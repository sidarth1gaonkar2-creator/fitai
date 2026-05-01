import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/community_providers.dart';
import '../../data/post_repository.dart';
import '../../domain/post.dart';

class ShareWorkoutSheet extends ConsumerStatefulWidget {
  const ShareWorkoutSheet({
    super.key,
    required this.workoutName,
    required this.duration,
    required this.exercises,
    required this.totalSets,
    required this.totalVolume,
  });

  final String workoutName;
  final int duration;

  /// Each map contains: name (String), sets (int), bestWeight (double).
  final List<Map<String, dynamic>> exercises;
  final int totalSets;
  final double totalVolume;

  @override
  ConsumerState<ShareWorkoutSheet> createState() => _ShareWorkoutSheetState();
}

class _ShareWorkoutSheetState extends ConsumerState<ShareWorkoutSheet> {
  final _captionController = TextEditingController();
  bool _isPublic = true;
  bool _isSharing = false;
  static const _uuid = Uuid();

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    if (_isSharing) return;

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final firestoreUser = ref.read(firestoreUserProvider).valueOrNull;

    setState(() => _isSharing = true);

    try {
      final postExercises = widget.exercises
          .map((e) => PostExercise(
                name: e['name'] as String? ?? '',
                sets: (e['sets'] as num?)?.toInt() ?? 0,
                bestWeight: (e['bestWeight'] as num?)?.toDouble() ?? 0,
              ))
          .toList();

      final post = Post(
        postId: _uuid.v4(),
        userId: userId,
        username: firestoreUser?.username ?? 'User',
        userProfilePic: firestoreUser?.profilePictureUrl,
        workoutName: widget.workoutName,
        duration: widget.duration,
        exercises: postExercises,
        totalSets: widget.totalSets,
        totalVolume: widget.totalVolume,
        caption: _captionController.text.trim(),
        isPublic: _isPublic,
        createdAt: DateTime.now(),
      );

      await ref.read(postRepositoryProvider).createPost(post);

      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: palette.textSecondary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 16),
              // Title
              Text(
                'Share Workout',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: palette.text,
                ),
              ),
              const SizedBox(height: 16),
              // Workout summary
              _buildSummaryCard(palette),
              const SizedBox(height: 16),
              // Caption
              CupertinoTextField(
                controller: _captionController,
                placeholder: 'Add a caption...',
                placeholderStyle: TextStyle(
                  fontFamily: 'LeagueSpartan',
                  fontSize: 14,
                  color: palette.textSecondary,
                ),
                style: TextStyle(
                  fontFamily: 'LeagueSpartan',
                  fontSize: 14,
                  color: palette.text,
                ),
                decoration: BoxDecoration(
                  color: palette.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.border),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                maxLength: 500,
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              // Public toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Public',
                    style: TextStyle(
                      fontFamily: 'LeagueSpartan',
                      fontSize: 15,
                      color: palette.text,
                    ),
                  ),
                  CupertinoSwitch(
                    value: _isPublic,
                    activeTrackColor: palette.accent,
                    onChanged: (v) => setState(() => _isPublic = v),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: palette.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      color: palette.accent,
                      borderRadius: BorderRadius.circular(12),
                      onPressed: _isSharing ? null : _share,
                      child: _isSharing
                          ? const CupertinoActivityIndicator(
                              color: CupertinoColors.white,
                            )
                          : const Text(
                              'Share',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: CupertinoColors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(Palette palette) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.workoutName,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: palette.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${widget.exercises.length} exercises \u00b7 ${widget.totalSets} sets \u00b7 ${widget.duration}min',
            style: TextStyle(
              fontFamily: 'LeagueSpartan',
              fontSize: 13,
              color: palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
