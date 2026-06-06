import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/logger.dart';
import '../../../../models/workout.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/community_providers.dart';
import '../../../../providers/workout_providers.dart';
import '../../../ranks/domain/military_ranks.dart';
import '../../../ranks/providers/rank_providers.dart';
import '../../data/post_repository.dart';
import '../../domain/post.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key, this.initialWorkoutId});

  final int? initialWorkoutId;

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _captionController = TextEditingController();
  bool _isPublic = true;
  bool _isSharing = false;
  int? _selectedWorkoutId;
  static const _uuid = Uuid();

  @override
  void initState() {
    super.initState();
    _selectedWorkoutId = widget.initialWorkoutId;
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  /// "Workout Share" template — one tap shares the most recent workout (with
  /// its stats; the rank badge is attached automatically on the post card).
  Future<void> _shareLastWorkout(int workoutId) async {
    if (_isSharing) return;
    HapticFeedback.mediumImpact();
    setState(() => _selectedWorkoutId = workoutId);
    await _share();
  }

  Future<void> _share() async {
    if (_isSharing) return;
    final workoutId = _selectedWorkoutId;
    if (workoutId == null) return;

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    setState(() => _isSharing = true);

    try {
      final workout =
          await ref.read(workoutByIdProvider(workoutId).future);
      if (workout == null) {
        throw StateError('Workout not found');
      }
      await workout.exercises.load();
      final postExercises = <PostExercise>[];
      int totalSets = 0;
      double totalVolume = 0;
      for (final ex in workout.exercises) {
        await ex.sets.load();
        double bestWeight = 0;
        for (final s in ex.sets) {
          totalSets += 1;
          totalVolume += s.weight * s.reps;
          if (s.weight > bestWeight) bestWeight = s.weight;
        }
        postExercises.add(PostExercise(
          name: ex.name,
          sets: ex.sets.length,
          bestWeight: bestWeight,
        ));
      }

      final firestoreUser = ref.read(firestoreUserProvider).valueOrNull;

      // Embed the author's current rank so the feed badge needs no user-doc
      // lookup. Prefer the live computed rank; fall back to the mirrored value.
      int? rankIndex = firestoreUser?.rankIndex;
      String? rankName = firestoreUser?.rankName;
      try {
        final rank = await ref.read(overallRankProvider.future);
        rankIndex = rank.index;
        rankName = rank.displayName;
      } catch (_) {}

      final post = Post(
        postId: _uuid.v4(),
        userId: userId,
        username: firestoreUser?.username ?? 'User',
        userProfilePic: firestoreUser?.profilePictureUrl,
        workoutName: workout.title,
        duration: workout.durationMinutes ?? 0,
        exercises: postExercises,
        totalSets: totalSets,
        totalVolume: totalVolume,
        caption: _captionController.text.trim(),
        isPublic: _isPublic,
        createdAt: DateTime.now(),
        workoutId: workoutId,
        rankIndex: rankIndex,
        rankName: rankName,
      );

      await ref.read(postRepositoryProvider).createPost(post);
      AppLogger.log('Post created (workout="${workout.title}")');

      if (mounted) Navigator.of(context).pop(true);
    } catch (e, st) {
      AppLogger.error('Post create failed', error: e, stack: st);
      if (mounted) {
        setState(() => _isSharing = false);
        showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: const Text('Could not share'),
            content: Text('$e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final workoutsAsync = ref.watch(allWorkoutsProvider);

    return CupertinoPageScaffold(
      backgroundColor: palette.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: palette.surface,
        border: Border(bottom: BorderSide(color: palette.border)),
        middle: Text(
          'New Post',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: palette.text,
          ),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed:
              (_selectedWorkoutId == null || _isSharing) ? null : _share,
          child: _isSharing
              ? const CupertinoActivityIndicator()
              : Text(
                  'Share',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    color: _selectedWorkoutId == null
                        ? palette.textSecondary
                        : palette.accent,
                  ),
                ),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Quick "Workout Share" template — one tap posts the last workout.
            workoutsAsync.maybeWhen(
              data: (all) => all.isEmpty
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _QuickShareTemplate(
                        palette: palette,
                        workoutTitle: all.first.title,
                        busy: _isSharing,
                        onTap: () => _shareLastWorkout(all.first.id),
                      ),
                    ),
              orElse: () => const SizedBox.shrink(),
            ),

            // Caption
            CupertinoTextField(
              controller: _captionController,
              placeholder: 'Add a caption...',
              maxLength: 500,
              maxLines: 4,
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
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: palette.border),
              ),
            ),
            const SizedBox(height: 20),

            // Public toggle
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: palette.border),
              ),
              child: Row(
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
            ),
            const SizedBox(height: 20),

            // Attach Workout section
            Text(
              'Attach Workout',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 8),
            workoutsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CupertinoActivityIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Could not load workouts: $e',
                  style: TextStyle(
                    fontFamily: 'LeagueSpartan',
                    fontSize: 13,
                    color: palette.destructive,
                  ),
                ),
              ),
              data: (all) {
                if (all.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No workouts yet. Finish a workout first, then share it here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'LeagueSpartan',
                        fontSize: 14,
                        color: palette.textSecondary,
                      ),
                    ),
                  );
                }
                final recent = all.take(10).toList();
                return Column(
                  children: recent
                      .map((w) => _WorkoutTile(
                            workout: w,
                            isSelected: _selectedWorkoutId == w.id,
                            onTap: () =>
                                setState(() => _selectedWorkoutId = w.id),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutTile extends ConsumerWidget {
  const _WorkoutTile({
    required this.workout,
    required this.isSelected,
    required this.onTap,
  });

  final Workout workout;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    // Load exercises lazily; on first build the list will be empty and we'll
    // show just the name/date, which is fine for the picker.
    final exerciseCount = workout.exercises.length;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? palette.accent.withValues(alpha: 0.12)
              : palette.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? palette.accent : palette.border,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? CupertinoIcons.checkmark_circle_fill
                  : CupertinoIcons.circle,
              color: isSelected ? palette.accent : palette.textSecondary,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workout.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: palette.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(workout.date) +
                        (exerciseCount > 0
                            ? ' \u00b7 $exerciseCount exercises'
                            : ''),
                    style: TextStyle(
                      fontFamily: 'LeagueSpartan',
                      fontSize: 12,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final now = DateTime.now();
    final sameYear = d.year == now.year;
    return sameYear
        ? '${months[d.month - 1]} ${d.day}'
        : '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

/// One-tap "Workout Share" template card. Posts the user's most recent workout
/// with its stats; the rank badge is attached automatically by the post card.
class _QuickShareTemplate extends StatelessWidget {
  const _QuickShareTemplate({
    required this.palette,
    required this.workoutTitle,
    required this.busy,
    required this.onTap,
  });

  final Palette palette;
  final String workoutTitle;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: busy ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.accent.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.accent.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: palette.accent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(CupertinoIcons.bolt_fill,
                  size: 20, color: palette.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Share last workout',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: palette.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'One tap · $workoutTitle · with your rank badge',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'LeagueSpartan',
                      fontSize: 12.5,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            busy
                ? const CupertinoActivityIndicator()
                : Icon(CupertinoIcons.arrow_right_circle_fill,
                    size: 26, color: palette.accent),
          ],
        ),
      ),
    );
  }
}

