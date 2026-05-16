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
import '../../models/weight_entry.dart';

class IsarService {
  static Future<Isar> initialize() async {
    String stage = 'getApplicationDocumentsDirectory';
    try {
      final dir = await getApplicationDocumentsDirectory();
      stage = 'Isar.open(directory=${dir.path})';
      return await Isar.open(
        [
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
        ],
        directory: dir.path,
      );
    } catch (e, st) {
      Error.throwWithStackTrace(
        StateError('IsarService.initialize failed at stage "$stage": $e'),
        st,
      );
    }
  }
}
