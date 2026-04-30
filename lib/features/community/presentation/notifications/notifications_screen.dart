import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show CircleAvatar;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
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
        backgroundColor: palette.surface,
        border: Border(
          bottom: BorderSide(color: palette.border, width: 0.5),
        ),
        middle: Text(
          'Notifications',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: palette.text,
          ),
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
                  style: TextStyle(
                    fontFamily: 'LeagueSpartan',
                    fontSize: 14,
                    color: palette.accent,
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
          error: (_, __) => Center(
            child: Text(
              'Could not load notifications.',
              style: TextStyle(
                fontFamily: 'LeagueSpartan',
                color: palette.textSecondary,
              ),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return _buildEmpty(palette);
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              separatorBuilder: (_, __) => Container(
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
              'All caught up',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 17,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'You have no new notifications.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'LeagueSpartan',
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

  Color _iconColor() {
    switch (notif.type) {
      case 'like':
        return palette.destructive;
      case 'follow':
      case 'challenge_join':
        return palette.accent;
      case 'comment':
      default:
        return palette.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
                    style: TextStyle(
                      fontFamily: 'LeagueSpartan',
                      fontSize: 14,
                      color: palette.text,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatRelativeTime(notif.createdAt),
                    style: TextStyle(
                      fontFamily: 'LeagueSpartan',
                      fontSize: 12,
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
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: CupertinoColors.white,
        ),
      ),
    );
  }
}
