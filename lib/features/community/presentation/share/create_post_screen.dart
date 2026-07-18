import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/field_manual.dart';
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
    // Rebuild on caption edits so Share enables/disables live (a caption alone
    // is now postable).
    _captionController.addListener(_onCaptionChanged);
  }

  void _onCaptionChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _captionController.removeListener(_onCaptionChanged);
    _captionController.dispose();
    super.dispose();
  }

  /// Postable when there's something to post and we're not mid-send: a non-empty
  /// caption OR a selected workout. Empty + no workout stays disabled.
  bool get _canShare =>
      !_isSharing &&
      (_captionController.text.trim().isNotEmpty || _selectedWorkoutId != null);

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

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final caption = _captionController.text.trim();
    final workoutId = _selectedWorkoutId;
    // Need at least a caption or a workout. The Share button already enforces
    // this; guard anyway so an empty post can never be created.
    if (caption.isEmpty && workoutId == null) return;

    setState(() => _isSharing = true);

    try {
      final firestoreUser = ref.read(firestoreUserProvider).valueOrNull;

      // Embed the author's current rank so the feed badge needs no user-doc
      // lookup. Prefer the live computed rank; fall back to the mirrored value.
      // Applies to caption-only posts too, so text posts still show a badge.
      int? rankIndex = firestoreUser?.rankIndex;
      String? rankName = firestoreUser?.rankName;
      try {
        final rank = await ref.read(overallRankProvider.future);
        rankIndex = rank.index;
        rankName = rank.displayName;
      } catch (_) {}

      final Post post;
      if (workoutId != null) {
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
        post = Post(
          postId: _uuid.v4(),
          userId: userId,
          username: firestoreUser?.username ?? 'User',
          userProfilePic: firestoreUser?.profilePictureUrl,
          workoutName: workout.title,
          duration: workout.durationMinutes ?? 0,
          exercises: postExercises,
          totalSets: totalSets,
          totalVolume: totalVolume,
          caption: caption,
          isPublic: _isPublic,
          createdAt: DateTime.now(),
          workoutId: workoutId,
          rankIndex: rankIndex,
          rankName: rankName,
        );
      } else {
        // Caption-only standalone post — no workout attachment.
        post = Post(
          postId: _uuid.v4(),
          userId: userId,
          username: firestoreUser?.username ?? 'User',
          userProfilePic: firestoreUser?.profilePictureUrl,
          caption: caption,
          isPublic: _isPublic,
          createdAt: DateTime.now(),
          rankIndex: rankIndex,
          rankName: rankName,
        );
      }

      await ref.read(postRepositoryProvider).createPost(post);
      AppLogger.log('Post created (hasWorkout=${workoutId != null})');

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
        // Field Manual chrome: ink ground over a hairline (DESIGN.md §Nav).
        backgroundColor: palette.background.withValues(alpha: 0.82),
        border: Border(bottom: BorderSide(color: palette.border)),
        middle:
            Text('NEW POST', style: FieldManual.title(color: palette.text)),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _canShare ? _share : null,
          child: _isSharing
              ? const CupertinoActivityIndicator()
              : Text(
                  // Command action — condensed uppercase (visual only).
                  'SHARE',
                  semanticsLabel: 'Share',
                  style: FieldManual.title(
                    color: _canShare ? palette.accent : palette.textSecondary,
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

            // Caption — FM input: raised field fill, hairline border, 8px
            // corners (DESIGN.md §Inputs). What the user types is Inter body.
            CupertinoTextField(
              controller: _captionController,
              placeholder: 'Share progress, ask a question, or introduce '
                  'yourself…',
              maxLength: 500,
              maxLines: 4,
              style: FieldManual.body(fontSize: 15, color: palette.text),
              placeholderStyle: FieldManual.body(
                fontSize: 15,
                color: palette.textSecondary,
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: palette.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
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
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: palette.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Public',
                    style: FieldManual.body(
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

            // Attach Workout section (optional — a caption alone is postable).
            // Section label — mono eyebrow designation.
            Text(
              'ATTACH A WORKOUT (OPTIONAL)',
              style: FieldManual.label(
                fontSize: 12,
                color: palette.textSecondary,
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
                  style: FieldManual.body(
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
                      'No workouts to attach yet — your caption alone will post.',
                      textAlign: TextAlign.center,
                      style: FieldManual.body(
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

    return Semantics(
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          // Selection shifts the hairline to the live accent over a raised
          // field ground \u2014 no glow (DESIGN.md \u00a7Inputs).
          decoration: BoxDecoration(
            color: isSelected ? palette.surfaceElevated : palette.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? palette.accent : palette.border,
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
                    // Workout title is user content \u2014 Inter, never uppercased.
                    Text(
                      workout.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FieldManual.body(
                        fontSize: 14,
                        color: palette.text,
                      ).copyWith(
                        fontWeight: FontWeight.w600,
                        fontVariations: const [FontVariation('wght', 600)],
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Meta row \u2014 mono readout.
                    Text(
                      _formatDate(workout.date) +
                          (exerciseCount > 0
                              ? ' \u00b7 $exerciseCount exercises'
                              : ''),
                      style: FieldManual.label(
                        fontSize: 11,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: busy ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          // Accent-tinted command card: the one loud action on this screen.
          decoration: BoxDecoration(
            color: palette.accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: palette.accent.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: palette.accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(4),
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
                    // Command heading — condensed uppercase (visual only).
                    Text(
                      'SHARE LAST WORKOUT',
                      semanticsLabel: 'Share last workout',
                      style: FieldManual.title(color: palette.text),
                    ),
                    const SizedBox(height: 2),
                    // Contains the user's workout title — Inter, sentence case.
                    Text(
                      'One tap · $workoutTitle · with your rank badge',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FieldManual.body(
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
      ),
    );
  }
}

