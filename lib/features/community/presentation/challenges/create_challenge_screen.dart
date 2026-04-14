import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/community_providers.dart';
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
  final _targetController = TextEditingController();

  int _typeIndex = 0; // 0=Streak, 1=Volume, 2=Workouts
  int _durationIndex = 0; // 0=7, 1=14, 2=30, 3=60
  bool _isPublic = true;
  bool _isSaving = false;

  static const _typeKeys = ['streak', 'volume', 'workouts'];
  static const _typeLabels = {0: 'Streak', 1: 'Volume', 2: 'Workouts'};
  static const _durationDays = [7, 14, 30, 60];
  static const _durationLabels = {
    0: '7 days',
    1: '14 days',
    2: '30 days',
    3: '60 days',
  };

  String get _targetUnit => switch (_typeKeys[_typeIndex]) {
        'streak' => 'days',
        'volume' => 'kg',
        'workouts' => 'count',
        _ => '',
      };

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    final targetVal = double.tryParse(_targetController.text.trim());
    if (targetVal == null || targetVal <= 0) return;

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    setState(() => _isSaving = true);

    try {
      final user = await ref.read(firestoreUserProvider.future);
      final repo = ref.read(challengeRepositoryProvider);
      final id = const Uuid().v4();
      final now = DateTime.now().toUtc();
      final duration = _durationDays[_durationIndex];
      final endDate = now.add(Duration(days: duration));

      final challenge = Challenge(
        challengeId: id,
        title: title,
        description: _descController.text.trim(),
        creatorId: userId,
        creatorUsername: user?.username ?? '',
        type: _typeKeys[_typeIndex],
        target: targetVal,
        durationDays: duration,
        startDate: now,
        endDate: endDate,
        participantCount: 1,
        isPublic: _isPublic,
        createdAt: now,
      );

      await repo.createChallenge(challenge);

      // Auto-join creator
      final participant = ChallengeParticipant(
        challengeId: id,
        userId: userId,
        username: user?.username ?? '',
        profilePictureUrl: user?.profilePictureUrl,
      );
      await repo.joinChallenge(participant);

      ref.invalidate(publicChallengesProvider);
      ref.invalidate(myChallengesProvider);

      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
            // ─── Title ─────────────────────────────────────────────────
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
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: palette.border, width: 0.5),
              ),
            ),

            const SizedBox(height: 20),

            // ─── Description ───────────────────────────────────────────
            _label(palette, 'Description'),
            const SizedBox(height: 6),
            CupertinoTextField(
              controller: _descController,
              placeholder: 'Optional description',
              maxLength: 300,
              maxLines: 3,
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
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: palette.border, width: 0.5),
              ),
            ),

            const SizedBox(height: 20),

            // ─── Type ──────────────────────────────────────────────────
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
                        horizontal: 10,
                        vertical: 6,
                      ),
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

            // ─── Target ────────────────────────────────────────────────
            _label(palette, 'Target ($_targetUnit)'),
            const SizedBox(height: 6),
            CupertinoTextField(
              controller: _targetController,
              placeholder: 'e.g. 30',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
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
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: palette.border, width: 0.5),
              ),
            ),

            const SizedBox(height: 20),

            // ─── Duration ──────────────────────────────────────────────
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
                        horizontal: 6,
                        vertical: 6,
                      ),
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

            // ─── Public toggle ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: palette.border, width: 0.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Public challenge',
                      style: TextStyle(
                        fontFamily: 'LeagueSpartan',
                        fontSize: 15,
                        color: palette.text,
                      ),
                    ),
                  ),
                  CupertinoSwitch(
                    value: _isPublic,
                    activeTrackColor: palette.accent,
                    onChanged: (v) => setState(() => _isPublic = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ─── Create button ─────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 14),
                color: palette.accent,
                borderRadius: BorderRadius.circular(12),
                onPressed: _isSaving ? null : _create,
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
}
