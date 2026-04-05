---
name: Pre-Implementation UX Review — Planned Features (2026-04-05)
description: UX risk analysis for 5 planned features before implementation begins — food search dual-source, nutrition screen redesign, exercise library, workout templates, settings back button
type: project
---

## Scope
Review conducted before implementation. No new code exists for these features yet.
Reviewed against: food_search_screen.dart, nutrition_screen.dart, barcode_scanner_screen.dart, settings_screen.dart, app_router.dart.

## Feature 1 — US Food Database + Search Integration

### Dual-Source Result Confusion
- Current foodSearchProvider returns a flat List<FoodSearchResult> — no source metadata on FoodSearchResult model.
- If local and remote results are merged into one flat list, users cannot distinguish trust/quality between sources.
- Local results arrive ~instantly; remote results have 300-800ms+ latency. A single merged provider will block the entire list until remote finishes, negating the local-first benefit.
- Recommendation: surface two async states — local resolves first (show immediately), remote appended with a "More results" section header.

### Empty State Gap (inherits existing issue)
- Current "No results found." is plain text with no icon and no barcode scan suggestion (noted in Pass 1 audit, food_search_screen.dart line 130).
- With dual sources, three new empty states are needed:
  1. Local results found, remote still loading — show local list + shimmer section below
  2. Local results found, remote returned nothing — show local list + "No additional results online"
  3. Both sources empty — current plain text is insufficient; add barcode scan CTA

### Barcode Scanner + Local DB
- BarcodeScannerScreen.dart calls barcodeLookupProvider which resolves via Open Food Facts only.
- If local DB is added, barcode lookup must check local DB first (faster, offline-capable), then fall back to remote.
- Current navigation: context.go('/nutrition/food/...') on match; back from FoodDetail lands on NutritionScreen (scanner dropped from stack — existing audit finding). This gets worse with local DB hits because users won't expect to lose the scanner on a local match.

### Loading State Architecture
- The planned "local results instant, remote results delayed" model cannot be served by the current single AsyncValue<List<FoodSearchResult>> approach without a shimmer placeholder for the remote section.
- Risk: if implemented naively as one merged provider, the whole list blocks on the slowest source (network), losing the instant-local benefit entirely.

## Feature 2 — Cronometer-Style Nutrition Screen

### Screen Length / Information Density
- Current NutritionScreen: DailySummaryHeader + 4 MealSection cards already fills ~800dp on a standard phone.
- Adding a calorie ring, macro breakdown, and a 10-micronutrient expandable section will push total content height to ~1400-1600dp.
- Risk: micronutrient section will be completely off-screen on load. Users will not discover it without prompting.
- Recommendation: collapse micronutrient section by default with an "Micronutrients" ExpansionTile showing a summary badge (e.g. "3 of 10 tracked today"). Use the existing Card.filled style.

### Micronutrient Empty States
- Most foods in Open Food Facts lack micronutrient data. 10 rows showing "0 / — mg" is demotivating.
- Recommendation: group tracked micros separately from untracked ones. Show "No data for X nutrients — try scanning packaged foods" for untracked items.

### "Complete Day" Discoverability
- A button that locks all data for the day is a high-stakes action. Placing it at the bottom of a long scroll means users must scroll past all meal sections and micronutrients to find it.
- Risk: users will miss it entirely, or accidentally tap it while scrolling.
- Recommendation: place in AppBar as a trailing action (icon + tooltip) or as a persistent bottom bar that appears only when at least one food has been logged. Do not bury it below the fold.

### Locked Day State
- No mechanism currently exists in the data model or UI to represent a "locked" day.
- Key questions before implementation:
  1. Is there an Isar model field for locked state? (not seen in nutrition_log.dart/meal.dart review)
  2. Can "Add Food" in MealSection still be tapped on a locked day? If not, the button must visually disable — not just silently fail.
  3. Undo path: a locked day with no undo is a destructive action by UX convention. Must show a snackbar with "Undo" for at least 5 seconds, or a dedicated "Unlock Day" button in the same position as "Complete Day".
- Recommendation: treat "Complete Day" as a reversible action, not a permanent lock. Show a locked banner at the top of the screen with an "Unlock" action visible without scrolling.

### "Complete Day" Haptic
- A day-completion action is a major milestone. Use HapticFeedback.mediumImpact() (confirmation pattern established in codebase). Consider a brief confetti or success animation.

## Feature 3 — Exercise Library + Muscle Diagram

### Muscle Diagram Utility at 200dp
- A full front/back body diagram at ~200dp width on a phone screen renders individual muscles at roughly 10-20px. At this size, tapped muscle regions are below the 48dp tap target requirement.
- If the diagram is interactive (tap to filter), this is a critical accessibility failure.
- If the diagram is purely illustrative (highlights muscles of the selected exercise), it remains useful but only marginally — users may not be able to distinguish highlighted vs unhighlighted muscle regions.
- Recommendation: make the diagram non-interactive at this size. Use it as a visual highlight only, with muscle names listed as text chips below for interactive filtering. This keeps tap targets at 48dp minimum.

### Filter Bar Overwhelm
- 8 muscle group options in a horizontal filter bar is at the upper edge of usability. With chip labels (Chest, Back, Shoulders, Arms, Core, Legs, Glutes, Full Body), total scrollable width exceeds screen width on most devices.
- Users may not realize the filter bar is scrollable — no scroll indicator or fade edge.
- Recommendation: add a right-edge gradient fade to indicate overflow. Alternatively, reduce to 6 options by merging (e.g., Arms covers Biceps + Triceps, Legs covers Quads + Hamstrings + Calves).

