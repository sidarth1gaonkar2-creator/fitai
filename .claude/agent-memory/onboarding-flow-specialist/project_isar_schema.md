---
name: Isar schema and service
description: Existing Isar models (17 collections), IsarService setup, schema registration (updated April 2026)
type: project
---

## IsarService (lib/core/database/isar_service.dart)
Opens Isar with these 17 schemas registered:
UserProfileSchema, WorkoutSchema, WorkoutExerciseSchema, WorkoutSetSchema,
NutritionLogSchema, MealSchema, FoodEntrySchema, AIMessageSchema, WeightEntrySchema,
OnboardingProgressSchema, CompletedDaySchema, CustomMealPlanSchema, CustomMealPlanMealSchema,
CustomMealPlanFoodSchema, PersonalRecordSchema, SupplementSchema, SupplementLogSchema

## Key constraint
isar_generator is pinned at ^3.1.0+1 — conflicts with modern build_runner/riverpod_generator.
All Riverpod providers must be written manually. All new Isar models must use @collection and generate .g.dart via `dart run build_runner build`.

## OnboardingProgress collection (exists)
- Id id = Isar.autoIncrement
- Fields for each step's data (name, age, sex, weightKg, heightCm, goal, activityLevel)
- lastCompletedStep, isComplete, updatedAt

**How to apply:** When adding new Isar collections, register the schema in IsarService.initialize() and run build_runner.
