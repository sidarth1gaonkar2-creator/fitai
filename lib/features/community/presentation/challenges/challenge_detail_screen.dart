import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show CircleAvatar;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/logger.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/community_providers.dart';
import '../../../../providers/firestore_provider.dart';
import '../../data/challenge_repository.dart';
import '../../domain/challenge.dart';

class ChallengeDetailScreen extends ConsumerWidget {
  const ChallengeDetailScreen({super.key, required this.challengeId});

  final String challengeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    final asyncChallenge = ref.watch(challengeByIdProvider(challengeId));

    return CupertinoPageScaffold(
      backgroundColor: palette.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: palette.surface,
        border: Border(
          bottom: BorderSide(color: palette.border, width: 0.5),
        ),
        middle: asyncChallenge.whenOrNull(
          data: (c) => Text(
            c?.title ?? 'Challenge',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: palette.text,
            ),
          ),
        ),
      ),
      child: asyncChallenge.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (_, __) => Center(
          child: Text(
            'Failed to load challenge.',
            style: TextStyle(
              fontFamily: 'LeagueSpartan',
              fontSize: 14,
              color: palette.textSecondary,
            ),
          ),
        ),
        data: (challenge) {
          if (challenge == null) {
            return Center(
              child: Text(
                'Challenge not found.',
                style: TextStyle(
                  fontFamily: 'LeagueSpartan',
                  fontSize: 14,
                  color: palette.textSecondary,
                ),
              ),
            );
          }
          return _Body(challenge: challenge);
        },
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    final userId = ref.watch(currentUserIdProvider);
    final asyncIsParticipant =
        ref.watch(isParticipantProvider(challenge.challengeId));
    final asyncParticipant =
        ref.watch(myChallengeParticipationProvider(challenge.challengeId));
    final asyncParticipants =
        ref.watch(challengeParticipantsProvider(challenge.challengeId));

    final daysRemaining = challenge.endDate != null
        ? challenge.endDate!.difference(DateTime.now()).inDays.clamp(0, 9999)
        : challenge.durationDays;
    final elapsed = challenge.durationDays - daysRemaining;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Header(challenge: challenge, palette: palette, elapsed: elapsed),
          const SizedBox(height: 16),
          if (asyncParticipant.value != null)
            _MyProgressCard(
              challenge: challenge,
              palette: palette,
              completedDays: asyncParticipant.value!.completedDays,
            ),
          if (asyncParticipant.value != null) const SizedBox(height: 16),
          asyncIsParticipant.when(
            loading: () => const CupertinoActivityIndicator(),
            error: (e, st) {
              AppLogger.error(
                'Challenge detail: isParticipant check failed',
                error: e,
                stack: st,
              );
              return const SizedBox.shrink();
            },
            data: (isJoined) => _ActionButtons(
              challenge: challenge,
              isJoined: isJoined,
              participant: asyncParticipant.value,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Participants (${challenge.participantCount})',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: palette.text,
            ),
          ),
          const SizedBox(height: 12),
          asyncParticipants.when(
            loading: () => const Center(child: CupertinoActivityIndicator()),
            error: (_, __) => Text(
              'Could not load participants.',
              style: TextStyle(
                fontFamily: 'LeagueSpartan',
                fontSize: 13,
                color: palette.textSecondary,
              ),
            ),
            data: (participants) {
              if (participants.isEmpty) {
                return Text(
                  'No participants yet. Be the first!',
                  style: TextStyle(
                    fontFamily: 'LeagueSpartan',
                    fontSize: 14,
                    color: palette.textSecondary,
                  ),
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < participants.length; i++)
                    _ParticipantRow(
                      rank: i + 1,
                      participant: participants[i],
                      palette: palette,
                      isMe: participants[i].userId == userId,
                    ),
                ],
              );
            },
          ),
          if (challenge.isPublic) ...[
            const SizedBox(height: 24),
            asyncParticipants.when(
              loading: () => const SizedBox.shrink(),
              error: (e, st) {
                AppLogger.error(
                  'Challenge detail: proof-feed participants load failed',
                  error: e,
                  stack: st,
                );
                return const SizedBox.shrink();
              },
              data: (participants) {
                final photos = <String>[
                  for (final p in participants) ...p.proofPhotos,
                ];
                if (photos.isEmpty) return const SizedBox.shrink();
                return _ProofFeed(photos: photos, palette: palette);
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.challenge,
    required this.palette,
    required this.elapsed,
  });

  final Challenge challenge;
  final Palette palette;
  final int elapsed;

  @override
  Widget build(BuildContext context) {
    final progress = challenge.durationDays > 0
        ? (elapsed / challenge.durationDays).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: palette.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  challenge.icon ?? '🏆',
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.typeLabel,
                      style: TextStyle(
                        fontFamily: 'LeagueSpartan',
                        fontSize: 12,
                        color: palette.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${challenge.durationDays} days · by ${challenge.creatorUsername.isEmpty ? 'FitAI' : challenge.creatorUsername}',
                      style: TextStyle(
                        fontFamily: 'LeagueSpartan',
                        fontSize: 13,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (challenge.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              challenge.description,
              style: TextStyle(
                fontFamily: 'LeagueSpartan',
                fontSize: 14,
                color: palette.text,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 14),
          _ProgressBar(
            progress: progress,
            palette: palette,
            caption:
                'Day ${elapsed.clamp(0, challenge.durationDays)} of ${challenge.durationDays}',
          ),
        ],
      ),
    );
  }
}