### Exercise Picker in Workout Logging Context
- When the exercise library is entered from WorkoutLoggingScreen, the expected interaction is: browse/search -> tap exercise -> return to logging screen with exercise added.
- Current go_router structure has no route for an exercise picker modal. Using context.go() would push a full screen; using showModalBottomSheet would keep logging context visible.
- Risk: if implemented as a full screen with context.go, pressing back from exercise library loses the user's workout-in-progress state if ActiveWorkoutState is not persisted correctly.
- Recommendation: implement as a DraggableScrollableSheet modal from WorkoutLoggingScreen, not a pushed route. This keeps the logging screen visible and avoids state loss.

### Dark Mode Muscle Diagram
- SVG or image-based body diagrams with hardcoded colors (e.g., grey body, red highlights) will not adapt to dark mode.
- Recommendation: use ColorScheme tokens for highlighted muscles (colorScheme.primary or colorScheme.tertiary) and surface/outline for the body silhouette. If using an SVG package, inject color at render time.

### Difficulty Badge Accessibility
- Difficulty badges (e.g., "Beginner", "Advanced") likely use color coding (green/yellow/red). Color alone fails accessibility.
- Recommendation: always include the text label alongside any color coding. Never rely on color alone.

## Feature 4 — Workout Templates

### Access Point Discoverability
- WorkoutsScreen currently has a FAB for starting a new workout. Adding templates as a second entry point creates a navigation choice problem.
- Options ranked by discoverability:
  1. FAB extended with a speed dial (two options: "Start Blank" / "Use Template") — most discoverable
  2. Segmented control or TabBar at top of WorkoutsScreen (History / Templates) — clear, always visible
  3. Separate tab in bottom nav — too prominent for a secondary feature
  4. Hidden inside FAB menu — lowest discoverability
- Recommendation: TabBar within WorkoutsScreen is the best fit. It reuses the existing screen without adding a nav tab, and keeps templates at zero-tap depth from the workouts branch.

### 20 Templates Without Categorisation
- A flat list of 20 templates is borderline manageable but only if each template has a clear name and brief description visible in the list item.
- Without categories (e.g., Strength, Cardio, HIIT, Beginner, Upper/Lower), users must scroll all 20 to find what they want.
- Recommendation: group by category using SliverList with StickyHeaders, or a filter chip bar (3-4 categories is fine). At minimum, add a search field above the list.

### Template Modification Before Starting
- If users cannot modify a template before starting, power users will abandon templates entirely and build from scratch.
- Minimum viable modification: allow removing exercises before tapping "Start Workout". A checkbox next to each exercise in the preview, or a swipe-to-remove gesture, handles this.
- "Save as custom template" is a stretch goal but highly expected by fitness app users. Flag this as a planned v2 feature and design the data model to support it (custom flag on template entity).

### Template Preview Screen
- The preview -> "Start Workout" flow needs:
  1. A clear list of all exercises (sets x reps format)
  2. Estimated duration
  3. A prominent "Start Workout" FilledButton at the bottom (not buried if list is long — use a persistent bottom bar)
- Risk: if "Start Workout" is a list item below a long exercise list, users on small screens will miss it.

## Feature 5 — Settings Back Button

### Confirmed: Back Button Is Present
- settings_screen.dart line 22: `appBar: AppBar(title: const Text('Settings'))`.
- AppBar in go_router automatically shows a back arrow when the route is pushed onto a stack above the root.
- /settings is defined as a standalone GoRoute above the StatefulShellRoute (app_router.dart line 42) with slideUpTransitionPage.
- On iOS, a slide-up (modal) transition means the OS does not provide a swipe-back gesture (swipe-back only works for standard push transitions).
- The AppBar back button IS present via Flutter's automatic leading behavior, BUT: on iOS slide-up modals, the standard left-edge swipe-back gesture does not work. The only way to dismiss is via the AppBar back button.
- Risk: if the user's thumb cannot reach the top-left back arrow (large phones, one-handed use), there is no alternative dismissal gesture.
- Recommendation: add a close button (Icons.close) as the leading icon explicitly, and/or support a downward swipe-to-dismiss using DraggableScrollableSheet or a custom scroll behavior. This is a minor improvement, not a critical bug, because the back button does exist.

### Edit Profile Sub-Route
- /settings/edit-profile is also a slideUpTransitionPage (app_router.dart line 49), so the same iOS swipe-back limitation applies there too.

## Summary of Severity Ratings

### Critical
- Dual-source food search: single merged provider will block local results on remote latency — defeats the entire local-first purpose.
- Muscle diagram interactive tap targets: if filterable by tapping diagram regions at 200dp, muscle tap areas will be well below 48dp.
- "Complete Day" button below the fold: a high-stakes action that users will miss or accidentally trigger while scrolling.

### Major
- Barcode scanner navigation: back from FoodDetail drops scanner (existing, worsened by local DB path).
- Micronutrient empty state: 10 zero-value rows with no guidance is demotivating and clutters the screen.
- Template access point: no clear entry point defined; templates buried in a FAB submenu will be undiscovered by most users.
- Exercise picker as pushed route risks losing active workout state.

### Minor
- Filter bar overflow indicator missing (exercise library).
- Settings slide-up modal: no swipe-down-to-dismiss on iOS.
- Locked day undo: treat as reversible from day one.
- Template preview "Start Workout" button may be buried below long exercise list.
