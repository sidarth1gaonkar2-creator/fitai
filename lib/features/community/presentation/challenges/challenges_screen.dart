import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/premade_challenges.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/community_providers.dart';
import '../../data/challenge_repository.dart';
import '../../domain/challenge.dart';

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
                  child: CupertinoSlidingSegmentedControl<int>(
                    groupValue: _selectedTab,
                    thumbColor: palette.accent,
                    backgroundColor: palette.surface,
                    children: {
                      0: _segLabel('Browse', _selectedTab == 0, palette),
                      1: _segLabel(
                          'My Challenges', _selectedTab == 1, palette),
                    },
                    onValueChanged: (value) {
                      if (value != null) {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedTab = value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    context.push('/community/challenge/create');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: palette.accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Create',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.white,
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

  Widget _segLabel(String text, bool selected, Palette palette) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: selected ? CupertinoColors.white : palette.text,
        ),
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
          height: 220,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: palette.text,
        ),
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
        creatorUsername: 'AtlasFit',
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
      );
      await repo.createChallenge(challenge);

      await repo.joinChallenge(ChallengeParticipant(
        challengeId: id,
        userId: userId,
        username: user?.username ?? '',
        profilePictureUrl: user?.profilePictureUrl,
        joinedAt: now,
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: palette.textSecondary),
            const SizedBox(height: 12),
            Text(
              title,
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
              subtitle,
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

  Widget _buildError(Palette palette, Object error, StackTrace? stack) {
    debugPrint('[Challenges] load failed: $error');
    if (stack != null) debugPrint('$stack');

    String detail;
    if (error is FirebaseException) {
      detail = 'Firestore ${error.code}: ${error.message ?? ''}';
      if (error.code == 'failed-precondition') {
        detail += '\n\nThis query needs a composite index. '
            'Check the debug console for a link to create it in Firebase.';
      }
    } else {
      detail = '$error';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 40, color: palette.textSecondary),
            const SizedBox(height: 12),
            Text(
              'Could not load challenges',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'LeagueSpartan',
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
          style: TextStyle(
            fontFamily: 'LeagueSpartan',
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
              style: TextStyle(
                fontFamily: 'LeagueSpartan',
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

  Color _difficultyColor() {
    switch (premade.difficulty) {
      case 'Easy':
        return palette.success;
      case 'Hard':
        return palette.destructive;
      case 'Medium':
      default:
        return palette.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(14),
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
              Text(premade.icon, style: const TextStyle(fontSize: 24)),
              const Spacer(),
              _chip(premade.category, palette.accent),
              const SizedBox(width: 6),
              _chip(premade.difficulty, _difficultyColor()),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            premade.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: palette.text,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              premade.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'LeagueSpartan',
                fontSize: 12,
                color: palette.textSecondary,
                height: 1.3,
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
                '${premade.durationDays} days',
                style: TextStyle(
                  fontFamily: 'LeagueSpartan',
                  fontSize: 12,
                  color: palette.textSecondary,
                ),
              ),
              if (premade.requiresPhotoProof) ...[
                const SizedBox(width: 10),
                Icon(CupertinoIcons.camera,
                    size: 13, color: palette.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'Photo',
                  style: TextStyle(
                    fontFamily: 'LeagueSpartan',
                    fontSize: 12,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 10),
              color: palette.accent,
              borderRadius: BorderRadius.circular(10),
              onPressed: starting ? null : onStart,
              child: starting
                  ? const CupertinoActivityIndicator(
                      color: CupertinoColors.white,
                    )
                  : const Text(
                      'Start Challenge',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.white,
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'LeagueSpartan',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ─── Community challenge card ──────────────────────────────────────────────

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({required this.challenge, required this.palette});

  final Challenge challenge;
  final Palette palette;

  @override
  Widget build(BuildContext context) {
    final daysRemaining = challenge.endDate != null
        ? challenge.endDate!.difference(DateTime.now()).inDays.clamp(0, 9999)
        : challenge.durationDays;
    final elapsed = challenge.durationDays - daysRemaining;
    final progress = challenge.durationDays > 0
        ? (elapsed / challenge.durationDays).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTap: () =>
          context.push('/community/challenge/${challenge.challengeId}'),
      child: Container(
        padding: const EdgeInsets.all(14),
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
                if (challenge.icon != null) ...[
                  Text(challenge.icon!, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    challenge.title,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: palette.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: palette.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    challenge.typeLabel,
                    style: TextStyle(
                      fontFamily: 'LeagueSpartan',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: palette.accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(CupertinoIcons.person_2_fill,
                    size: 14, color: palette.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${challenge.participantCount}',
                  style: TextStyle(
                    fontFamily: 'LeagueSpartan',
                    fontSize: 13,
                    color: palette.textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(CupertinoIcons.clock,
                    size: 14, color: palette.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '$daysRemaining days left',
                  style: TextStyle(
                    fontFamily: 'LeagueSpartan',
                    fontSize: 13,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: SizedBox(
                height: 6,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    return Stack(
                      children: [
                        Container(
                          width: width,
                          color: palette.surfaceElevated,
                        ),
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
          ],
        ),
      ),
    );
  }
}
