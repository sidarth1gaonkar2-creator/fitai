---
name: Isar Schema Notes
description: Isar collection names, relationship patterns, and transaction conventions
type: reference
---

## Collections (registered in IsarService.initialize())
- `UserProfile` — singleton profile with tdee, goal, activityLevel
- `Workout` → IsarLinks<WorkoutExercise> (exercises)
- `WorkoutExercise` → IsarLinks<WorkoutSet> (sets)
- `WorkoutSet` — reps, weight, isCompleted, order
- `NutritionLog` → IsarLinks<Meal> (meals); has date index
- `Meal` → IsarLinks<FoodEntry> (foodEntries); has type (MealType)
- `FoodEntry` — 12 nullable micronutrient fields added in this phase; @Backlink to Meal
- `AIMessage` — chat messages for AI coach
- `WeightEntry` — body weight over time
- `OnboardingProgress` — tracks which onboarding steps completed
- `CompletedDay` — new in this phase; unique index on `date` (midnight-normalised DateTime)

## Relationship Patterns
- All link loading is explicit: `await obj.links.load()` before iterating.
- Link saves are explicit: `await obj.links.save()` after `.add()`.
- Links are bi-directional for FoodEntry ↔ Meal via `@Backlink(to: 'foodEntries')`.

## Collection Name Quirk
Isar pluralises `FoodEntry` as `isar.foodEntrys` (not `foodEntries`). This is an Isar v3
pluralisation behaviour — not a typo.

## Transaction Conventions
- All writes wrapped in `isar.writeTxn(() async { ... })`.
- Reads outside transactions use `isar.collection.where().findFirst()` or `.findAll()`.
- Totals on `NutritionLog` are recalculated inline after each add/delete (not incremental).
- `completeDay`/`uncompleteDay` are free functions in `nutrition_providers.dart`, not methods
  on a notifier — they take `WidgetRef` as a parameter.
