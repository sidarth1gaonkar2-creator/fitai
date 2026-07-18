import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/field_manual.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/fm_segmented.dart';
import '../../../../data/premade_challenges.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/community_providers.dart';
import '../../../ranks/domain/military_ranks.dart';
import '../../../ranks/presentation/widgets/rank_badge.dart';
import '../../data/challenge_repository.dart';
import '../../domain/challenge.dart';
import 'challenge_goal_progress_view.dart';

class ChallengesScreen extends ConsumerStatefulWidget {
  const ChallengesScreen({super.key});

  @override
  ConsumerState<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends ConsumerState<ChallengesScreen> {
  int _selectedTab = 0; // 0 Browse, 1 My Challenges
  String? _startingId; // premade being started right now

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

    return Container(
      color: palette.background,
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Tab toggle + create button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: FmSegmented<int>(
                    segments: const [(0, 'Browse'), (1, 'My Challenges')],
                    selected: _selectedTab,
                    onChanged: (value) =>
                        setState(() => _selectedTab = value),
                  ),
                ),
                const SizedBox(width: 12),
                // Spoken label stays sentence case; uppercase is visual only.
                Semantics(
                  label: 'Create challenge',
                  button: true,
                  child: ExcludeSemantics(
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        context.push('/community/challenge/create');
                      },
                      child: Container(
                        alignment: Alignment.center,
                        constraints:
                            const BoxConstraints(minHeight: 44, minWidth: 44),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: palette.accent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'CREATE',
                          style: TextStyle(
                            fontFamily: 'Oswald',
                            fontVariations: const [FontVariation('wght', 600)],
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            letterSpacing: 0.6,
                            color: palette.onAccent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Expanded(
            child: _selectedTab == 0
                ? _buildBrowseTab(palette)
                : _buildMyTab(palette),
          ),
        ],
      ),
    );
  }

  // ─── Browse tab ──────────────────────────────────────────────────────────