class _MyProgressCard extends StatelessWidget {
  const _MyProgressCard({
    required this.challenge,
    required this.palette,
    required this.completedDays,
  });

  final Challenge challenge;
  final Palette palette;
  final int completedDays;

  @override
  Widget build(BuildContext context) {
    final fraction = challenge.durationDays > 0
        ? (completedDays / challenge.durationDays).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Progress',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: palette.text,
            ),
          ),
          const SizedBox(height: 10),
          _ProgressBar(
            progress: fraction,
            palette: palette,
            caption:
                '$completedDays / ${challenge.durationDays} days ' '(${(fraction * 100).toStringAsFixed(0)}%)',
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.progress,
    required this.palette,
    required this.caption,
  });

  final double progress;
  final Palette palette;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 8,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Container(
                      width: constraints.maxWidth,
                      color: palette.surfaceElevated,
                    ),
                    Container(
                      width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                      decoration: BoxDecoration(
                        color: palette.accent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          caption,
          style: TextStyle(
            fontFamily: 'LeagueSpartan',
            fontSize: 13,
            color: palette.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ActionButtons extends ConsumerStatefulWidget {
  const _ActionButtons({
    required this.challenge,
    required this.isJoined,
    required this.participant,
  });

  final Challenge challenge;
  final bool isJoined;
  final ChallengeParticipant? participant;

  @override
  ConsumerState<_ActionButtons> createState() => _ActionButtonsState();
}

class _ActionButtonsState extends ConsumerState<_ActionButtons> {
  bool _loading = false;

  Future<void> _join() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    setState(() => _loading = true);
    try {
      final user = await ref.read(firestoreUserProvider.future);
      final p = ChallengeParticipant(
        challengeId: widget.challenge.challengeId,
        userId: userId,
        username: user?.username ?? '',
        profilePictureUrl: user?.profilePictureUrl,
        joinedAt: DateTime.now().toUtc(),
      );
      await ref.read(challengeRepositoryProvider).joinChallenge(p);
      _invalidate();
    } catch (e) {
      _showError('Could not join: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _leave() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Leave challenge?'),
        content:
            const Text('Your progress in this challenge will be lost.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _loading = true);
    try {
      await ref
          .read(challengeRepositoryProvider)
          .leaveChallenge(widget.challenge.challengeId, userId);
      _invalidate();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _checkIn() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    setState(() => _loading = true);

    try {
      File? proof;
      if (widget.challenge.requiresPhotoProof) {
        final picked = await ref
            .read(storageServiceProvider)
            .pickImage(source: ImageSource.camera);
        if (picked == null) {
          setState(() => _loading = false);
          return;
        }
        proof = picked;
      }

      HapticFeedback.mediumImpact();
      await ref.read(challengeRepositoryProvider).checkIn(
            challenge: widget.challenge,
            userId: userId,
            proofFile: proof,
          );
      _invalidate();
    } catch (e) {
      _showError('Could not check in: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _invalidate() {
    ref.invalidate(isParticipantProvider(widget.challenge.challengeId));
    ref.invalidate(
        myChallengeParticipationProvider(widget.challenge.challengeId));
    ref.invalidate(
        challengeParticipantsProvider(widget.challenge.challengeId));
    ref.invalidate(challengeByIdProvider(widget.challenge.challengeId));
    ref.invalidate(myChallengesProvider);
  }

  void _showError(String msg) {
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Oops'),
        content: Text(msg),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

    if (_loading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (!widget.isJoined) {
      return SizedBox(
        width: double.infinity,
        child: CupertinoButton(
          padding: const EdgeInsets.symmetric(vertical: 14),
          color: palette.accent,
          borderRadius: BorderRadius.circular(12),
          onPressed: _join,
          child: const Text(
            'Join Challenge',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: CupertinoColors.white,
            ),
          ),
        ),
      );
    }

    final checkedInToday = ref
        .read(challengeRepositoryProvider)
        .didCheckInToday(widget.participant);

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 14),
            color: checkedInToday
                ? palette.surfaceElevated
                : palette.accent,
            borderRadius: BorderRadius.circular(12),
            onPressed: checkedInToday ? null : _checkIn,
            child: Text(
              checkedInToday
                  ? 'Checked In Today ✓'
                  : widget.challenge.requiresPhotoProof
                      ? 'Log Today (Photo)'
                      : 'Log Today',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color:
                    checkedInToday ? palette.text : CupertinoColors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _leave,
          child: Text(
            'Leave Challenge',
            style: TextStyle(
              fontFamily: 'LeagueSpartan',
              fontSize: 14,
              color: palette.destructive,
            ),
          ),
        ),
      ],
    );
  }
}

class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow({
    required this.rank,
    required this.participant,
    required this.palette,
    required this.isMe,
  });

  final int rank;
  final ChallengeParticipant participant;
  final Palette palette;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/profile/${participant.userId}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isMe
              ? palette.accent.withValues(alpha: 0.1)
              : palette.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.border, width: 0.5),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                '$rank',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: palette.text,
                ),
              ),
            ),
            const SizedBox(width: 10),
            CircleAvatar(
              radius: 18,
              backgroundColor: palette.surfaceElevated,
              backgroundImage: participant.profilePictureUrl != null
                  ? CachedNetworkImageProvider(
                      participant.profilePictureUrl!)
                  : null,
              child: participant.profilePictureUrl == null
                  ? Icon(
                      CupertinoIcons.person_fill,
                      size: 16,
                      color: palette.textSecondary,
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    participant.username,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: palette.text,
                    ),
                  ),
                  Text(
                    'Streak ${participant.currentStreak}🔥',
                    style: TextStyle(
                      fontFamily: 'LeagueSpartan',
                      fontSize: 12,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${participant.completedDays} d',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: palette.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProofFeed extends StatelessWidget {
  const _ProofFeed({required this.photos, required this.palette});

  final List<String> photos;
  final Palette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Proof Feed',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: palette.text,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
          ),
          itemCount: photos.length,
          itemBuilder: (context, index) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: photos[index],
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: palette.surfaceElevated,
                  child:
                      const Center(child: CupertinoActivityIndicator()),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: palette.surfaceElevated,
                  child: Icon(CupertinoIcons.photo,
                      color: palette.textSecondary),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

