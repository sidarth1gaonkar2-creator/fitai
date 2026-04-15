---
name: Dashboard Widget Map
description: All widgets on the dashboard screen, their data sources, and current visual state (updated April 2026)
type: project
---

File: lib/features/dashboard/presentation/dashboard_screen.dart

Data providers:
- userProfileProvider (FutureProvider) — gates the entire screen; shows full-page shimmer while loading
- todayNutritionProvider (FutureProvider) — uses valueOrNull, silently shows 0 if loading/null
- todayWorkoutProvider (FutureProvider) — uses valueOrNull
- streakProvider (FutureProvider) — uses valueOrNull, defaults to 0
- waterIntakeProvider (StateProvider) — in-memory, always available
- supplementChecklistProvider (FutureProvider) — active supplements + today's logs

Widgets rendered (in order):
1. CalorieRing (200x200) — single-color arc, CustomPainter, strokeWidth=14, StrokeCap.round
2. MacroRow — three _MacroBar columns (Protein/Carbs/Fat) with LinearProgressIndicator, 8dp track height
3. StreakCounter + WaterTracker — side by side in a Row
4. TodayWorkoutCard — shows workout title or CTA
5. SupplementChecklistCard — today's supplement checklist with animated checkboxes, count display
6. Quick action buttons (Log Meal / Log Workout)

**Shimmer gap:** Only the top-level profileAsync uses .when() with shimmer. The nutrition/workout/streak providers use valueOrNull — no per-widget loading skeleton exists for those.
