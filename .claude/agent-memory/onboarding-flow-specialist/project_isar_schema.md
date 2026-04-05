---
name: Isar schema and service
description: Existing Isar models, IsarService registration, and what is missing for onboarding persistence
type: project
---

## IsarService (lib/core/database/isar_service.dart)
Opens Isar with these schemas registered:
UserProfileSchema, WorkoutSchema, WorkoutExerciseSchema, WorkoutSetSchema,
NutritionLogSchema, MealSchema, FoodEntrySchema, AIMessageSchema, WeightEntrySchema

## Key constraint
isar_generator is pinned at ^3.1.0+1 — conflicts with modern build_runner/riverpod_generator.
All Riverpod providers must be written manually. All new Isar models must use @collection and generate .g.dart via `dart run build_runner build`.

## Missing for onboarding persistence
No `OnboardingProgress` collection exists. To support partial progress persistence, a new model is needed:

Proposed fields:
- Id id = Isar.autoIncrement
- String? name
- int? age
- String? sex  (store as String, not enum, to avoid @enumerated migration risk)
- double? weightKg
- double? heightCm
- String? goal (String)
- String? activityLevel (String)
- int lastCompletedStep = 0
- bool isComplete = false
- DateTime updatedAt

After adding: must register OnboardingProgressSchema in IsarService.initialize() and run build_runner.

**Why:** Audit on 2026-04-05 confirmed no OnboardingProgress model and no draft-save logic.
**How to apply:** When implementing partial persistence, follow this proposed schema exactly rather than redesigning from scratch.
