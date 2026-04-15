---
name: BMR calculator — verified correct + TDEEBreakdown added
description: Mifflin-St Jeor constants verified correct; TDEEBreakdown value class added for summary step
type: project
---

## Current code (lib/core/utils/tdee_calculator.dart)

BMR constants ARE correct for standard Mifflin-St Jeor:
- Male: 10W + 6.25H - 5A + 5
- Female: 10W + 6.25H - 5A - 161

## TDEEBreakdown (implemented)
A `TDEEBreakdown` value class has been added with:
- baseValue, sexConstant, bmr, activityMultiplier, tdee, goalAdjustedTarget, calorieAdjustment

`calculateTDEEBreakdown()` function returns the full breakdown.

Goal calorie adjustments:
- loseFat: -500 kcal
- buildMuscle: +250 kcal
- maintain: 0

**How to apply:** Use `calculateTDEEBreakdown()` when you need intermediate values (e.g., summary step display). Use `calculateBMR()` + `calculateTDEE()` for simple final values.
