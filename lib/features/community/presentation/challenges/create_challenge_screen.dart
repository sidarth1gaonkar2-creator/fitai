import 'package:flutter/cupertino.dart';
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

  int _typeIndex = 0; // 0=workout, 1=nutrition, 2=habit
  int _durationIndex = 2; // 0=7, 1=14, 2=30, 3=60 → default 30
  bool _isPublic = true;
  bool _requiresPhotoProof = false;
  bool _isSaving = false;

  static const _typeKeys = ['workout', 'nutrition', 'habit'];
  static const _typeLabels = {0: 'Workout', 1: 'Nutrition', 2: 'Habit'};
  static const _durationDays = [7, 14, 30, 60];
  static const _durationLabels = {
    0: '7 days',
    1: '14 days',
    2: '30 days',
    3: '60 days',
  };

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
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
        durationDays: duration,
        startDate: now,
        endDate: endDate,
        participantCount: 1,
        isPublic: _isPublic,
        requiresPhotoProof: _requiresPhotoProof,
        createdAt: now,
      );

      await repo.createChallenge(challenge);

      // Auto-join creator.
      final participant = ChallengeParticipant(
        challengeId: id,
        userId: userId,
        username: user?.username ?? '',
        profilePictureUrl: user?.profilePictureUrl,
        joinedAt: now,
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
