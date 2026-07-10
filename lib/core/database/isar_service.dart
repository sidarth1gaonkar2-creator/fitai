import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/user_profile.dart';
import '../../models/workout.dart';
import '../../models/workout_exercise.dart';
import '../../models/workout_set.dart';
import '../../models/nutrition_log.dart';
import '../../models/meal.dart';
import '../../models/food_entry.dart';
import '../../models/ai_message.dart';
import '../../models/completed_day.dart';
import '../../models/onboarding_progress.dart';
import '../../models/custom_meal_plan.dart';
import '../../models/custom_meal_plan_food.dart';
import '../../models/custom_meal_plan_meal.dart';
import '../../models/personal_record.dart';
import '../../models/saved_meal.dart';
import '../../models/saved_meal_item.dart';
import '../../models/supplement.dart';
import '../../models/supplement_log.dart';
import '../../models/cached_menu_item.dart';
import '../../models/user_rank.dart';
import '../../models/user_theme_state.dart';
import '../../models/weight_entry.dart';
import '../../models/saved_workout_template.dart';

/// Opens the per-account Isar instances (uid-scoping batch, see
/// docs/uid-scoping-audit.md §2b).
///
/// Each Firebase account gets its OWN named Isar instance — `u_<uid>.isar` —
/// so device-local data is isolated per account structurally: none of the
/// ~200 query sites can leak across accounts because they only ever see the
/// active account's database. Signed-out sessions use a scratch `anon`
/// instance. The active instance is published via `activeIsarProvider`
/// (isar_provider.dart); consumers keep reading `isarProvider` unchanged.
class IsarService {
  /// Instance name for signed-out sessions. Nothing user-attributable is
  /// written pre-auth (onboarding runs post-sign-in), so this is a scratch DB.
  static const String anonInstanceName = 'anon';

  /// All collection schemas — shared by every instance (and by the row-copy
  /// path of the legacy uid migration).
  static const List<CollectionSchema<dynamic>> schemas = [
    UserProfileSchema,
    WorkoutSchema,
    WorkoutExerciseSchema,
    WorkoutSetSchema,
    NutritionLogSchema,
    MealSchema,
    FoodEntrySchema,
    AIMessageSchema,
    WeightEntrySchema,
    OnboardingProgressSchema,
    CompletedDaySchema,
    CustomMealPlanSchema,
    CustomMealPlanMealSchema,
    CustomMealPlanFoodSchema,
    PersonalRecordSchema,
    SavedMealSchema,
    SavedMealItemSchema,
    SupplementSchema,
    SupplementLogSchema,
    UserThemeStateSchema,
    CachedMenuItemSchema,
    UserRankSchema,
    SavedWorkoutTemplateSchema,
  ];

  /// Canonical instance name for an account (or the anon scratch instance
  /// when signed out). Firebase uids are URL-safe alphanumerics, so they are
  /// valid in file names (the instance name IS the file name — see
  /// [databaseDirectory]).
  static String instanceNameForUid(String? uid) =>
      uid == null ? anonInstanceName : 'u_$uid';

  /// Directory holding every instance's `<name>.isar` file. Exposed so the
  /// legacy uid migration can operate on the files before the first open.
  static Future<String> databaseDirectory() async =>
      (await getApplicationDocumentsDirectory()).path;

  /// Opens (or reuses) the instance for [uid] — `u_<uid>`, or `anon` when
  /// signed out.
  static Future<Isar> openForUid(String? uid) =>
      openByName(instanceNameForUid(uid));

  /// Opens the named instance, reusing an already-open handle when present
  /// (e.g. a rapid sign-out → sign-in before the session manager's deferred
  /// close ran) — `Isar.open` throws on a duplicate name otherwise.
  static Future<Isar> openByName(String name) async {
    final existing = Isar.getInstance(name);
    if (existing != null && existing.isOpen) return existing;

    String stage = 'getApplicationDocumentsDirectory';
    try {
      final dir = await getApplicationDocumentsDirectory();
      stage = 'Isar.open(name=$name, directory=${dir.path})';
      return await Isar.open(
        schemas,
        directory: dir.path,
        name: name,
      );
    } catch (e, st) {
      Error.throwWithStackTrace(
        StateError('IsarService.openByName failed at stage "$stage": $e'),
        st,
      );
    }
  }
}
