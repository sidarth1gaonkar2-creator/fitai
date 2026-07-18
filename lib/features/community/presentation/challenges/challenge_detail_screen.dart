import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show CircleAvatar;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/field_manual.dart';
import '../../../../core/utils/logger.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/community_providers.dart';
import '../../../../providers/firestore_provider.dart';
import '../../../ranks/domain/military_ranks.dart';
import '../../../ranks/presentation/widgets/rank_badge.dart';
import '../../data/challenge_repository.dart';
import '../../domain/challenge.dart';
import '../../domain/challenge_goal.dart';
import 'challenge_goal_progress_view.dart';

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
        backgroundColor: palette.background.withValues(alpha: 0.82),
        border: Border(bottom: BorderSide(color: palette.border)),
        middle: asyncChallenge.whenOrNull(
          data: (c) => Text(
            // Challenge titles are user content — Inter, never uppercased
            // (the Bark Budget Rule).
            c?.title ?? 'Challenge',
            style: TextStyle(
              fontFamily: 'Inter',
              fontVariations: const [FontVariation('wght', 600)],
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: palette.text,
            ),
          ),
        ),
      ),
      child: asyncChallenge.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (_, _) => Center(
          child: Text(
            'Failed to load challenge.',
            style: FieldManual.body(
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
                style: FieldManual.body(
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
              return Row(
                children: [
                  Icon(CupertinoIcons.exclamationmark_circle,
                      size: 16, color: palette.destructive),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Couldn't check your join status.",
                      style: FieldManual.body(
                        fontSize: 13,
                        color: palette.textSecondary,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(44, 44),
                    onPressed: () => ref.invalidate(
                        isParticipantProvider(challenge.challengeId)),
                    child:
                        const Text('Retry', style: TextStyle(fontSize: 13)),
                  ),
                ],
              );
            },
            data: (isJoined) => _ActionButtons(
              challenge: challenge,
              isJoined: isJoined,
              participant: asyncParticipant.value,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'PARTICIPANTS',
                style: FieldManual.title(color: palette.text),
              ),
              const SizedBox(width: 8),
              Text(
                // Roster size is a stat — mono readout.
                '${challenge.participantCount}',
                style: FieldManual.label(
                  fontSize: 12,
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          asyncParticipants.when(
            loading: () => const Center(child: CupertinoActivityIndicator()),
            error: (_, _) => Text(
              'Could not load participants.',
              style: FieldManual.body(
                fontSize: 13,
                color: palette.textSecondary,
              ),
            ),
            data: (participants) {
              if (participants.isEmpty) {
                return Text(
                  'No participants yet. Be the first!',
                  style: FieldManual.body(
                    fontSize: 14,
                    color: palette.textSecondary,
                  ),
                );
              }
              // Rank challenges rank the roster by strength, not check-in days.
              final list = challenge.isRankGoal
                  ? ([...participants]..sort((a, b) =>
                      (b.rankIndex ?? -1).compareTo(a.rankIndex ?? -1)))
                  : participants;
              return Column(
                children: [
                  for (var i = 0; i < list.length; i++)
                    _ParticipantRow(
                      position: i + 1,
                      participant: list[i],
                      palette: palette,
                      isMe: list[i].userId == userId,
                      showRank: challenge.isRankGoal,
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.border),
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
                  borderRadius: BorderRadius.circular(4),
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
                      // Type designation — mono stamp in the live accent.
                      challenge.typeLabel.toUpperCase(),
                      style: FieldManual.label(
                        fontSize: 10,
                        color: palette.accent,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          // Duration is a trained-against number — mono.
                          '${challenge.durationDays} DAYS',
                          style: FieldManual.label(
                            fontSize: 11,
                            color: palette.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            // Creator names are user content — Inter, never
                            // uppercased.
                            '· by ${challenge.creatorUsername.isEmpty ? 'DrillFit' : challenge.creatorUsername}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: FieldManual.body(
                              fontSize: 13,
                              color: palette.textSecondary,
                            ),
                          ),
                        ),
                      ],
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
              style: FieldManual.body(fontSize: 14, color: palette.text),
            ),
          ],
          const SizedBox(height: 14),
          if (challenge.isRankGoal)
            Row(
              children: [
                ChallengeTargetBadge(challenge: challenge, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    challengeGoalSummary(challenge),
                    style: FieldManual.body(
                      fontSize: 13,
                      color: palette.textSecondary,
                    ),
                  ),
                ),
              ],
            )
          else
            _ProgressBar(
              progress: progress,
              palette: palette,
              caption:
                  'DAY ${elapsed.clamp(0, challenge.durationDays)} OF ${challenge.durationDays}',
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOUR PROGRESS',
            style: FieldManual.title(color: palette.text)
                .copyWith(fontSize: 14),
          ),
          const SizedBox(height: 10),
          if (challenge.isRankGoal)
            ChallengeGoalProgressView(challenge: challenge)
          else
            _ProgressBar(
              progress: fraction,
              palette: palette,
              caption:
                  '$completedDays / ${challenge.durationDays} DAYS ' '(${(fraction * 100).toStringAsFixed(0)}%)',
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
        // Instrument: accent fill on a hairline track, spoken as a value.
        Semantics(
          label: 'Challenge progress',
          value: '${(progress.clamp(0.0, 1.0) * 100).round()}%',
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: palette.border),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ClipRRect(
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
                          width:
                              constraints.maxWidth * progress.clamp(0.0, 1.0),
                          color: palette.accent,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          // Day counts are readouts — mono.
          caption,
          style: FieldManual.label(
            fontSize: 11,
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
    } catch (e, st) {
      AppLogger.error('Challenge detail: join failed', error: e, stack: st);
      _showError("Couldn't join the challenge. Try again in a moment.");
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
    } catch (e, st) {
      AppLogger.error('Challenge detail: check-in failed',
          error: e, stack: st);
      _showError("Couldn't check in. Try again in a moment.");
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
        title: const Text('Could not complete action'),
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
      // Spoken label stays sentence case; the uppercase is visual only.
      return SizedBox(
        width: double.infinity,
        child: Semantics(
          label: 'Join challenge',
          button: true,
          child: ExcludeSemantics(
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 14),
              color: palette.accent,
              borderRadius: BorderRadius.circular(4),
              onPressed: _join,
              child: Text(
                'JOIN CHALLENGE',
                style: _ctaStyle(palette.onAccent),
              ),
            ),
          ),
        ),
      );
    }

    final checkedInToday = ref
        .read(challengeRepositoryProvider)
        .didCheckInToday(widget.participant);
    final checkInLabel = checkedInToday
        ? 'Checked in today'
        : widget.challenge.requiresPhotoProof
            ? 'Log today with photo'
            : 'Log today';

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: Semantics(
            label: checkInLabel,
            button: true,
            child: ExcludeSemantics(
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 14),
                color: checkedInToday
                    ? palette.surfaceElevated
                    : palette.accent,
                // Keep the Field Manual surface when disabled — never the
                // iOS quaternarySystemFill fallback.
                disabledColor: palette.surfaceElevated,
                borderRadius: BorderRadius.circular(4),
                onPressed: checkedInToday ? null : _checkIn,
                child: Text(
                  checkedInToday
                      ? 'CHECKED IN TODAY ✓'
                      : widget.challenge.requiresPhotoProof
                          ? 'LOG TODAY (PHOTO)'
                          : 'LOG TODAY',
                  style: _ctaStyle(
                    checkedInToday ? palette.text : palette.onAccent,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _leave,
          child: Text(
            // Alert red — leaving discards progress (a consequence).
            'Leave Challenge',
            style: FieldManual.body(fontSize: 14, color: palette.destructive)
                .copyWith(
              fontVariations: const [FontVariation('wght', 600)],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// Field Manual primary-CTA label: condensed uppercase Oswald.
  TextStyle _ctaStyle(Color color) => TextStyle(
        fontFamily: 'Oswald',
        fontVariations: const [FontVariation('wght', 600)],
        fontWeight: FontWeight.w600,
        fontSize: 15,
        letterSpacing: 0.6,
        color: color,
      );
}

class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow({
    required this.position,
    required this.participant,
    required this.palette,
    required this.isMe,
    this.showRank = false,
  });

  final int position;
  final ChallengeParticipant participant;
  final Palette palette;
  final bool isMe;

  /// Rank challenges display each participant's rank instead of check-in days.
  final bool showRank;

  @override
  Widget build(BuildContext context) {
    final rank = participant.rankIndex == null
        ? null
        : rankFromIndex(participant.rankIndex!);

    final semanticsLabel = showRank && rank != null
        ? '$position, ${participant.username}, ${rank.displayName}'
        : '$position, ${participant.username}, '
            'streak ${participant.currentStreak}, '
            '${participant.completedDays} days';

    return Semantics(
      button: true,
      label: semanticsLabel,
      child: GestureDetector(
        onTap: () => context.push('/profile/${participant.userId}'),
        child: ExcludeSemantics(
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isMe
                  ? palette.accent.withValues(alpha: 0.1)
                  : palette.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isMe ? palette.accent : palette.border,
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    // Roster position is a stat — mono.
                    '$position',
                    textAlign: TextAlign.center,
                    style: FieldManual.readout(
                      fontSize: 13,
                      color: palette.text,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Rank challenges lead with the rank insignia disc.
                if (showRank && rank != null) ...[
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: rank.color.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: RankInsignia(rank: rank, size: 21),
                  ),
                  const SizedBox(width: 10),
                ] else ...[
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: palette.surfaceElevated,
                    backgroundImage: participant.profilePictureUrl != null
                        ? CachedNetworkImageProvider(participant.profilePictureUrl!)
                        : null,
                    child: participant.profilePictureUrl == null
                        ? Icon(CupertinoIcons.person_fill,
                            size: 16, color: palette.textSecondary)
                        : null,
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        // Usernames are user content — Inter, never uppercased.
                        participant.username,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontVariations: const [FontVariation('wght', 600)],
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: palette.text,
                        ),
                      ),
                      const SizedBox(height: 1),
                      if (showRank && rank != null)
                        Text(
                          // Rank-coloured small text wears the AA-lifted tone,
                          // never the raw rank colour.
                          rank.displayName.toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'Oswald',
                            fontVariations: const [FontVariation('wght', 500)],
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            letterSpacing: 0.4,
                            color: rank.textColor,
                          ),
                        )
                      else
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              // Streak is a stat — mono.
                              'STREAK ${participant.currentStreak}',
                              style: FieldManual.label(
                                fontSize: 11,
                                color: palette.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              CupertinoIcons.flame,
                              size: 12,
                              // Accent marks the viewer's own streak.
                              color: isMe
                                  ? palette.accent
                                  : palette.textSecondary,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (showRank && rank != null)
                  Text(
                    // Rank abbreviations are mono designations in the lifted tone.
                    rank.abbreviation,
                    style: FieldManual.label(
                      fontSize: 12,
                      color: rank.textColor,
                    ),
                  )
                else
                  Text(
                    // Check-in count is a stat — mono readout.
                    '${participant.completedDays} D',
                    style: FieldManual.readout(
                      fontSize: 14,
                      color: palette.accent,
                    ),
                  ),
              ],
            ),
          ),
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
          'PROOF FEED',
          style: FieldManual.title(color: palette.text),
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
                placeholder: (_, _) => Container(
                  color: palette.surfaceElevated,
                  child:
                      const Center(child: CupertinoActivityIndicator()),
                ),
                errorWidget: (_, _, _) => Container(
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

