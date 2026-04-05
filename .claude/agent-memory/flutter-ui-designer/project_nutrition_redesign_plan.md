---
name: Nutrition Redesign Plan
description: Cronometer-style nutrition screen redesign plan including micros, complete day, colour-coded macros
type: project
---

Planned as of 2026-04-05.

Key decisions:
- CompletedDay is a new Isar @collection model
- Micronutrient data must be added to FoodEntry (10 new nullable double fields)
- FoodSearchResult and open_food_facts_service.dart need micro field mapping
- MealSection gets a protein subtotal alongside existing calorie subtotal
- DailySummaryHeader is fully replaced by NutritionSummaryCard (calorie ring + macro bars)
- Micro section is a new collapsible widget: MicronutrientSection
- FoodEntryTile gains a macro inline row (already partially there, just needs visual upgrade)
- CompleteDay flow: bottom button → BottomSheet summary → write CompletedDay to Isar

**How to apply:** When implementing, touch FoodEntry model first (adds fields, requires isar codegen rerun), then providers, then UI widgets in order.
