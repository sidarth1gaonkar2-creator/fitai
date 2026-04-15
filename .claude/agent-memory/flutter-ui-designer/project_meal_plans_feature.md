---
name: Custom Meal Plans Feature
description: Create, browse, preview, and import custom meal plans into daily nutrition — Isar-backed with 3 linked models
type: project
---

## Isar Models (lib/models/)

**CustomMealPlan** — name, goal, createdAt, totalCalories, totalProtein, totalCarbs, totalFat
- IsarLinks<CustomMealPlanMeal> meals

**CustomMealPlanMeal** — mealType (MealType enum)
- IsarLinks<CustomMealPlanFood> foods

**CustomMealPlanFood** — name, calories, protein, carbs, fat, servingSize, servingUnit

Schemas registered in IsarService: CustomMealPlanSchema, CustomMealPlanMealSchema, CustomMealPlanFoodSchema

## Providers (lib/providers/custom_meal_plan_providers.dart)

- `allCustomMealPlansProvider` — All meal plans from Isar
- `saveCustomMealPlan()` — Save plan with linked meals and foods
- `deleteCustomMealPlan()` — Delete plan and all linked data
- `importCustomMealPlan()` — Import plan's foods into today's NutritionLog meals
- `PlanFood` DTO for plan creation

## Screens (lib/features/nutrition/presentation/)

- **MealPlansScreen** — Browse saved meal plans
- **CreateMealPlanScreen** — Form to build a custom plan with meals and foods
- **MealPlanPreviewScreen** — Preview plan details before importing

## Integration
- Accessible from NutritionScreen's "Meal Plans" tab
- Import copies plan foods into today's actual meals in the NutritionLog
