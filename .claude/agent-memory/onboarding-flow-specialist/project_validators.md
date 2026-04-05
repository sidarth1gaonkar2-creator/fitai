---
name: Validators coverage gaps
description: Current validator rules in validators.dart and what is missing for inline validation
type: project
---

## Current validators (lib/core/utils/validators.dart)
- `validateRequired(value, fieldName)` — non-empty check only, no length cap
- `validatePositiveNumber(value, fieldName)` — non-empty + double > 0, no range bounds
- `validateAge(value)` — non-empty + int, range 13–120 ✓

## Missing validators needed for inline validation improvements
1. `validateName(value)` — non-empty + max length (e.g. 50 chars) + no purely-numeric strings
2. `validateWeight(value)` — positive number + reasonable range: 20–300 kg
3. `validateHeight(value)` — positive number + reasonable range: 50–272 cm (tallest recorded human)
4. Both weight/height need unit-aware variants if unit toggle is added to MeasurementsStep

## Inline validation strategy
Current: validate only on _submit() via Form.validate().
Target: validate on every keystroke (onChanged) using a local `_errorText` state variable, with a short debounce (~500ms) to avoid spamming errors while typing.
Pattern: use a Timer in the step's state class; cancel and restart on each onChanged call; on timer fire, call the validator and setState(_errorText).
The Next/Submit FilledButton should check `_isValid` (derived from all local error states being null and all required fields non-empty).

**Why:** Audit on 2026-04-05 confirmed zero inline validation exists; all steps gate on _submit() only.
**How to apply:** When implementing inline validation, add the missing validators to validators.dart first, then update each step widget.
