---
name: Codebase Overview
description: Screen inventory, confirmed tech stack, widget conventions, and routing structure for FitAI Flutter app
type: project
---

## Tech Stack (confirmed in code)
- Flutter + Material 3 (MaterialApp.router, ColorScheme tokens throughout)
- Riverpod manual providers (FutureProvider, StateNotifierProvider, StateProvider, Provider) — no @riverpod codegen
- Isar 3.1.0+1 with generated .g.dart files
- go_router 14.x with StatefulShellRoute.indexedStack for bottom nav

## Screens
- OnboardingScreen — 6-step PageView (Name, BodyInfo, Measurements, Goal, Activity, Summary)
- ShellScreen — BottomNavigationBar wrapping 5 branches
- DashboardScreen — Calorie ring, macro row, streak + water, today's workout card, quick action buttons
- WorkoutsScreen — Calendar + filtered list
- WorkoutLoggingScreen (new & edit) — Live timer, exercise list, finish button
- WorkoutDetailScreen — Read-only view with delete/edit actions
- NutritionScreen — DailySummaryHeader + 4x MealSection cards
- FoodSearchScreen — Debounced search with barcode scanner shortcut
- BarcodeScannerScreen — MobileScanner + lookup overlay
- FoodDetailScreen — Serving size picker, nutrition preview, Add button
- ProgressScreen — Milestones, WeightChart, StrengthChart, NutritionTrends
- AICoachScreen — Chat UI with streaming, empty state, error snackbar
- SettingsScreen — Profile tile, dark mode toggle, reset data
- EditProfileScreen — Full profile edit form

## Core Widgets
- ShimmerBox, ShimmerList, ShimmerCard — custom shimmer system (no third-party package)
- ErrorCard — reusable error widget with optional retry
- CalorieRing — CustomPainter ring
- WorkoutCalendar — custom GridView calendar

## Routing Notes
- /onboarding is a standalone GoRoute (no shell)
- /settings and /settings/edit-profile are standalone routes above the shell (slide-up transition)
- All 5 shell branches use slideUpTransitionPage for sub-routes
- Route redirect guards onboarding: no profile -> /onboarding; has profile -> /dashboard
- Workout detail path: /workouts/:id (int.parse on pathParameters with !)
- Food detail passes FoodSearchResult via state.extra — crash risk if extra is null
