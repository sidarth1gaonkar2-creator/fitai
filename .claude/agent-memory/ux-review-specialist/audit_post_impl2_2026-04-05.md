---
name: Post-Implementation Audit — UI Overhaul Pass (2026-04-05)
description: Critical and major UX findings from the full UI overhaul covering shell, dashboard, workouts, nutrition, progress, AI coach, settings, onboarding, and all associated widgets.
type: project
---

> **STALE COLOR REFERENCES:** This audit was written during the purple/lime era. All hex values and contrast calculations referencing #C8F135 (lime), #7B5CF6 (purple), #3D2FA0 (purpleDark), #242424 (darkSurface), #1A1A1A (darkBackground) are outdated. The app now uses an iOS-native black/white/blue palette. See `ui_theme_pattern.md` for current values. Tap target, semantics, and structural findings remain valid.

## Findings summary

### Critical
- WaterTracker +/- buttons are 36x36dp, below the 48dp minimum.
- WorkoutCalendar day cells are approximately 34dp on a 375pt wide phone — well below 48dp — and have no semanticLabel for screen readers.
- FoodEntryTile `_MacroTag` for Fat uses hardcoded `Color(0xFF7A9000)` (dark olive) on a white/lime bg in light mode — this is not a design-token color and has unknown contrast. On the dark surface bg it may pass, but it is not tied to any theme-aware token.
- `_SuggestedPromptChip` in ai_coach_screen.dart uses `GestureDetector` directly; the chip has no minimum tap-target constraint. At short text lengths ("Suggest a workout plan") the vertical hit area can be under 40dp.
- SettingsScreen `_ProfileHeader` uses a bare `GestureDetector` wrapping a full-width container — fine for width, but no `Semantics` label ("Edit profile") is provided, so screen readers announce nothing meaningful.
- `MealSection` icon badge is 36x36dp — the icon is decorative but the surrounding header row is not tappable so this is cosmetic, not a tap target issue. Noted for completeness.
- `_WaterIconButton` is explicitly `SizedBox(width: 36, height: 36)` — this is a confirmed sub-48dp tap target issue.

### Major
- All `Icon` widgets used as decorative or semantic elements throughout the codebase (shell nav icons, stat card icons, meal type icons, streak fire icon, water drop icon, onboarding illustration icons) have no `semanticLabel`. Flutter marks bare `Icon()` as non-semantic by default but TalkBack/VoiceOver may still announce the icon name if `Semantics` or `semanticLabel` are absent.
- Lime (#C8F135) on `purpleDark` (#3D2FA0) background used in: `SelectableCard` (selected icon badge), `MealSection` header icon. Purple-dark background with lime icon — contrast ratio is approximately 5.5:1, passes AA for normal text but is borderline for small icons at 18-20dp.
- Lime text on white surface: `lightCta` (`Color(0xFF8DB000)`) is defined in AppColors but lime (`#C8F135`) as text on white fails WCAG AA (contrast ~1.9:1). Lime is only used as a CTA background with black text in buttons — this is fine. However, in `FoodEntryTile` the calorie value is `AppColors.lime` text on a Card (dark surface `#242424`). Contrast ratio lime on #242424 = approximately 9.5:1 — passes.
- `_ProgressTabToggle` and `_PillTabBar` (workouts) tab pills have `padding: EdgeInsets.symmetric(vertical: 9 or 10)` inside an `AnimatedContainer`. The full pill container height inside a 40dp outer container is 40 - 6 (border + margin) = 34dp. This is the tappable height for a tab switch — below 48dp.
- `WorkoutCalendar` day-of-week header row uses duplicate 'T' labels (Tuesday and Thursday both show 'T', Saturday and Sunday both show 'S'). Screen readers and users relying on text cannot distinguish them.
- `dashboard_screen.dart` line 47: when `profile == null` the body returns `SizedBox.shrink()` with no Scaffold — the user sees a blank Scaffold from the loading branch's AppBar with no body content. Should show a prompt to complete onboarding.
- `EditProfileScreen` has no error handling around the Isar write at line 99. If the write throws, `_isSaving` stays true and the button is permanently disabled with no user feedback.
- `SummaryStep` "Get Started" button has no haptic feedback on `onPressed`.
- `_NextButton` across all onboarding steps has no haptic feedback when tapped.
- `StreakCounter` has no semantic label — a user on VoiceOver hears "7" with no context.
- `MacroRow` progress bars use `AppColors.lime` for Fat — lime (`#C8F135`) on `AppColors.darkSurface` (`#242424`) background has sufficient contrast (~9.5:1), which is fine.
- `WaterTracker` glass dots (20x20dp) are decorative (not interactive), so tap target is not an issue there. The interactive controls are the ±36dp buttons — confirmed issue.
- `TypingIndicator` has no `Semantics` wrapper — screen readers will announce nothing while the AI is processing, leaving blind users with no indication.
- AI Coach `_EmptyState` icon (`Icons.smart_toy_rounded`) has no `semanticLabel`.
- `_ProfileHeader` in settings uses `GestureDetector` with no `Semantics` — screen reader users cannot discover or activate the "Edit profile" affordance.

### Good patterns
- Haptic feedback present in: `WaterTracker` +/- buttons, `SelectableCard` onTap, `ChatInputBar` send, `FoodEntryTile` dismiss, `CompleteDayButton` complete/unlock, `SettingsScreen` toggle, reset dialog.
- Shimmer/skeleton loaders implemented throughout dashboard, workouts, nutrition, progress.
- `AsyncValue.error` branches render `ErrorCard` with retry actions in all main screens.
- Empty states present in: workouts history tab (icon + message), AI coach (suggested prompts), nutrition meal sections ("No foods logged yet").
- `CalorieRing` has a proper `Semantics` label with percentage announced.
- `DashboardScreen` profile null-guard exists; onboarding flow has back navigation.
- `EditProfileScreen` shows inline loading spinner in the save button during async save.
- `CompleteDayButton` trophy sheet and unlock dialog are well-structured.
- `onboarding_screen.dart` progress indicator is present; back navigation is handled per-step.
