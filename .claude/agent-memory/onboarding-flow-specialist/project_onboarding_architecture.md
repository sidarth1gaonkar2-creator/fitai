---
name: Onboarding architecture snapshot
description: File layout, step order, controller pattern, Riverpod wiring, and key gaps found in first audit (April 2026)
type: project
---

## File layout (actual, differs from spec)

The onboarding feature lives at `lib/features/onboarding/` with this structure (NOT the flat spec layout):

```
lib/features/onboarding/
├── domain/
│   └── onboarding_state.dart           # OnboardingState value class
└── presentation/
    ├── onboarding_controller.dart       # StateNotifier + provider
    ├── onboarding_screen.dart           # PageView host
    └── widgets/
        ├── name_step.dart
        ├── body_info_step.dart          # Age + Sex (SegmentedButton, NOT large cards)
        ├── measurements_step.dart       # Weight + Height (no unit toggle yet)
        ├── goal_step.dart               # Goal cards — cards exist but no disabled-Next state
        ├── activity_step.dart           # Activity — uses ListTile, NOT cards; needs upgrade
        └── summary_step.dart            # Shows TDEE but no breakdown
```

Support files used by onboarding:
- `lib/core/utils/tdee_calculator.dart` — calculateBMR / calculateTDEE
- `lib/core/utils/validators.dart` — validateRequired, validateAge, validatePositiveNumber
- `lib/models/enums.dart` — Sex, Goal, ActivityLevel (with multiplier extension)
- `lib/models/user_profile.dart` — final save target (Isar @collection)
- `lib/providers/isar_provider.dart` — isarProvider (throw stub; overridden in main)
- `lib/providers/user_profile_provider.dart` — FutureProvider, used for router redirect
- `lib/core/constants/app_constants.dart` — onboardingStepCount = 6
- `lib/routing/app_router.dart` — redirect: no profile → /onboarding

## Step order (PageView index)
0 = NameStep, 1 = BodyInfoStep, 2 = MeasurementsStep, 3 = GoalStep, 4 = ActivityStep, 5 = SummaryStep

## Controller pattern
- `OnboardingController extends StateNotifier<OnboardingState>` — manual, no codegen
- Provider: `StateNotifierProvider<OnboardingController, OnboardingState>`
- Ref stored on controller as `_ref` — used to read isarProvider and invalidate userProfileProvider
- `calculateAndSave()` writes a full UserProfile to Isar, then invalidates userProfileProvider (triggers router redirect)

## Key gaps found in first audit
1. PageView transition uses `animateToPage` with 300ms/easeInOut — fine, but no custom page transition builder (plain slide from PageView default)
2. BodyInfoStep uses SegmentedButton for Sex — should be large tappable cards
3. ActivityStep uses ListTile — should be Card-based to match GoalStep
4. No inline validation — all steps validate only on _submit(); Next button is never disabled
5. No partial progress persistence — onboarding state is in-memory only; app kill loses progress
6. SummaryStep recalculates BMR/TDEE locally but shows only final number — no breakdown
7. No OnboardingProgress Isar model exists
8. go_router redirect only checks for complete UserProfile — cannot resume mid-onboarding

**Why:** Recorded after first full audit of onboarding feature on 2026-04-05.
**How to apply:** Use these gaps as the checklist for the improvement plan.
