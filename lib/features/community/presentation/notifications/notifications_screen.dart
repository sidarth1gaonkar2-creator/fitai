import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show CircleAvatar;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/field_manual.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/community_providers.dart';
import '../../data/notification_repository.dart';
import '../../domain/notification.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    final async = ref.watch(notificationsStreamProvider);
    final userId = ref.watch(currentUserIdProvider);

    return CupertinoPageScaffold(
      backgroundColor: palette.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: palette.background.withValues(alpha: 0.82),
        border: Border(bottom: BorderSide(color: palette.border)),
        middle: Text(
          'NOTIFICATIONS',
          style: FieldManual.title(color: palette.text),
        ),
        trailing: userId == null
            ? null
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () async {
                  HapticFeedback.selectionClick();
                  await ref
                      .read(notificationRepositoryProvider)
                      .markAllRead(userId);
                },
                child: Text(
                  'Mark all read',
                  style: FieldManual.body(
                    fontSize: 14,
                    color: palette.accent,
                  ).copyWith(
                    fontVariations: const [FontVariation('wght', 600)],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
      ),
      child: SafeArea(
        child: async.when(
          loading: () => Padding(
            padding: const EdgeInsets.all(16),
            child: const ShimmerList(itemCount: 5),
          ),
          error: (_, _) => Center(
            child: Text(
              'Could not load notifications.',
              style: FieldManual.body(color: palette.textSecondary),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return _buildEmpty(palette);
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              separatorBuilder: (_, _) => Container(
                height: 0.5,
                color: palette.border,
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              itemBuilder: (context, index) {
                final notif = items[index];
                return _NotifTile(
                  notif: notif,
                  palette: palette,
                  onTap: () => _open(context, ref, notif, userId),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmpty(Palette palette) {
    // Drill-sergeant eyebrow + sentence-case guidance (DESIGN.md).
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.bell,
                size: 48, color: palette.textSecondary),
            const SizedBox(height: 12),
            Text(
              'ALL QUIET',
              textAlign: TextAlign.center,
              style: FieldManual.label(
                fontSize: 12,
                color: palette.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No new notifications. Carry on, soldier.',
              textAlign: TextAlign.center,
              style: FieldManual.body(
                fontSize: 14,
                color: palette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    AppNotification notif,
    String? userId,
  ) async {
    HapticFeedback.selectionClick();
    if (userId != null && !notif.isRead) {
      await ref
          .read(notificationRepositoryProvider)
          .markRead(userId, notif.id);
    }
    if (!context.mounted) return;

    switch (notif.type) {
      case 'follow':
        context.push('/profile/${notif.fromUserId}');
        break;
      case 'like':
      case 'comment':
        if (notif.postId != null) {
          context.push('/community/post/${notif.postId}');
        }
        break;
      case 'challenge_join':
        if (notif.challengeId != null) {
          context.push('/community/challenge/${notif.challengeId}');
        }
        break;
    }
  }
}

class _NotifTile extends StatelessWidget {
  const _NotifTile({
    required this.notif,
    required this.palette,
    required this.onTap,
  });

  final AppNotification notif;
  final Palette palette;
  final VoidCallback onTap;

  IconData _iconForType() {
    switch (notif.type) {
      case 'follow':
        return CupertinoIcons.person_add;
      case 'like':
        return CupertinoIcons.heart_fill;
      case 'comment':
        return CupertinoIcons.chat_bubble_fill;
      case 'challenge_join':
        return CupertinoIcons.flag_fill;
      default:
        return CupertinoIcons.bell;
    }
  }

  // Quiet list: type icons stay muted — no red badges without a true
  // consequence, and only the unread dot wears the accent (One Voice Rule).
  Color _iconColor() => palette.textSecondary;

  @override
  Widget build(BuildContext context) {
    // The unread state is spoken, not carried by colour alone.
    return Semantics(
      button: true,
      label:
          '${notif.message}, ${formatRelativeTime(notif.createdAt)}'
          '${notif.isRead ? '' : ', unread'}',
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: notif.isRead
                ? palette.background
                : palette.accent.withValues(alpha: 0.07),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    _avatar(),
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: palette.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_iconForType(),
                            size: 12, color: _iconColor()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notif.message,
                        style: FieldManual.body(
                          fontSize: 14,
                          color: palette.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        // Timestamps set in quiet mono.
                        formatRelativeTime(notif.createdAt),
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontVariations: const [FontVariation('wght', 500)],
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                          letterSpacing: 0.2,
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!notif.isRead)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 6),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: palette.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatar() {
    final url = notif.fromUserAvatar;
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: palette.surfaceElevated,
        backgroundImage: CachedNetworkImageProvider(url),
      );
    }
    final letter = notif.fromUsername.isNotEmpty
        ? notif.fromUsername[0].toUpperCase()
        : '?';
    return CircleAvatar(
      radius: 20,
      backgroundColor: palette.accent,
      child: Text(
        letter,
        style: TextStyle(
          fontFamily: 'Inter',
          fontVariations: const [FontVariation('wght', 700)],
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: palette.onAccent,
        ),
      ),
    );
  }
}
