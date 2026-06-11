import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../../models/ai_message.dart';
import '../../../models/enums.dart';
import '../../../providers/isar_provider.dart';
import '../../../providers/unit_system_provider.dart';
import '../../../services/anthropic_service.dart';
import '../domain/coach_context_builder.dart';

const _systemPrompt =
    'You are DrillFit Coach, a knowledgeable and supportive fitness and '
    'nutrition expert. You give personalized, actionable advice based on '
    "the user's workout history, nutrition data, and goals. Keep responses "
    'concise (under 200 words unless asked for more), practical, and '
    'encouraging.';

/// Max messages persisted locally per user; older ones are trimmed on save.
const _maxStoredMessages = 50;

/// Max messages sent to the proxy per request — independent of how many are
/// stored or displayed.
const _maxContextMessages = 12;

/// One-time flag marking that legacy pre-uid-scoping chat rows were purged.
const _unscopedPurgedKey = 'aiCoachUnscopedPurged';

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
  AIChatController(this._ref, this._anthropic, this._uid)
      : super(const ChatState()) {
    _loadHistory();
  }

  final Ref _ref;
  final AnthropicService? _anthropic;

  /// Firebase uid this controller is scoped to. Null when signed out — in that
  /// case nothing is loaded, persisted, or sent.
  final String? _uid;

  Isar get _isar => _ref.read(isarProvider);

  Future<void> _loadHistory() async {
    await _purgeLegacyUnscopedMessages();

    final uid = _uid;
    if (uid == null) {
      // Signed out — show nothing and persist nothing.
      if (mounted) state = state.copyWith(messages: const []);
      return;
    }

    try {
      final messages = await _isar.aIMessages
          .filter()
          .uidEqualTo(uid)
          .sortByTimestamp()
          .findAll();
      if (!mounted) return;
      state = state.copyWith(messages: messages);
    } catch (_) {
      // A load failure shouldn't crash the screen — start from an empty chat.
      if (!mounted) return;
      state = state.copyWith(messages: const []);
    }
  }

  /// Deletes pre-scoping global chat rows (uid == '') exactly once after this
  /// upgrade so old data is discarded, never migrated to any account.
  Future<void> _purgeLegacyUnscopedMessages() async {
    try {
      final prefs = _ref.read(sharedPreferencesProvider);
      if (prefs.getBool(_unscopedPurgedKey) ?? false) return;
      await _isar.writeTxn(() async {
        await _isar.aIMessages.filter().uidIsEmpty().deleteAll();
      });
      await prefs.setBool(_unscopedPurgedKey, true);
    } catch (_) {
      // Best-effort; will retry on a later launch if it failed.
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    if (state.isStreaming || state.isWaitingForStream) return;

    if (_anthropic == null) {
      state = state.copyWith(
        errorMessage: () =>
            "AI Coach isn't set up. A backend proxy (AI_PROXY_URL) must be "
            'configured.',
      );
      return;
    }

    final uid = _uid;
    if (uid == null) {
      state = state.copyWith(
        errorMessage: () => 'Sign in to use the AI Coach.',
      );
      return;
    }

    // Save user message (scoped to this uid, trimmed to the 50-message cap).
    final userMsg = AIMessage()
      ..uid = uid
      ..role = MessageRole.user
      ..content = text.trim()
      ..timestamp = DateTime.now();

    await _persist(userMsg);
    if (!mounted) return;

    state = state.copyWith(
      messages: _capInMemory([...state.messages, userMsg]),
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
      final recentHistory = history.length > _maxContextMessages
          ? history.sublist(history.length - _maxContextMessages)
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
        if (streamErr is AnthropicRateLimitException) {
          // Daily cap hit — terminal. Don't burn a second call on the
          // non-streaming fallback; surface the limit notice.
          rethrow;
        }
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

      // Save assistant message (same uid scope + 50-message cap).
      final assistantMsg = AIMessage()
        ..uid = uid
        ..role = MessageRole.assistant
        ..content = buffer.toString()
        ..timestamp = DateTime.now();

      await _persist(assistantMsg);
      if (!mounted) return;

      state = state.copyWith(
        messages: _capInMemory([...state.messages, assistantMsg]),
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
      // The daily-limit message is already user-friendly — show it verbatim.
      state = state.copyWith(
        isStreaming: false,
        isWaitingForStream: false,
        streamingContent: '',
        errorMessage: () => e is AnthropicRateLimitException
            ? e.message
            : _friendlyError(e.message),
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
    final uid = _uid;
    try {
      if (uid != null) {
        await _isar.writeTxn(() async {
          await _isar.aIMessages.filter().uidEqualTo(uid).deleteAll();
        });
      }
    } catch (_) {
      // Ignore — clearing is best-effort.
    }
    if (!mounted) return;
    state = const ChatState();
  }

  /// Persists [msg] and enforces the per-user 50-message cap atomically: the
  /// insert and the trim of the oldest overflow run in one write txn, so there
  /// is never a window where more than 50 rows exist for this uid.
  Future<void> _persist(AIMessage msg) async {
    try {
      await _isar.writeTxn(() async {
        await _isar.aIMessages.put(msg);
        final stored = await _isar.aIMessages
            .filter()
            .uidEqualTo(msg.uid)
            .sortByTimestamp()
            .findAll();
        if (stored.length > _maxStoredMessages) {
          final overflow = stored
              .take(stored.length - _maxStoredMessages)
              .map((m) => m.id)
              .toList();
          await _isar.aIMessages.deleteAll(overflow);
        }
      });
    } catch (_) {
      // Best-effort persistence; the message still appears in the session.
    }
  }

  /// Mirrors the stored 50-message cap in memory so the display matches disk.
  List<AIMessage> _capInMemory(List<AIMessage> messages) =>
      messages.length > _maxStoredMessages
          ? messages.sublist(messages.length - _maxStoredMessages)
          : messages;

  String _friendlyError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('rate_limit') || lower.contains('rate limit')) {
      return 'Too many requests. Please wait a moment and try again.';
    }
    if (lower.contains('authentication') ||
        lower.contains('invalid') ||
        lower.contains('auth token')) {
      return "Couldn't verify your session. Please sign out and back in.";
    }
    if (lower.contains('overloaded')) {
      return 'The AI service is busy. Please try again in a minute.';
    }
    return "Couldn't reach the AI coach. Check your connection and try again.";
  }
}
