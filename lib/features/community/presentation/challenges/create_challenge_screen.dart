import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/field_manual.dart';
import '../../../../core/widgets/fm_segmented.dart';
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
      backgroundColor: palette.scaffold,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: palette.background.withValues(alpha: 0.82),
        border: Border(bottom: BorderSide(color: palette.border)),
        middle: Text(
          'CREATE CHALLENGE',
          style: FieldManual.title(color: palette.text),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _label(palette, 'Title'),
            const SizedBox(height: 6),
            _FMTextField(
              controller: _titleController,
              placeholder: 'Challenge title',
              maxLength: 60,
              maxLines: 1,
            ),

            const SizedBox(height: 20),

            _label(palette, 'Description'),
            const SizedBox(height: 6),
            _FMTextField(
              controller: _descController,
              placeholder: 'What is this challenge about?',
              maxLength: 500,
              maxLines: 4,
            ),

            const SizedBox(height: 20),

            _label(palette, 'Goal'),
            const SizedBox(height: 6),
            FmSegmented<int>(
              segments: [
                for (final MapEntry(:key, :value) in _goalLabels.entries)
                  (key, value),
              ],
              selected: _goalIndex,
              onChanged: (value) => setState(() => _goalIndex = value),
            ),

            // Goal-specific inputs.
            if (_goalType == RankGoalType.overallRank) ...[
              const SizedBox(height: 12),
              _label(palette, 'Target rank'),
              const SizedBox(height: 6),
              SizedBox(
                // ≥44pt touch targets; scales with Dynamic Type.
                height: MediaQuery.textScalerOf(context).scale(44),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: MilitaryRank.values.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final rank = MilitaryRank.values[index];
                    final selected = _targetRankIndex == index;
                    // Insignia + abbreviation stay in canonical tier colours;
                    // the selected chip borrows the rank colour for structure
                    // (border/tint), never for reading text.
                    return Semantics(
                      button: true,
                      selected: selected,
                      label: rank.displayName,
                      child: ExcludeSemantics(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _targetRankIndex = index);
                          },
                          child: Container(
                            alignment: Alignment.center,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              // 0.14 alpha keeps every tier's textColor at
                              // ≥4.5:1 on the tinted ground (tier 4 fails
                              // at 0.18).
                              color: selected
                                  ? rank.color.withValues(alpha: 0.14)
                                  : palette.surface,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color:
                                    selected ? rank.color : palette.border,
                                width: selected ? 1.2 : 1.0,
                              ),
                            ),
                            child:
                                RankBadge(rank: rank, compact: true, size: 16),
                          ),
                        ),
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
              FmSegmented<int>(
                segments: [
                  for (var i = 0; i < _liftOptions.length; i++)
                    (i, _liftOptions[i].$2),
                ],
                selected: _goalLiftIndex,
                onChanged: (value) => setState(() => _goalLiftIndex = value),
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
              FmSegmented<int>(
                segments: [
                  for (final MapEntry(:key, :value) in _typeLabels.entries)
                    (key, value),
                ],
                selected: _typeIndex,
                onChanged: (value) => setState(() => _typeIndex = value),
              ),
              const SizedBox(height: 20),
            ],

            _label(palette, 'Duration'),
            const SizedBox(height: 6),
            FmSegmented<int>(
              segments: [
                for (final MapEntry(:key, :value) in _durationLabels.entries)
                  (key, value),
              ],
              selected: _durationIndex,
              onChanged: (value) => setState(() => _durationIndex = value),
              fontSize: 10,
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
            // Spoken label stays sentence case; uppercase is visual only.
            SizedBox(
              width: double.infinity,
              child: Semantics(
                label: 'Create challenge',
                button: true,
                child: ExcludeSemantics(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    color: palette.accent,
                    borderRadius: BorderRadius.circular(4),
                    onPressed: _isSaving
                        ? null
                        : () {
                            HapticFeedback.mediumImpact();
                            _create();
                          },
                    child: _isSaving
                        ? CupertinoActivityIndicator(
                            color: palette.onAccent,
                          )
                        : Text(
                            'CREATE CHALLENGE',
                            style: TextStyle(
                              fontFamily: 'Oswald',
                              fontVariations: const [
                                FontVariation('wght', 600),
                              ],
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
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
    );
  }

  /// Mono designation eyebrow above each form group.
  Widget _label(Palette palette, String text) {
    return Text(
      text.toUpperCase(),
      style: FieldManual.label(fontSize: 11, color: palette.textSecondary),
    );
  }

  Widget _targetWeightField(Palette palette, String placeholder) {
    return _FMTextField(
      controller: _targetWeightController,
      placeholder: placeholder,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      mono: true,
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
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: FieldManual.body(fontSize: 14, color: palette.text)
                      .copyWith(
                    fontVariations: const [FontVariation('wght', 600)],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: FieldManual.body(
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

/// Field Manual text input: field-raised fill, hairline border that shifts to
/// the live accent on focus, no glow (DESIGN.md §Inputs). Numeric entry sets
/// [mono] for instrument-panel digits. Purely visual — behaviour is the inner
/// [CupertinoTextField]'s.
class _FMTextField extends StatefulWidget {
  const _FMTextField({
    required this.controller,
    required this.placeholder,
    this.maxLength,
    this.maxLines = 1,
    this.keyboardType,
    this.mono = false,
  });

  final TextEditingController controller;
  final String placeholder;
  final int? maxLength;
  final int maxLines;
  final TextInputType? keyboardType;
  final bool mono;

  @override
  State<_FMTextField> createState() => _FMTextFieldState();
}

class _FMTextFieldState extends State<_FMTextField> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() => setState(() {});

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final focused = _focusNode.hasFocus;
    return CupertinoTextField(
      controller: widget.controller,
      focusNode: _focusNode,
      placeholder: widget.placeholder,
      maxLength: widget.maxLength,
      maxLines: widget.maxLines,
      keyboardType: widget.keyboardType,
      padding: const EdgeInsets.all(14),
      cursorColor: palette.accent,
      style: widget.mono
          ? FieldManual.readout(fontSize: 15, color: palette.text)
          : FieldManual.body(fontSize: 15, color: palette.text),
      placeholderStyle: FieldManual.body(
        fontSize: 15,
        color: palette.textSecondary,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: focused ? palette.accent : palette.border,
        ),
      ),
    );
  }
}
