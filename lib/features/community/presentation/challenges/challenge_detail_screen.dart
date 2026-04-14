import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show CircleAvatar, Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/community_providers.dart';
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
          return _ChallengeDetailBody(
            challenge: challenge,
            challengeId: challengeId,
          );
        },
      ),
    );
  }
}

class _ChallengeDetailBody extends ConsumerWidget {
  const _ChallengeDetailBody({
    required this.challenge,
    required this.challengeId,
  });

  final Challenge challenge;
  final String challengeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    final userId = ref.watch(currentUserIdProvider);
    final asyncIsParticipant = ref.watch(isParticipantProvider(challengeId));
    final asyncParticipants =
        ref.watch(challengeParticipantsProvider(challengeId));

    final daysRemaining = challenge.endDate != null
        ? challenge.endDate!.difference(DateTime.now()).inDays.clamp(0, 9999)
        : 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ─── Info card ───────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: palette.border, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (challenge.description.isNotEmpty) ...[
                Text(
                  challenge.description,
                  style: TextStyle(
                    fontFamily: 'LeagueSpartan',
                    fontSize: 14,
                    color: palette.text,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
              ],
              _infoRow(palette, 'Type', challenge.typeLabel),
              const SizedBox(height: 8),
              _infoRow(palette, 'Target', _targetLabel),
              const SizedBox(height: 8),
              _infoRow(
                palette,
                'Duration',
                '${challenge.durationDays} days ($daysRemaining remaining)',
              ),
              if (challenge.startDate != null) ...[
                const SizedBox(height: 8),
                _infoRow(
                  palette,
                  'Started',
                  _formatDate(challenge.startDate!),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ─── Personal progress ───────────────────────────────────────
        asyncParticipants.whenOrNull(
              data: (participants) {
                final mine = participants
                    .where((p) => p.userId == userId)
                    .toList();
                if (mine.isEmpty) return const SizedBox.shrink();

                final myProgress = mine.first.progress;
                final fraction = challenge.target > 0
                    ? (myProgress / challenge.target).clamp(0.0, 1.0)
                    : 0.0;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: palette.border, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Progress',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: palette.text,
                        ),
                      ),
                      const SizedBox(height: 12),
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
                                    width:
                                        constraints.maxWidth * fraction,
                                    decoration: BoxDecoration(
                                      color: palette.accent,
                                      borderRadius:
                                          BorderRadius.circular(4),
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
                        '${myProgress.toStringAsFixed(0)} / ${challenge.target.toStringAsFixed(0)}'
                        '  (${(fraction * 100).toStringAsFixed(0)}%)',
                        style: TextStyle(
                          fontFamily: 'LeagueSpartan',
                          fontSize: 13,
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ) ??
            const SizedBox.shrink(),

        const SizedBox(height: 16),

        // ─── Join / Leave button ─────────────────────────────────────
        asyncIsParticipant.when(
          loading: () => const CupertinoActivityIndicator(),
          error: (_, __) => const SizedBox.shrink(),
          data: (isJoined) => _JoinLeaveButton(
            isJoined: isJoined,
            challenge: challenge,
            challengeId: challengeId,
          ),
        ),

        const SizedBox(height: 24),

        // ─── Participants ────────────────────────────────────────────
        Text(
          'Participants',
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
                'No participants yet.',
                style: TextStyle(
                  fontFamily: 'LeagueSpartan',
                  fontSize: 14,
                  color: palette.textSecondary,
                ),
              );
            }
            return Column(
              children: List.generate(participants.length, (index) {
                final p = participants[index];
                return _participantRow(palette, index + 1, p, userId);
              }),
            );
          },
        ),
      ],
    );
  }

  String get _targetLabel {
    final unit = switch (challenge.type) {
      'streak' => 'days',
      'volume' => 'kg',
      'workouts' => 'workouts',
      _ => '',
    };
    return '${challenge.target.toStringAsFixed(0)} $unit';
  }

  Widget _infoRow(Palette palette, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'LeagueSpartan',
              fontSize: 13,
              color: palette.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'LeagueSpartan',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: palette.text,
            ),
          ),
        ),
      ],
    );
  }

  Widget _participantRow(
    Palette palette,
    int rank,
    ChallengeParticipant p,
    String? currentUserId,
  ) {
    final isMe = p.userId == currentUserId;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? palette.accent.withOpacity(0.1) : palette.surface,
        borderRadius: BorderRadius.circular(10),
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
            radius: 16,
            backgroundColor: palette.surfaceElevated,
            backgroundImage: p.profilePictureUrl != null
                ? CachedNetworkImageProvider(p.profilePictureUrl!)
                : null,
            child: p.profilePictureUrl == null
                ? Icon(
                    CupertinoIcons.person_fill,
                    size: 16,
                    color: palette.textSecondary,
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              p.username,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: palette.text,
              ),
            ),
          ),
          Text(
            p.progress.toStringAsFixed(0),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: palette.accent,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _JoinLeaveButton extends ConsumerStatefulWidget {
  const _JoinLeaveButton({
    required this.isJoined,
    required this.challenge,
    required this.challengeId,
  });

  final bool isJoined;
  final Challenge challenge;
  final String challengeId;

  @override
  ConsumerState<_JoinLeaveButton> createState() => _JoinLeaveButtonState();
}

class _JoinLeaveButtonState extends ConsumerState<_JoinLeaveButton> {
  bool _loading = false;

  Future<void> _toggle() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    setState(() => _loading = true);
    try {
      final repo = ref.read(challengeRepositoryProvider);
      if (widget.isJoined) {
        await repo.leaveChallenge(widget.challengeId, userId);
      } else {
        final user = await ref.read(firestoreUserProvider.future);
        final participant = ChallengeParticipant(
          challengeId: widget.challengeId,
          userId: userId,
          username: user?.username ?? '',
          profilePictureUrl: user?.profilePictureUrl,
        );
        await repo.joinChallenge(participant);
      }
      ref.invalidate(isParticipantProvider(widget.challengeId));
      ref.invalidate(challengeParticipantsProvider(widget.challengeId));
      ref.invalidate(challengeByIdProvider(widget.challengeId));
      ref.invalidate(myChallengesProvider);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

    if (_loading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 14),
        color: widget.isJoined ? palette.destructive : palette.accent,
        borderRadius: BorderRadius.circular(12),
        onPressed: _toggle,
        child: Text(
          widget.isJoined ? 'Leave Challenge' : 'Join Challenge',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: CupertinoColors.white,
          ),
        ),
      ),
    );
  }
}
