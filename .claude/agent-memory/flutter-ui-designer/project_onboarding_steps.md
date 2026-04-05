---
name: Onboarding Step Map
description: All 6 onboarding steps — what they collect and their current visual state
type: project
---

File: lib/features/onboarding/presentation/onboarding_screen.dart
Navigation: PageView with NeverScrollableScrollPhysics, LinearProgressIndicator header.
Step count: 6 (AppConstants.onboardingStepCount)

Steps (in order):
0. NameStep — collects name via TextFormField. Layout: headline + subtitle + field + Spacer + FilledButton. NO illustration.
1. BodyInfoStep — collects age (TextFormField) + sex (SegmentedButton). NO illustration.
2. MeasurementsStep — collects weight (kg) + height (cm). NO illustration.
3. GoalStep — selects Goal enum (loseFat/buildMuscle/maintain) via _GoalCard list. Each card already has a small Icon (fire/dumbbell/balance). NO hero illustration above headline.
4. ActivityStep — selects ActivityLevel enum via ListTile list. NO illustration.
5. SummaryStep — read-only summary Card + TDEE display. NO illustration.

All steps share the same sparse layout: 32dp top spacing, headlineMedium title, bodyLarge subtitle, 32dp gap, content, Spacer, FilledButton. There is significant empty vertical space above the headline on all steps.
