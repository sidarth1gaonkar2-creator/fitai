---
name: Cupertino Migration Audit (2026-04-08)
description: Findings from iOS HIG compliance review after Material→Cupertino migration
type: project
---

App migrated from MaterialApp to CupertinoApp.router. Key structural facts for future reviews:

- `lib/app.dart`: CupertinoApp.router + transparent Material wrapper in builder. No MaterialApp, no Theme widget — so `Theme.of(context)` resolves to `ThemeData.fallback()` (light M3) throughout the app. Every widget using `Theme.of`, `textTheme`, `colorScheme` is getting unthemed values.
- `lib/features/shell/presentation/shell_screen.dart`: 6-tab custom bar (HIG max is 5). GestureDetector with HitTestBehavior.opaque — tap targets are full Expanded width so hit area is fine even though icon+label column is small.
- Bottom nav bar height is 56 (hardcoded SizedBox) + SafeArea. HIG standard is 49pt content area — 56 is slightly taller than spec but acceptable.
- Nav bar label font size 10pt matches HIG. Font weight w600 on selected is correct. Poppins (non-system font) used throughout — intentional brand choice.
- No CupertinoSliverNavigationBar large-title usage anywhere — all screens use compact CupertinoNavigationBar.
- Icons.fitness_center used as workouts tab icon (no Cupertino equivalent) — minor but intentional.

Remaining Material widgets (not converted):
- `complete_day_button.dart`: AlertDialog + showDialog + FilledButton + showModalBottomSheet (Material)
- `weight_entry_dialog.dart`: AlertDialog + TextField + FilledButton
- `today_workout_card.dart`: ElevatedButton
- `rest_timer_sheet.dart`: FilledButton.tonal x2 + FilledButton
- `set_row.dart`: TextField x2 (reps/weight inline inputs — CupertinoTextField would be appropriate)
- `workout_logging_screen.dart`: TextField (title input)
- `daily_summary_header.dart` (NutritionSummaryCard): Material Card + LinearProgressIndicator
- `meal_section.dart`: Material Card + TextButton.icon
- `micronutrient_section.dart`: Material Card + ExpansionTile + LinearProgressIndicator
- `workout_list_tile.dart`: Material Card + ListTile
- `water_tracker.dart`: Card.filled (uses Material Card)
- `food_detail_screen.dart`: Card.filled x2 + FilledButton.icon + FilledButton.tonal
- `nutrition_trends.dart`: Card.outlined
- `template_picker_sheet.dart`, `exercise_picker_sheet.dart`: showModalBottomSheet (Material)
- `settings_screen.dart`: ListTile x2 inside _SettingsCard containers
- `meal_plan_card.dart`, `meal_plan_preview_screen.dart`: FilledButton
- `activity_step.dart`, `body_info_step.dart`, `goal_step.dart`, `name_step.dart`, `summary_step.dart`: FilledButton (onboarding CTAs)
- `chat_input_bar.dart`: TextField (multi-line — CupertinoTextField supports maxLines)

Screens with custom purple headers (not CupertinoNavigationBar):
- `workouts_screen.dart`: _WorkoutsHeader is a Container(color: purple) with TabController — not converted
- `progress_screen.dart`: _buildAppBar returns PreferredSize Container(color: purple) — not converted

ScaffoldMessenger.showSnackBar still called in 7+ locations (should use showCupertinoToast).

BouncingScrollPhysics: Not set globally or per-screen. All ListViews/ScrollViews use default physics (ClampingScrollPhysics on Android, BouncingScrollPhysics on iOS via platform default). On iOS this is correct by default; no global override needed. No action required.

**Why:** CupertinoApp on iOS will already use BouncingScrollPhysics by default via ScrollBehavior.

CupertinoButton(padding: EdgeInsets.zero, minimumSize: Size.zero): Used in ~10 nav bar trailing slots. These icons are 22-24pt in a CupertinoNavigationBar trailing area. The trailing area itself provides touch slop, but the explicit Size.zero minimumSize means the engine's hit-test rect is exactly the icon's paint rect (22-24pt) — below the 44pt HIG minimum.