  Widget _buildBrowseTab(Palette palette) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _sectionHeader(palette, 'Featured Challenges'),
        const SizedBox(height: 8),
        SizedBox(
          // Scales with Dynamic Type so the card's internal Column can't
          // overflow at accessibility text sizes.
          height: MediaQuery.textScalerOf(context).scale(248),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: premadeChallenges.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final pm = premadeChallenges[index];
              return _PremadeCard(
                premade: pm,
                palette: palette,
                starting: _startingId == pm.id,
                onStart: () => _startPremade(pm),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        _sectionHeader(palette, 'Community Challenges'),
        const SizedBox(height: 8),
        _CommunityChallengesSection(palette: palette),
      ],
    );
  }

  Widget _sectionHeader(Palette palette, String title) {
    // Section headers wear the condensed display face in bone (DESIGN.md).
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Text(
        title.toUpperCase(),
        style: FieldManual.title(color: palette.text),
      ),
    );
  }

  Widget _buildMyTab(Palette palette) {
    final asyncChallenges = ref.watch(myChallengesProvider);

    return asyncChallenges.when(
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (e, st) => _buildError(palette, e, st),
      data: (challenges) {
        if (challenges.isEmpty) {
          return _buildEmpty(
            palette,
            icon: CupertinoIcons.flag,
            title: 'No challenges joined',
            subtitle: 'Pick one from the Browse tab to get started.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: challenges.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) =>
              _ChallengeCard(challenge: challenges[index], palette: palette),
        );
      },
    );
  }

  // ─── Start premade challenge ─────────────────────────────────────────────

  Future<void> _startPremade(PremadeChallenge pm) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    setState(() => _startingId = pm.id);
    HapticFeedback.mediumImpact();

    try {
      final user = await ref.read(firestoreUserProvider.future);
      final repo = ref.read(challengeRepositoryProvider);
      final id = const Uuid().v4();
      final now = DateTime.now().toUtc();
      final endDate = now.add(Duration(days: pm.durationDays));

      final challenge = Challenge(
        challengeId: id,
        title: pm.title,
        description: pm.description,
        creatorId: 'system',
        creatorUsername: 'DrillFit',
        type: premadeTypeFromCategory(pm.category),
        durationDays: pm.durationDays,
        startDate: now,
        endDate: endDate,
        participantCount: 1,
        isPublic: false, // solo premade by default
        requiresPhotoProof: pm.requiresPhotoProof,
        proofInstructions: pm.proofInstructions,
        category: pm.category,
        icon: pm.icon,
        difficulty: pm.difficulty,
        createdAt: now,
        rankGoalType: pm.rankGoalType,
        targetRankIndex: pm.targetRankIndex,
        goalExerciseId: pm.goalExerciseId,
        goalExerciseLabel: pm.goalExerciseLabel,
        targetWeightLbs: pm.targetWeightLbs,
        targetBodyweightMultiple: pm.targetBodyweightMultiple,
      );
      await repo.createChallenge(challenge);

      await repo.joinChallenge(ChallengeParticipant(
        challengeId: id,
        userId: userId,
        username: user?.username ?? '',
        profilePictureUrl: user?.profilePictureUrl,
        joinedAt: now,
        rankIndex: user?.rankIndex,
      ));

      ref.invalidate(myChallengesProvider);
      ref.invalidate(publicChallengesProvider);

      if (mounted) {
        context.push('/community/challenge/$id');
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog<void>(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('Could not start'),
            content: Text('$e'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _startingId = null);
    }
  }

  Widget _buildEmpty(
    Palette palette, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    // Drill-sergeant eyebrow + sentence-case guidance (DESIGN.md).
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: palette.textSecondary),
            const SizedBox(height: 12),
            Text(
              title.toUpperCase(),
              textAlign: TextAlign.center,
              style: FieldManual.label(
                fontSize: 12,
                color: palette.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
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

  Widget _buildError(Palette palette, Object error, StackTrace? stack) {
    // Full diagnostics (incl. any missing-composite-index hint) go to the
    // log; the user gets a plain sentence.
    var reason = '[Challenges] load failed';
    if (error is FirebaseException && error.code == 'failed-precondition') {
      reason += ' (query likely needs a composite index — check the '
          'console for the creation link)';
    }
    AppLogger.error(reason, error: error, stack: stack);

    const detail = "Couldn't load challenges. Try again in a moment.";

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.exclamationmark_triangle,
                size: 40, color: palette.textSecondary),
            const SizedBox(height: 12),
            Text(
              'COULD NOT LOAD CHALLENGES',
              textAlign: TextAlign.center,
              style: FieldManual.label(
                fontSize: 12,
                color: palette.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: FieldManual.body(
                fontSize: 12,
                color: palette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Community challenges list ─────────────────────────────────────────────

class _CommunityChallengesSection extends ConsumerWidget {
  const _CommunityChallengesSection({required this.palette});

  final Palette palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncChallenges = ref.watch(publicChallengesProvider);

    return asyncChallenges.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CupertinoActivityIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Could not load community challenges.',
          style: FieldManual.body(
            fontSize: 13,
            color: palette.textSecondary,
          ),
        ),
      ),
      data: (challenges) {
        // Hide system-created premade duplicates from the Community section.
        final visible = challenges
            .where((c) => c.creatorId != 'system' && c.isPublic)
            .toList();
        if (visible.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(
              'No community challenges yet. Create the first one!',
              style: FieldManual.body(
                fontSize: 14,
                color: palette.textSecondary,
              ),
            ),
          );
        }
        return Column(
          children: [
            for (final c in visible)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 5),
                child: _ChallengeCard(challenge: c, palette: palette),
              ),
          ],
        );
      },
    );
  }
}

// ─── Premade card ──────────────────────────────────────────────────────────

class _PremadeCard extends StatelessWidget {
  const _PremadeCard({
    required this.premade,
    required this.palette,
    required this.starting,
    required this.onStart,
  });

