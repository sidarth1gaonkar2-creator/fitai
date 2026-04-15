---
name: Isar Schema Notes
description: All Isar collections, relationship patterns, and transaction conventions (updated April 2026)
type: reference
---

## Collections (registered in IsarService.initialize())

### User & Onboarding
- `UserProfile` — singleton profile with tdee, goal, activityLevel
- `OnboardingProgress` — tracks which onboarding steps completed

### Workouts
- `Workout` → IsarLinks<WorkoutExercise> (exercises)
- `WorkoutExercise` → IsarLinks<WorkoutSet> (sets)
- `WorkoutSet` — reps, weight, isCompleted, order
- `PersonalRecord` — exerciseName, weightKg, bestReps, dateAchieved, muscleGroup

### Nutrition
- `NutritionLog` → IsarLinks<Meal> (meals); has date index
- `Meal` → IsarLinks<FoodEntry> (foodEntries); has type (MealType)
- `FoodEntry` — 12 nullable micronutrient fields; @Backlink to Meal
- `CompletedDay` — unique index on `date` (midnight-normalised DateTime)

### Meal Plans
- `CustomMealPlan` → IsarLinks<CustomMealPlanMeal> (meals); name, goal, macro totals
- `CustomMealPlanMeal` → IsarLinks<CustomMealPlanFood> (foods); mealType
- `CustomMealPlanFood` — name, calories, protein, carbs, fat, servingSize, servingUnit

### Supplements
- `Supplement` — name, dosage, unit, timing (SupplementTiming), isActive
- `SupplementLog` — supplementId (indexed), date (indexed), timeTaken, taken (bool)

### AI & Tracking
- `AIMessage` — chat messages for AI coach
- `WeightEntry` — body weight over time

## Total: 17 collections

## Relationship Patterns
- All link loading is explicit: `await obj.links.load()` before iterating
- Link saves are explicit: `await obj.links.save()` after `.add()`
- Links are bi-directional for FoodEntry ↔ Meal via `@Backlink(to: 'foodEntries')`
- SupplementLog → Supplement is via supplementId (int FK), NOT IsarLinks

## Collection Name Quirk
Isar pluralises `FoodEntry` as `isar.foodEntrys` (not `foodEntries`). This is an Isar v3 pluralisation behaviour — not a typo.

## Transaction Conventions
- All writes wrapped in `isar.writeTxn(() async { ... })`
- Reads outside transactions use `isar.collection.where().findFirst()` or `.findAll()`
- Totals on NutritionLog are recalculated inline after each add/delete (not incremental)
- `completeDay`/`uncompleteDay` are free functions in `nutrition_providers.dart`, not methods on a notifier — they take WidgetRef as a parameter
