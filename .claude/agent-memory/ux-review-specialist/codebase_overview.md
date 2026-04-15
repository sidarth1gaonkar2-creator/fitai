---
name: Codebase Overview
description: Screen inventory, confirmed tech stack, widget conventions, and routing structure for FitAI Flutter app (updated April 2026)
type: project
---

## Tech Stack
- Flutter + CupertinoApp.router (Material ThemeData injected via builder for remaining Material widgets)
- Riverpod manual providers — no @riverpod codegen (Isar v3 conflict)
- Isar 3.1.0+1 for local persistence (17 collections)
- Firebase (Auth, Firestore, Storage) for social/community backend
- go_router 14.x with StatefulShellRoute.indexedStack for bottom nav
- flutter_local_notifications for scheduled reminders

## Color System
- iOS-native palette: black/white/blue (NOT purple/lime — legacy variable names are misleading)
- `AppColors.of(context)` returns brightness-aware `Palette` object
- Dark: #000000 bg, #1C1C1E surfaces, #0A84FF accent (iOS blue)
- Light: #F2F2F7 bg, #FFFFFF surfaces, #007AFF accent (iOS blue)

## Screens (by feature area)

### Auth
- WelcomeScreen — sign in / sign up entry
- SignInScreen — email/password + Google
- SignUpScreen — registration

### Onboarding
- OnboardingScreen — 6-step PageView (Name, BodyInfo, Measurements, Goal, Activity, Summary)
- ProfileSetupScreen — social profile creation (username, bio, pic) post-onboarding

### Shell
- ShellScreen — 5-tab custom bottom nav: Home, Workouts, Nutrition, Progress, Community

### Dashboard
- DashboardScreen — Calorie ring, macro row, streak + water, today workout card, supplement checklist, quick actions

### Workouts
- WorkoutsScreen — Calendar + filtered list + Templates tab
- WorkoutLoggingScreen (new & edit) — Live timer, exercise list, finish button
- WorkoutDetailScreen — Read-only view with MuscleGroupDiagram, delete/edit
- ExercisePickerSheet — Modal with search, filter chips, 106 exercises
- TemplatePickerSheet + TemplatePreviewScreen — Browse and start from templates

### Nutrition
- NutritionScreen — NutritionSummaryCard + 4x MealSection + MicronutrientSection + CompleteDayButton + Meal Plans tab
- FoodSearchScreen — Dual-source (local instant + remote), debounced
- BarcodeScannerScreen — MobileScanner + lookup
- FoodDetailScreen — Serving size picker, nutrition preview, Add
- MealPlansScreen, CreateMealPlanScreen, MealPlanPreviewScreen — Custom meal plans

### Supplements
- SupplementsScreen — Manage active/inactive supplements, consistency tracking
- AddSupplementSheet — Library catalog + custom form
- SupplementChecklistCard — Dashboard checklist widget

### Progress
- ProgressScreen — Milestones, WeightChart, StrengthChart, NutritionTrends
- PRHallScreen — Personal records gallery (sortable, filterable)

### AI Coach
- AICoachScreen — Chat UI with streaming, empty state, error snackbar

### Community (Firebase-backed)
- CommunityScreen — Hub: Feed, Leaderboard, Challenges, Search
- FeedScreen — Paginated workout posts
- PostDetailScreen — Comments, likes
- LeaderboardScreen — Rankings by streak/volume/workouts, global vs friends
- ChallengesScreen — Browse public + joined challenges
- ChallengeDetailScreen, CreateChallengeScreen
- ProfileScreen, EditSocialProfileScreen
- UserSearchScreen, FollowersListScreen
- ShareWorkoutSheet

### Settings
- SettingsScreen — Profile tile, dark mode toggle, reset data
- EditProfileScreen — Full profile edit form
- NotificationSettingsScreen — All notification category toggles + time pickers

## Core Widgets
- ShimmerBox, ShimmerList, ShimmerCard — custom shimmer system
- ErrorCard — reusable error widget with optional retry
- CalorieRing — CustomPainter ring
- WorkoutCalendar — custom GridView calendar
- MuscleGroupDiagram — CustomPainter front+back silhouettes (SVG-backed)
- SupplementChecklistCard, SupplementConsistencyCard
- PRCard, PRBanner, PRConfettiOverlay

## Routing Notes
- /onboarding, /profile-setup are standalone GoRoutes (no shell)
- /settings, /settings/edit-profile, /supplements are standalone routes (slide-up transition)
- All shell branches use slideUpTransitionPage for sub-routes
- Route redirect guards: no auth → /welcome; no profile → /onboarding; no social profile → /profile-setup
- Community routes under /community/* and /profile/*
