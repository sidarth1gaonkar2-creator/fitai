import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/cupertino_helpers.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/community_providers.dart';
import '../../data/block_repository.dart';
import '../../data/post_repository.dart';

/// Shared moderation flows (Guideline 1.2) so the feed, post-detail screen, and
/// profile all present an identical Report / Block experience.

const _reportReasons = <String>[
  'Spam',
  'Harassment or abuse',
  'Inappropriate content',
  'Other',
];

/// Asks for a reason, files a report, then hides the post locally for the
/// reporter (it is NOT deleted for everyone). Best-effort: a network failure
/// still hides the post, because the user explicitly asked not to see it.
Future<void> reportPostFlow(
  BuildContext context,
  WidgetRef ref, {
  required String postId,
  required String reportedUserId,
}) async {
  final reporterId = ref.read(currentUserIdProvider);
  if (reporterId == null) return;

  final reason = await showCupertinoModalPopup<String>(
    context: context,
    builder: (ctx) => CupertinoActionSheet(
      title: const Text('Report post'),
      message: const Text('Why are you reporting this post?'),
      actions: [
        for (final r in _reportReasons)
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(ctx).pop(r),
            child: Text(r),
          ),
      ],
      cancelButton: CupertinoActionSheetAction(
        isDefaultAction: true,
        onPressed: () => Navigator.of(ctx).pop(),
        child: const Text('Cancel'),
      ),
    ),
  );
  if (reason == null) return;

  try {
    await ref.read(postRepositoryProvider).reportPost(
          postId: postId,
          reportedUserId: reportedUserId,
          reporterId: reporterId,
          reason: reason,
        );
  } catch (e, st) {
    AppLogger.error('reportPost failed', error: e, stack: st);
  }
  // Hide locally regardless of the network result.
  await ref.read(hiddenPostsProvider.notifier).hide(postId);
  if (context.mounted) {
    showCupertinoToast(context, "Reported. You won't see this post again.");
  }
}

/// Confirms, blocks the user, and refreshes the blocked set so the feed drops
/// their posts immediately. Returns true if the block was applied (callers on a
/// profile/sheet can pop themselves).
Future<bool> blockUserFlow(
  BuildContext context,
  WidgetRef ref, {
  required String targetUserId,
  required String username,
}) async {
  final uid = ref.read(currentUserIdProvider);
  if (uid == null || uid == targetUserId) return false;

  final confirmed = await showCupertinoDialog<bool>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: Text('Block @$username?'),
      content: const Text(
        "You won't see their posts in your feed. You can unblock them later "
        'from their profile.',
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Block'),
        ),
      ],
    ),
  );
  if (confirmed != true) return false;

  try {
    await ref.read(blockRepositoryProvider).block(uid, targetUserId);
  } catch (e, st) {
    AppLogger.error('blockUser failed', error: e, stack: st);
  }
  ref.invalidate(blockedUserIdsProvider);
  if (context.mounted) {
    showCupertinoToast(context, 'Blocked @$username.');
  }
  return true;
}
