import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/community_providers.dart';
import '../../../ranks/domain/military_ranks.dart';
import '../../../ranks/presentation/widgets/rank_badge.dart';
import '../../data/challenge_repository.dart';
import '../../domain/challenge.dart';

class CreateChallengeScreen extends ConsumerStatefulWidget {
  const CreateChallengeScreen({super.key});

  @override
  ConsumerState<CreateChallengeScreen> createState() =>
      _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends ConsumerState<CreateChallengeScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _targetWeightController = TextEditingController();

  int _typeIndex = 0; // 0=workout, 1=nutrition, 2=habit
  int _durationIndex = 2; // 0=7, 1=14, 2=30, 3=60 → default 30
  bool _isPublic = true;
  bool _requiresPhotoProof = false;
  bool _isSaving = false;

  // Rank goal selection.
  int _goalIndex = 0; // index into _goalTypes
  int _targetRankIndex = 4; // default Sergeant
  int _goalLiftIndex = 0; // 0 bench, 1 squat, 2 deadlift

  static const _goalTypes = [
    RankGoalType.none,
    RankGoalType.overallRank,
    RankGoalType.liftWeight,
    RankGoalType.big3Total,
  ];
  static const _goalLabels = {
    0: 'Habit',
    1: 'Rank',
    2: 'Lift',
    3: 'Big 3',
  };

  // (exercise id, display label) per lift option.
  static const _liftOptions = [
    ('barbell_bench_press', 'Bench'),
    ('barbell_back_squat', 'Squat'),
    ('conventional_deadlift', 'Deadlift'),
  ];

  static const _typeKeys = ['workout', 'nutrition', 'habit'];
  static const _typeLabels = {0: 'Workout', 1: 'Nutrition', 2: 'Habit'};
  static const _durationDays = [7, 14, 30, 60];
  static const _durationLabels = {
    0: '7 days',
    1: '14 days',
    2: '30 days',
    3: '60 days',
  };

