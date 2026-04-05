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
import '../../models/weight_entry.dart';

class IsarService {
  static Future<Isar> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    return Isar.open(
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
      ],
      directory: dir.path,
    );
  }
}
