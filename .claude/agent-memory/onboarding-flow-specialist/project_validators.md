---
name: Validators — all implemented
description: All validators in validators.dart including name, weight, height range validators (updated April 2026)
type: project
---

## Current validators (lib/core/utils/validators.dart)

- `validateRequired(value, fieldName)` — non-empty check
- `validatePositiveNumber(value, fieldName)` — non-empty + double > 0
- `validateAge(value)` — range 13–120
- `validateName(value)` — non-empty + max 50 chars + no purely-numeric strings
- `validateWeight(value)` — positive + range 20–300 kg
- `validateHeight(value)` — positive + range 50–272 cm

All validators that were previously missing have been implemented.

**How to apply:** Use these validators for form validation. No unit-aware variants exist yet (weight/height are always kg/cm).
