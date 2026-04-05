import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/enums.dart';
import '../../../providers/ai_coach_providers.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/typing_indicator.dart';

class AICoachScreen extends ConsumerStatefulWidget {
  const AICoachScreen({super.key});

  @override
  ConsumerState<AICoachScreen> createState() => _AICoachScreenState();
}

class _AICoachScreenState extends ConsumerState<AICoachScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(aiChatControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Show error as SnackBar
    ref.listen<String?>(
      aiChatControllerProvider.select((s) => s.errorMessage),
      (prev, next) {
        if (next != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next),
              action: SnackBarAction(
                label: 'Dismiss',
                onPressed: () => ref
                    .read(aiChatControllerProvider.notifier)
                    .clearError(),
              ),
            ),
          );
        }
      },
    );

    // Scroll to bottom when new messages arrive or streaming updates
    ref.listen(aiChatControllerProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length ||
          prev?.streamingContent != next.streamingContent ||
          prev?.isWaitingForStream != next.isWaitingForStream) {
        _scrollToBottom();
      }
    });

    final isBusy = chatState.isStreaming || chatState.isWaitingForStream;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Coach'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') {
                _confirmClear();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'clear',
                child: Text('Clear History'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: chatState.messages.isEmpty && !isBusy
                ? _EmptyState(textTheme: textTheme, colorScheme: colorScheme)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: chatState.messages.length +
                        (chatState.isWaitingForStream ? 1 : 0) +
                        (chatState.isStreaming ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Persisted messages
                      if (index < chatState.messages.length) {
                        final msg = chatState.messages[index];
                        return ChatBubble(
                          role: msg.role,
                          content: msg.content,
                          timestamp: msg.timestamp,
                        );
                      }

                      // Typing indicator (waiting for first token)
                      if (chatState.isWaitingForStream) {
                        return const TypingIndicator();
                      }

                      // Streaming bubble (partial response)
                      if (chatState.isStreaming) {
                        return ChatBubble(
                          role: MessageRole.assistant,
                          content: chatState.streamingContent,
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),
          ),
          // Input bar
          ChatInputBar(
            enabled: !isBusy,
            onSend: (text) =>
                ref.read(aiChatControllerProvider.notifier).sendMessage(text),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear chat history?'),
        content: const Text('This will delete all messages permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(aiChatControllerProvider.notifier).clearHistory();
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.textTheme, required this.colorScheme});

  final TextTheme textTheme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.smart_toy_outlined,
              size: 56,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Your AI Coach',
              style: textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask me about your training, nutrition, or any fitness question. '
              "I have access to your workout and nutrition data so I can give "
              'personalised advice.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