  RankGoalType get _goalType => _goalTypes[_goalIndex];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showError('Please enter a title.');
      return;
    }

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final goalType = _goalType;
    if ((goalType == RankGoalType.liftWeight ||
            goalType == RankGoalType.big3Total) &&
        (double.tryParse(_targetWeightController.text.trim()) ?? 0) <= 0) {
      _showError('Enter a target weight in lbs for this goal.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = await ref.read(firestoreUserProvider.future);
      final repo = ref.read(challengeRepositoryProvider);
      final id = const Uuid().v4();
      final now = DateTime.now().toUtc();
      final duration = _durationDays[_durationIndex];
      final endDate = now.add(Duration(days: duration));

      // Rank challenges are always strength-typed.
      final type = goalType == RankGoalType.none
          ? _typeKeys[_typeIndex]
          : 'workout';
      final targetWeight =
          double.tryParse(_targetWeightController.text.trim());
      final lift = _liftOptions[_goalLiftIndex];

      final challenge = Challenge(
        challengeId: id,
        title: title,
        description: _descController.text.trim(),
        creatorId: userId,
        creatorUsername: user?.username ?? '',
        type: type,
        durationDays: duration,
        startDate: now,
        endDate: endDate,
        participantCount: 1,
        isPublic: _isPublic,
        requiresPhotoProof: _requiresPhotoProof,
        createdAt: now,
        rankGoalType: goalType,
        targetRankIndex:
            goalType == RankGoalType.overallRank ? _targetRankIndex : null,
        goalExerciseId:
            goalType == RankGoalType.liftWeight ? lift.$1 : null,
        goalExerciseLabel:
            goalType == RankGoalType.liftWeight ? lift.$2 : null,
        targetWeightLbs: (goalType == RankGoalType.liftWeight ||
                goalType == RankGoalType.big3Total)
            ? targetWeight
            : null,
      );

      await repo.createChallenge(challenge);

      // Auto-join creator.
      final participant = ChallengeParticipant(
        challengeId: id,
        userId: userId,
        username: user?.username ?? '',
        profilePictureUrl: user?.profilePictureUrl,
        joinedAt: now,
        rankIndex: user?.rankIndex,
      );
      await repo.joinChallenge(participant);

      ref.invalidate(publicChallengesProvider);
      ref.invalidate(myChallengesProvider);

      if (mounted) {
        // Replace the create screen with the detail screen.
        context.pushReplacement('/community/challenge/$id');
      }
    } catch (e) {
      if (mounted) _showError('Could not create challenge: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) {
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Could not create'),
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

    return CupertinoPageScaffold(
      backgroundColor: palette.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: palette.surface,
        border: Border(
          bottom: BorderSide(color: palette.border, width: 0.5),
        ),
        middle: Text(
          'Create Challenge',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: palette.text,
          ),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _label(palette, 'Title'),
            const SizedBox(height: 6),
            CupertinoTextField(
              controller: _titleController,
              placeholder: 'Challenge title',
              maxLength: 60,
              maxLines: 1,
              padding: const EdgeInsets.all(14),
              style: TextStyle(
                fontFamily: 'LeagueSpartan',
                fontSize: 15,
                color: palette.text,
              ),
              placeholderStyle: TextStyle(
                fontFamily: 'LeagueSpartan',
                fontSize: 15,
                color: palette.textSecondary,
              ),
              decoration: _fieldDecoration(palette),
            ),

            const SizedBox(height: 20),

            _label(palette, 'Description'),
            const SizedBox(height: 6),
            CupertinoTextField(
              controller: _descController,
              placeholder: 'What is this challenge about?',
              maxLength: 500,
              maxLines: 4,
              padding: const EdgeInsets.all(14),
              style: TextStyle(
                fontFamily: 'LeagueSpartan',
                fontSize: 15,
                color: palette.text,
              ),
              placeholderStyle: TextStyle(
                fontFamily: 'LeagueSpartan',
                fontSize: 15,
                color: palette.textSecondary,
              ),
              decoration: _fieldDecoration(palette),
            ),

            const SizedBox(height: 20),

            _label(palette, 'Goal'),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: CupertinoSlidingSegmentedControl<int>(
                groupValue: _goalIndex,
                thumbColor: palette.accent,
                backgroundColor: palette.surface,
                children: _goalLabels.map(
                  (key, label) => MapEntry(
                    key,
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: _goalIndex == key
                              ? CupertinoColors.white
                              : palette.text,
                        ),
                      ),
                    ),
                  ),
                ),
                onValueChanged: (value) {
                  if (value != null) {
                    HapticFeedback.selectionClick();
                    setState(() => _goalIndex = value);
                  }
                },
              ),
            ),

            // Goal-specific inputs.
            if (_goalType == RankGoalType.overallRank) ...[
              const SizedBox(height: 12),
              _label(palette, 'Target rank'),
              const SizedBox(height: 6),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: MilitaryRank.values.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final rank = MilitaryRank.values[index];
                    final selected = _targetRankIndex == index;
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _targetRankIndex = index);
                      },
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: selected
                              ? rank.color.withValues(alpha: 0.18)
                              : palette.surface,
                          borderRadius: BorderRadius.circular(19),
                          border: Border.all(
                            color: selected ? rank.color : palette.border,
                            width: selected ? 1.2 : 0.5,
                          ),
                        ),
                        child: RankBadge(rank: rank, compact: true, size: 16),
                      ),
                    );
                  },
                ),
              ),
            ],
            if (_goalType == RankGoalType.liftWeight) ...[
              const SizedBox(height: 12),
              _label(palette, 'Lift'),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: CupertinoSlidingSegmentedControl<int>(
                  groupValue: _goalLiftIndex,
                  thumbColor: palette.accent,
                  backgroundColor: palette.surface,
                  children: {
                    for (var i = 0; i < _liftOptions.length; i++)
                      i: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        child: Text(
                          _liftOptions[i].$2,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _goalLiftIndex == i
                                ? CupertinoColors.white
                                : palette.text,
                          ),
                        ),
                      ),
                  },
                  onValueChanged: (value) {
                    if (value != null) {
                      HapticFeedback.selectionClick();
                      setState(() => _goalLiftIndex = value);
                    }
                  },
                ),
              ),
              const SizedBox(height: 10),
              _targetWeightField(palette, 'Target weight (lbs)'),
            ],
            if (_goalType == RankGoalType.big3Total) ...[
              const SizedBox(height: 12),
              _targetWeightField(palette, 'Target big-3 total (lbs)'),
            ],

            const SizedBox(height: 20),

            // Challenge type only applies to non-rank (habit) challenges.
            if (_goalType == RankGoalType.none) ...[
              _label(palette, 'Type'),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: CupertinoSlidingSegmentedControl<int>(
                  groupValue: _typeIndex,
                  thumbColor: palette.accent,
                  backgroundColor: palette.surface,
                  children: _typeLabels.map(
                    (key, label) => MapEntry(
                      key,
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _typeIndex == key
                                ? CupertinoColors.white
                                : palette.text,
                          ),
                        ),
                      ),
                    ),
                  ),
                  onValueChanged: (value) {
                    if (value != null) {
                      HapticFeedback.selectionClick();
                      setState(() => _typeIndex = value);
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],

            _label(palette, 'Duration'),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: CupertinoSlidingSegmentedControl<int>(
                groupValue: _durationIndex,
                thumbColor: palette.accent,
                backgroundColor: palette.surface,
                children: _durationLabels.map(
                  (key, label) => MapEntry(
                    key,
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 6),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _durationIndex == key
                              ? CupertinoColors.white
                              : palette.text,
                        ),
                      ),
                    ),
                  ),
                ),
                onValueChanged: (value) {
                  if (value != null) {
                    HapticFeedback.selectionClick();
                    setState(() => _durationIndex = value);
                  }
                },
              ),
            ),

            const SizedBox(height: 20),

            _switchRow(
              palette: palette,
              label: 'Public challenge',
              subtitle: 'Anyone can discover and join',
              value: _isPublic,
              onChanged: (v) => setState(() => _isPublic = v),
            ),
            const SizedBox(height: 10),
            _switchRow(
              palette: palette,
              label: 'Photo proof required',
              subtitle: 'Participants upload a photo for each check-in',
              value: _requiresPhotoProof,
              onChanged: (v) => setState(() => _requiresPhotoProof = v),
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 14),
                color: palette.accent,
                borderRadius: BorderRadius.circular(12),
                onPressed: _isSaving
                    ? null
                    : () {
                        HapticFeedback.mediumImpact();
                        _create();
                      },
                child: _isSaving
                    ? const CupertinoActivityIndicator(
                        color: CupertinoColors.white,
                      )
                    : const Text(
                        'Create Challenge',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: CupertinoColors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _fieldDecoration(Palette palette) => BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border, width: 0.5),
      );

  Widget _label(Palette palette, String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w500,
        fontSize: 13,
        color: palette.textSecondary,
      ),
    );
  }

  Widget _targetWeightField(Palette palette, String placeholder) {
    return CupertinoTextField(
      controller: _targetWeightController,
      placeholder: placeholder,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      padding: const EdgeInsets.all(14),
      style: TextStyle(
        fontFamily: 'LeagueSpartan',
        fontSize: 15,
        color: palette.text,
      ),
      placeholderStyle: TextStyle(
        fontFamily: 'LeagueSpartan',
        fontSize: 15,
        color: palette.textSecondary,
      ),
      decoration: _fieldDecoration(palette),
    );
  }

  Widget _switchRow({
    required Palette palette,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: _fieldDecoration(palette),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'LeagueSpartan',
                    fontSize: 12,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            activeTrackColor: palette.accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
