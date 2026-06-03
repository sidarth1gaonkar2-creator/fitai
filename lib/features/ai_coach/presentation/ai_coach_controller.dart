import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../../models/ai_message.dart';
import '../../../models/enums.dart';
import '../../../providers/isar_provider.dart';
import '../../../services/anthropic_service.dart';
import '../domain/coach_context_builder.dart';

const _systemPrompt =
    'You are DrillFit Coach, a knowledgeable and supportive fitness and '
    'nutrition expert. You give personalized, actionable advice based on '
    "the user's workout history, nutrition data, and goals. Keep responses "
    'concise (under 200 words unless asked for more), practical, and '
    'encouraging.';

class ChatState {
  const ChatState({
    this.messages = const [],
    this.isStreaming = false,
    this.isWaitingForStream = false,
    this.streamingContent = '',
    this.errorMessage,
  });

  final List<AIMessage> messages;
  final bool isStreaming;
  final bool isWaitingForStream;
  final String streamingContent;
  final String? errorMessage;

  ChatState copyWith({
    List<AIMessage>? messages,
    bool? isStreaming,
    bool? isWaitingForStream,
    String? streamingContent,
    String? Function()? errorMessage,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isStreaming: isStreaming ?? this.isStreaming,
      isWaitingForStream: isWaitingForStream ?? this.isWaitingForStream,
      streamingContent: streamingContent ?? this.streamingContent,
      errorMessage:
          errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }
}

class AIChatController extends StateNotifier<ChatState> {
  AIChatController(this._ref, this._anthropic)
      : super(const ChatState()) {
    _loadHistory();
  }

  final Ref _ref;
  final AnthropicService? _anthropic;

  Isar get _isar => _ref.read(isarProvider);

  Future<void> _loadHistory() async {
    final messages =
        await _isar.aIMessages.where().sortByTimestamp().findAll();
    state = state.copyWith(messages: messages);
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    if (state.isStreaming || state.isWaitingForStream) return;

    if (_anthropic == null) {
      state = state.copyWith(
        errorMessage: () =>
            'API key not configured. Add your key to assets/.env',
      );
      return;
    }

    // Save user message
    final userMsg = AIMessage()
      ..role = MessageRole.user
      ..content = text.trim()
      ..timestamp = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.aIMessages.put(userMsg);
    });

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isWaitingForStream: true,
      streamingContent: '',
      errorMessage: () => null,
    );

    try {
      // Build user context
      final context = await CoachContextBuilder.build(_ref);
      final systemWithContext = '$_systemPrompt\n\n'
          'Current user context:\n$context';

      // Prepare message history (last 20 messages)
      final history = state.messages
          .take(state.messages.length) // all messages
          .toList();
      final recentHistory = history.length > 20
          ? history.sublist(history.length - 20)
          : history;

      final apiMessages = recentHistory
          .map((m) => (
                role: m.role == MessageRole.user ? 'user' : 'assistant',
                content: m.content,
              ))
          .toList();

      // Stream response — fall back to non-streaming if the stream fails
      // before any chunk arrives.
      final buffer = StringBuffer();
      bool firstChunk = true;
      bool streamFailedBeforeFirstChunk = false;

      try {
        await for (final chunk in _anthropic.streamMessage(
          systemPrompt: systemWithContext,
          messages: apiMessages,
        )) {
          if (!mounted) return;

          if (firstChunk) {
            firstChunk = false;
            state = state.copyWith(
              isWaitingForStream: false,
              isStreaming: true,
            );
          }

          buffer.write(chunk);
          state = state.copyWith(streamingContent: buffer.toString());
        }
      } catch (streamErr) {
        if (firstChunk) {
          // Nothing streamed yet — try non-streaming fallback.
          streamFailedBeforeFirstChunk = true;
        } else {
          rethrow;
        }
      }

      if (streamFailedBeforeFirstChunk) {
        final fullText = await _anthropic.sendMessage(
          systemPrompt: systemWithContext,
          messages: apiMessages,
        );
        buffer.write(fullText);
      }

      if (!mounted) return;

      // Save assistant message
      final assistantMsg = AIMessage()
        ..role = MessageRole.assistant
        ..content = buffer.toString()
        ..timestamp = DateTime.now();

      await _isar.writeTxn(() async {
        await _isar.aIMessages.put(assistantMsg);
      });

      state = state.copyWith(
        messages: [...state.messages, assistantMsg],
        isStreaming: false,
        isWaitingForStream: false,
        streamingContent: '',
      );
    } on SocketException {
      if (!mounted) return;
      state = state.copyWith(
        isStreaming: false,
        isWaitingForStream: false,
        streamingContent: '',
        errorMessage: () =>
            'No internet connection. Connect to the network and try again.',
      );
    } on AnthropicException catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isStreaming: false,
        isWaitingForStream: false,
        streamingContent: '',
        errorMessage: () => _friendlyError(e.message),
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isStreaming: false,
        isWaitingForStream: false,
        streamingContent: '',
        errorMessage: () =>
            "Couldn't reach the AI coach. Check your connection and try again.",
      );
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: () => null);
  }

  Future<void> clearHistory() async {
    await _isar.writeTxn(() async {
      await _isar.aIMessages.clear();
    });
    state = const ChatState();
  }

  String _friendlyError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('rate_limit') || lower.contains('rate limit')) {
      return 'Too many requests. Please wait a moment and try again.';
    }
    if (lower.contains('authentication') || lower.contains('invalid')) {
      return 'Invalid API key. Check your key in assets/.env';
    }
    if (lower.contains('overloaded')) {
      return 'The AI service is busy. Please try again in a minute.';
    }
    return "Couldn't reach the AI coach. Check your connection and try again.";
  }
}