  final PremadeChallenge premade;
  final Palette palette;
  final bool starting;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(14),
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
              Text(premade.icon, style: const TextStyle(fontSize: 24)),
              const Spacer(),
              // Difficulty is metadata, not a consequence — quiet mono stamp,
              // not a coloured alert (the One Voice Rule).
              _chip(premade.difficulty, palette.textSecondary),
            ],
          ),
          const SizedBox(height: 8),
          // Target rank badge (or goal pill for weight challenges). Insignia
          // and abbreviation render in canonical tier colours (RankBadge uses
          // rank.textColor for the small text itself).
          if (premade.targetRankIndex != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: rankFromIndex(premade.targetRankIndex!)
                      .color
                      .withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: RankBadge(
                  rank: rankFromIndex(premade.targetRankIndex!),
                  compact: true,
                  size: 18,
                ),
              ),
            )
          else
            Align(
              alignment: Alignment.centerLeft,
              child: _chip(premade.category, palette.accent),
            ),
          const SizedBox(height: 8),
          // Premade titles are system designations — they may wear the bark.
          Text(
            premade.title.toUpperCase(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: FieldManual.title(color: palette.text),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              premade.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: FieldManual.body(
                fontSize: 12,
                color: palette.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(CupertinoIcons.clock,
                  size: 13, color: palette.textSecondary),
              const SizedBox(width: 4),
              Text(
                // Duration is a trained-against number — mono readout.
                '${premade.durationDays} DAYS',
                style: FieldManual.label(
                  fontSize: 11,
                  color: palette.textSecondary,
                ),
              ),
              if (premade.requiresPhotoProof) ...[
                const SizedBox(width: 10),
                Icon(CupertinoIcons.camera,
                    size: 13, color: palette.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'PHOTO',
                  style: FieldManual.label(
                    fontSize: 11,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: Semantics(
              label: 'Start challenge',
              button: true,
              child: ExcludeSemantics(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  color: palette.accent,
                  borderRadius: BorderRadius.circular(4),
                  onPressed: starting ? null : onStart,
                  child: starting
                      ? CupertinoActivityIndicator(color: palette.onAccent)
                      : Text(
                          'START CHALLENGE',
                          style: TextStyle(
                            fontFamily: 'Oswald',
                            fontVariations: const [
                              FontVariation('wght', 600),
                            ],
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            letterSpacing: 0.6,
                            color: palette.onAccent,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: palette.border),
      ),
      child: Text(
        text.toUpperCase(),
        style: FieldManual.label(fontSize: 10, color: color),
      ),
    );
  }
}

// ─── Community / my challenge card ─────────────────────────────────────────

class _ChallengeCard extends ConsumerWidget {
  const _ChallengeCard({required this.challenge, required this.palette});

  final Challenge challenge;
  final Palette palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysRemaining = challenge.endDate != null
        ? challenge.endDate!.difference(DateTime.now()).inDays.clamp(0, 9999)
        : challenge.durationDays;
    final elapsed = challenge.durationDays - daysRemaining;
    final dayProgress = challenge.durationDays > 0
        ? (elapsed / challenge.durationDays).clamp(0.0, 1.0)
        : 0.0;

    return Semantics(
      button: true,
      label: [
        challenge.title,
        if (!challenge.isRankGoal) '$daysRemaining days left',
        '${challenge.participantCount} participants',
      ].join(', '),
      child: GestureDetector(
        onTap: () =>
            context.push('/community/challenge/${challenge.challengeId}'),
        child: ExcludeSemantics(
          child: Container(
            padding: const EdgeInsets.all(14),
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
                    if (challenge.icon != null) ...[
                      Text(challenge.icon!, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        // User-created titles are never uppercased and never wear
                        // the display face (the Bark Budget Rule).
                        challenge.title,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontVariations: const [FontVariation('wght', 600)],
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: palette.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (challenge.isRankGoal)
                      ChallengeTargetBadge(challenge: challenge, size: 18)
                    else
                      _typeChip(),
                  ],
                ),
                const SizedBox(height: 12),

                // Rank-goal: show the user's progress toward the rank objective.
                // Legacy challenge: keep the day-count bar.
                if (challenge.isRankGoal)
                  ChallengeGoalProgressView(challenge: challenge, dense: true)
                else ...[
                  _dayBar(dayProgress),
                  const SizedBox(height: 8),
                  Text(
                    '$daysRemaining DAYS LEFT',
                    style: FieldManual.label(
                      fontSize: 11,
                      color: palette.textSecondary,
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                // Participants: count + top-3 rank badges.
                _ParticipantStrip(challenge: challenge, palette: palette),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _typeChip() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: palette.accent.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          challenge.typeLabel.toUpperCase(),
          style: FieldManual.label(fontSize: 10, color: palette.accent),
        ),
      );

  Widget _dayBar(double progress) => Semantics(
        label: 'Challenge time elapsed',
        value: '${(progress * 100).round()}%',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            height: 6,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                return Stack(
                  children: [
                    Container(width: width, color: palette.surfaceElevated),
                    Container(
                      width: width * progress,
                      decoration: BoxDecoration(
                        color: palette.accent,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
}

/// Participant count + up to three top participants' rank insignia, ranked by
/// strength. Reads the challenge's participant roster (cached per challenge).
class _ParticipantStrip extends ConsumerWidget {
  const _ParticipantStrip({required this.challenge, required this.palette});

  final Challenge challenge;
  final Palette palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parts =
        ref.watch(challengeParticipantsProvider(challenge.challengeId)).valueOrNull;
    final ranked = (parts ?? [])
        .where((p) => p.rankIndex != null)
        .toList()
      ..sort((a, b) => b.rankIndex!.compareTo(a.rankIndex!));
    final top = ranked.take(3).toList();

    return Semantics(
      label: '${challenge.participantCount} participants',
      child: ExcludeSemantics(
        child: Row(
          children: [
            Icon(CupertinoIcons.person_2_fill,
                size: 14, color: palette.textSecondary),
            const SizedBox(width: 4),
            Text(
              // Participant count is a stat — mono.
              '${challenge.participantCount}',
              style: FieldManual.label(
                fontSize: 12,
                color: palette.textSecondary,
              ),
            ),
            const Spacer(),
            for (final p in top)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: rankFromIndex(p.rankIndex!)
                        .color
                        .withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: RankInsignia(
                      rank: rankFromIndex(p.rankIndex!), size: 17),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
