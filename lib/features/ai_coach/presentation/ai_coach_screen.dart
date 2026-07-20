import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/logger.dart';
import '../../../models/enums.dart';
import '../../../providers/ai_coach_providers.dart';
import '../../../providers/entitlement_providers.dart';
import '../../paywall/presentation/airborne_paywall.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/coach_proposal_card.dart';
import 'widgets/typing_indicator.dart';

class AICoachScreen extends ConsumerStatefulWidget {
  const AICoachScreen({super.key});

  @override
  ConsumerState<AICoachScreen> createState() => _AICoachScreenState();
}

class _AICoachScreenState extends ConsumerState<AICoachScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    AppLogger.log('AI Coach opened');
  }

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

  void _sendMessage(String text) {
    if (ref.read(anthropicServiceProvider) == null) {
      showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('AI Coach not configured'),
          content: const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              "AI Coach isn't set up yet. A backend proxy (AI_PROXY_URL) "
              'needs to be configured before you can chat.',
            ),
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    ref.read(aiChatControllerProvider.notifier).sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(aiChatControllerProvider);

    // Show errors as a Cupertino alert so the typing indicator is never
    // left spinning silently. The daily-cap 429 gets the Airborne upsell
    // instead — but only for free-tier users; a subscriber who exhausts the
    // higher cap sees the plain limit notice (nothing left to sell them).
    ref.listen<String?>(
      aiChatControllerProvider.select((s) => s.errorMessage),
      (prev, next) {
        if (next == null) return;
        final isDailyLimit =
            ref.read(aiChatControllerProvider).errorIsDailyLimit;
        final airborne = ref.read(airborneActiveProvider);
        if (isDailyLimit && !airborne) {
          _showDailyLimitUpsell(next);
        } else {
          showCupertinoDialog<void>(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: Text(
                  isDailyLimit ? 'Daily limit reached' : 'AI Coach unavailable'),
              content: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(next),
              ),
              actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        ref.read(aiChatControllerProvider.notifier).clearError();
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

    final palette = AppColors.of(context);
    final configured = ref.watch(anthropicServiceProvider) != null;
    return Scaffold(
      backgroundColor: palette.scaffold,
      appBar: CupertinoNavigationBar(
        middle: const Text('AI Coach'),
        backgroundColor: palette.background.withValues(alpha: 0.8),
        border: null,
        trailing: CupertinoButton(
          padding: const EdgeInsets.all(8),
          onPressed: _showActions,
          child: const Icon(CupertinoIcons.ellipsis,
              size: 22, semanticLabel: 'Chat options'),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: !configured
                ? const _UnavailableState()
                : chatState.messages.isEmpty && !isBusy
                    ? _EmptyState(onPromptTapped: _sendMessage)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: chatState.messages.length +
                        (chatState.isWaitingForStream ? 1 : 0) +
                        (chatState.isStreaming ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < chatState.messages.length) {
                        final msg = chatState.messages[index];
                        if (msg.proposalKind == null) {
                          return ChatBubble(
                            role: msg.role,
                            content: msg.content,
                            timestamp: msg.timestamp,
                          );
                        }
                        // A message carrying a tool proposal: show any lead-in
                        // text, then the inline confirmation card.
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (msg.content.trim().isNotEmpty)
                              ChatBubble(
                                role: msg.role,
                                content: msg.content,
                                timestamp: msg.timestamp,
                              ),
                            CoachProposalCard(message: msg),
                          ],
                        );
                      }

                      if (chatState.isWaitingForStream) {
                        return const TypingIndicator();
                      }

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
          ChatInputBar(
            enabled: configured && !isBusy,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }

  /// Daily-cap dialog for free-tier users: the server's limit notice plus the
  /// Airborne pitch. "Not now" is the quiet default; GO AIRBORNE opens the
  /// RevenueCat paywall.
  Future<void> _showDailyLimitUpsell(String message) async {
    final goAirborne = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Daily limit reached'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '$message\n\n15 a day is standard issue. '
            'Airborne raises it to 100.',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not now'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('GO AIRBORNE'),
          ),
        ],
      ),
    );
    if (goAirborne == true && mounted) {
      await presentAirbornePaywall(context, ref);
    }
  }

  Future<void> _showActions() async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              _confirmClear();
            },
            child: const Text('Clear History'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _confirmClear() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Clear chat history?'),
        content: const Text('This will delete all messages permanently.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
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

/// Shown when no AI proxy is configured (`AI_PROXY_URL` empty) — an explicit
/// "unavailable — configuration" state, never a silent blank chat.
class _UnavailableState extends StatelessWidget {
  const _UnavailableState();

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.wrench, size: 48, color: palette.textSecondary),
            const SizedBox(height: 16),
            Text('AI Coach unavailable',
                textAlign: TextAlign.center, style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              "The coach is offline due to a configuration issue — this build "
              "can't reach the backend. Nothing you did; it'll be back.",
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium
                  ?.copyWith(color: palette.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onPromptTapped});

  final void Function(String prompt) onPromptTapped;

  static const _suggestedPrompts = [
    'How can I improve my diet?',
    'Suggest a workout plan',
    'Help me hit my protein target',
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.of(context).accent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.smart_toy_rounded,
                size: 40,
                color: AppColors.of(context).text,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Ask me anything about your fitness journey',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                color: AppColors.of(context).text,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _suggestedPrompts
                  .map((prompt) => _SuggestedPromptChip(
                        label: prompt,
                        onTap: () => onPromptTapped(prompt),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestedPromptChip extends StatelessWidget {
  const _SuggestedPromptChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: label,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          decoration: BoxDecoration(
            border: Border.all(
                color: colorScheme.onSurface.withValues(alpha: 0.5), width: 1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
