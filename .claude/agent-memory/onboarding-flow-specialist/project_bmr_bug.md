---
name: BMR calculator bug
description: Mifflin-St Jeor constants in tdee_calculator.dart are wrong — male constant should be +5 not +5, female should be -161 not -161. Actually the male path adds +5 which is correct; but the spec says male = base + 166 and female = base - 161. This needs verification.
type: project
---

## Current code (lib/core/utils/tdee_calculator.dart)

```dart
double calculateBMR({...}) {
  final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
  return switch (sex) {
    Sex.male => base + 5,       // Mifflin-St Jeor male: +5 ✓
    Sex.female => base - 161,   // Mifflin-St Jeor female: -161 ✓
  };
}
```

## Status
On close reading, the current constants ARE correct for standard Mifflin-St Jeor:
- Male: 10W + 6.25H - 5A + 5
- Female: 10W + 6.25H - 5A - 161

The system prompt spec says "male: base - 161 + 166" which simplifies to +5. So the code is correct.

## Action needed for TDEE breakdown step
The summary screen must expose the intermediate values: base value, sex constant, final BMR, activity multiplier, raw TDEE, and goal-adjusted target. The calculator should be updated to return a breakdown struct rather than just a double, or a separate `calculateBMRBreakdown()` helper should be added.

**Why:** Summary step currently only displays the final TDEE number. Breakdown plan requires surfacing BMR and multiplier.
**How to apply:** When implementing the TDEE breakdown, add a TDEEBreakdown value object (no Isar needed) returned from a new helper in tdee_calculator.dart.
