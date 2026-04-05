---
name: UI Design System Overhaul Plan
description: Dark-first purple/lime design system — token file, fonts, shell + onboarding overhaul status, plus remaining per-screen plans
type: project
---

## Completed — Phase 1 (Shell + Onboarding)

All files below have been rewritten to match the Figma dark-mode design kit:

- `lib/core/theme/app_colors.dart` — all tokens as `AppColors` constants (purple, lime, purpleDark, purpleLight, darkBackground, darkSurface, darkSurfaceBorder, bottomNavBar, etc.)
- `lib/core/theme/app_theme.dart` — full rewrite: Poppins headings, League Spartan body
- `lib/features/shell/presentation/shell_screen.dart` — custom purple bottom nav with lime active dot + AnimatedScale icon + GestureDetector haptics
- `lib/features/onboarding/presentation/onboarding_screen.dart` — purple AppBar, dot-pill progress indicator (AnimatedContainer)
- `lib/features/onboarding/presentation/widgets/selectable_card.dart` — darkSurface default, lime selected state, purpleDark icon container
- `lib/features/onboarding/presentation/widgets/onboarding_illustration.dart` — purpleDark circle + lime icon
- All 6 step files — Poppins Bold 28sp heading, purpleLight subtitle, `_NextButton` pattern (lime FilledButton when valid / white OutlinedButton when not)

## Key Patterns Established

- **`_NextButton`**: Private widget in each step. Lime `FilledButton` when valid, white-bordered `OutlinedButton` (disabled) when not. Shape: `RoundedRectangleBorder(radius: 12)`, height 52.
- **Bottom nav active**: white icon + AnimatedContainer lime 6×6 dot (collapses to 0 when inactive), AnimatedScale 1.1 on icon.
- **Dot progress**: AnimatedContainer pill — active dot is 20w×8h, inactive is 8×8, all on purple AppBar background.
- **SelectableCard**: AnimatedContainer bg transition, purpleDark 40×40 circle icon, black text + black checkmark on lime when selected.
- **Summary step cards**: Profile = purpleDark container; TDEE breakdown = darkSurface + darkSurfaceBorder; lime for section labels and final calorie value.

## Completed — Phase 2 (AI Coach + Settings)

- `lib/features/ai_coach/presentation/ai_coach_screen.dart` — purpleDark 80x80 coach icon circle, suggested prompt chips (colorScheme border + primary text), chips call sendMessage directly
- `lib/features/ai_coach/presentation/widgets/chat_bubble.dart` — user: AppColors.lime bg + black text; AI: darkSurface + darkSurfaceBorder border + white text
- `lib/features/ai_coach/presentation/widgets/chat_input_bar.dart` — darkSurface container, darkSearchField TextField, purple focus border on 24dp radius, purple IconButton.filled send
- `lib/features/ai_coach/presentation/widgets/typing_indicator.dart` — darkSurface + darkSurfaceBorder container, AppColors.lime dots
- `lib/features/settings/presentation/settings_screen.dart` — full-width purple profile header (purpleDark avatar, purpleLight subtitle), _SettingsCard (darkSurface + border), _SettingsIconBadge (40dp circle), lime chevron_right, error color for Reset row
- `lib/features/settings/presentation/edit_profile_screen.dart` — SegmentedButton styled (purple selected/dark unselected), RadioListTile with purple activeColor, lime FilledButton save (full-width, h=52)

## Completed — Phase 3 (Dashboard + Workouts) — 2026-04-05

- `dashboard_screen.dart` — time-aware greeting, search/bell/avatar AppBar, `_StatsRow` (steps/kcal/minutes with purpleDark 48×48 icon circles), lime `_QuickActionButton`
- `calorie_ring.dart` — purple→purpleLight (normal) / lime (≥80%) / error (≥100%) gradient ring; darkSurface track; glow layer kept
- `streak_counter.dart` — purpleDark Container (replaces Card.filled), lime fire icon, white Poppins SemiBold text
- `water_tracker.dart` — 8-dot `_GlassDotsRow` (lime filled / white-border empty); purple icon buttons; lime water_drop icon (filled)
- `today_workout_card.dart` — full-width AppColors.purple Container hero card, lime "Completed" chip, lime "Log Workout" ElevatedButton
- `macro_row.dart` — protein=AppColors.purple, carbs=AppColors.purpleLight, fat=AppColors.lime; darkSurface track; purpleLight label color
- `workouts_screen.dart` — `_PillTabBar` (lime active pill / purple-outline inactive); lime+black FAB
- `workout_list_tile.dart` — purpleDark 48×48 circle leading, purpleLight subtitle, lime chevron_right
- `workout_calendar.dart` — purple day-of-week headers + nav arrows; lime selected circle with black text; purple 20% alpha today highlight; lime workout dots (black when day is selected)

## Completed — Phase 4 (Nutrition + Progress) — 2026-04-05

- `nutrition_screen.dart` — `ConsumerStatefulWidget` with `_TabToggle` (lime active pill / purple-outline inactive); "Meal Plans" tab shows a `_MealPlansPlaceholder` (purpleDark circle + lime icon); `bottomNavigationBar` hidden on Meal Plans tab
- `meal_section.dart` — purpleDark 36×36 circle icon container, lime Poppins SemiBold meal type label, lime Add Food TextButton.icon
- `food_entry_tile.dart` — Poppins Medium food name; macro tags: protein=purple bg+text, carbs=purpleLight bg+text, fat=lime bg + #7A9000 dark text; calories in AppColors.lime
- `daily_summary_header.dart` — macro bars now have fixed `baseColor` per macro (protein=purple, carbs=purpleLight, fat=lime); good threshold turns bar lime; over threshold turns bar error
- `complete_day_button.dart` — `_CompleteButton`: lime bg + black text; `_LockedBanner`: purpleDark Container with lime trophy icon; trophy sheet heading in lime Poppins Bold
- `micronutrient_section.dart` — leading icon = AppColors.purple; bar colors: purple (normal), lime (≥90%), error (>110% / sodium overflow)
- `progress_screen.dart` — `ConsumerStatefulWidget`; `PreferredSize` AppBar with purple background, profile avatar (purpleDark circle + lime icon), `_ProgressTabToggle` (lime active / white inactive); tab 0 = Workout Log (milestones + weight chart + lime "Log Weight" button); tab 1 = Charts (strength + nutrition trends)

## Key Tab Toggle Pattern

A reusable pattern used in both nutrition and progress screens:
- Container with `darkSurfaceBorder` border + 3dp padding + circular border radius
- Two `_TabPill` widgets (Expanded) inside a Row
- Active pill: `AnimatedContainer` with lime background, black Poppins SemiBold text
- Inactive pill: transparent background, purple (nutrition) or white (progress) text
- 200ms `easeInOut` transition

## Remaining Per-Screen Plans

### Workouts (detail)
- ExerciseCard: muscle group color indicator on left border

### Progress polish
- WeightChart: increase gradient fill opacity
- MilestoneBadges: scale(1.05) + shadow on earned badges

### Animations (optional polish)
- StreakCounter: pulse/glow animation when streak > 0

## Font Pairing (Current)
- Poppins Bold/SemiBold/Medium for headings and CTAs
- League Spartan Regular for body/subtitles
- Both declared in pubspec.yaml as asset fonts (not google_fonts package)
