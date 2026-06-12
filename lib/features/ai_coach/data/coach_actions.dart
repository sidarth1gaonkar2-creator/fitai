import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../../core/utils/logger.dart';
import '../../../models/saved_workout_template.dart';
import '../../../models/user_profile.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/isar_provider.dart';
import '../../../providers/user_profile_provider.dart';
import '../../onboarding/data/remote_profile_repository.dart';

/// Applies an AI Coach nutrition-goal proposal: writes the four targets as
/// overrides on the single UserProfile (atomically), syncs them to the private
/// Firestore profile doc so they survive new devices, and refreshes the
/// goal-dependent providers (dailyTargetsProvider cascades off userProfile).
Future<void> applyNutritionGoals(
  Ref ref, {
  required double calories,
  required double proteinG,
  required double carbsG,
  required double fatG,
}) async {
  final isar = ref.read(isarProvider);
  final profile = await isar.userProfiles.where().anyId().build().findFirst();
  if (profile == null) {
    throw StateError('No profile to update');
  }
  profile
    ..calorieGoal = calories
    ..proteinGoalG = proteinG
    ..carbsGoalG = carbsG
    ..fatGoalG = fatG;
  await isar.writeTxn(() async {
    await isar.userProfiles.put(profile);
  });
  ref.invalidate(userProfileProvider);

  // Sync overrides to the private Firestore doc (best-effort).
  final uid = ref.read(currentUserIdProvider);
  if (uid != null) {
    try {
      await ref
          .read(remoteProfileRepositoryProvider)
          .save(uid, RemoteProfile.fromLocal(profile));
    } catch (e, st) {
      AppLogger.error('applyNutritionGoals: remote sync failed',
          error: e, stack: st);
    }
  }
}

/// All Coach-saved workout templates for the current user, newest first.
/// uid-scoped — rebuilds on auth change so templates never leak across accounts.
final savedWorkoutTemplatesProvider =
    FutureProvider<List<SavedWorkoutTemplate>>((ref) async {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return const [];
  final isar = ref.watch(isarProvider);
  return isar.savedWorkoutTemplates
      .filter()
      .uidEqualTo(uid)
      .sortByCreatedAtDesc()
      .findAll();
});

/// Persists an applied AI workout proposal as a startable template. Returns the
/// new template id, or null when signed out.
Future<int?> saveCoachWorkoutTemplate(
  Ref ref, {
  required String name,
  required String focus,
  required String exercisesJson,
}) async {
  final uid = ref.read(currentUserIdProvider);
  if (uid == null) return null;
  final isar = ref.read(isarProvider);
  final template = SavedWorkoutTemplate()
    ..uid = uid
    ..name = name
    ..focus = focus
    ..exercisesJson = exercisesJson
    ..source = 'coach';
  await isar.writeTxn(() async {
    await isar.savedWorkoutTemplates.put(template);
  });
  ref.invalidate(savedWorkoutTemplatesProvider);
  return template.id;
}

/// Deletes a Coach-saved template (built-ins are not deletable). Takes a
/// [WidgetRef] — it's invoked from the Templates tab UI.
Future<void> deleteCoachWorkoutTemplate(WidgetRef ref, int id) async {
  final isar = ref.read(isarProvider);
  await isar.writeTxn(() async {
    await isar.savedWorkoutTemplates.delete(id);
  });
  ref.invalidate(savedWorkoutTemplatesProvider);
}
