---
name: Pre-Implementation UX Review — Round 2 (2026-04-05)
description: UX risk analysis for 6 planned changes — micronutrient always-visible, day completion sheet, settings back nav fix, instant local search, macro colour coding, full UI design system overhaul. Also covers current-state audit of dashboard, ai_coach, progress, shell screens.
type: project
---

## Scope
Planned changes reviewed before any implementation.
Files read: micronutrient_section.dart, complete_day_button.dart, settings_screen.dart, app_router.dart, food_search_screen.dart, daily_summary_header.dart (NutritionSummaryCard), dashboard_screen.dart, ai_coach_screen.dart, progress_screen.dart, shell_screen.dart.

---

## Change 1 — Micronutrient Section Always Visible

### Key finding: current architecture uses filter-by-value > 0 for the tracked list
- `consumed.entries.where((e) => e.value > 0)` on line 26 means zero-value nutrients are classified as "untracked" and appear only in the text footer, not as bars.
- On a fresh day ALL 10 nutrients will be in `untracked`; zero bars will be rendered, the section will show only the subtitle "0 of 10 nutrients tracked today" and the info text listing all 10 names.
- The plan to "always show all 10 bars at 0/target" requires reclassifying the bar rendering: bars must be rendered for ALL keys in microRdaTargets, not just those where consumed > 0.

### Overwhelm risk: MAJOR
- 10 bars at 0% simultaneously, with identical grey colouring, is a wall of emptiness. There is no visual hierarchy or actionable guidance.
- The animation (TweenAnimationBuilder begin: 0, end: 0.0) will play silently and convey nothing — all bars animate from 0 to 0.
- The section header subtitle will read "0 of 10 nutrients tracked today" which is factually correct but reads as a failure state at day start — discouraging for new users.

### Collapse-by-default is correct; REINFORCE it
- Current ExpansionTile has `initiallyExpanded: false` — this is the right decision. Do NOT change it to expanded.
- The collapsed tile on a zero-day shows the subtitle "0 of 10 nutrients tracked today" which is adequate as a teaser. Users can expand if curious.
- Recommended subtitle change for zero state: "Tap to see which nutrients to hit today" — actionable and not a guilt-trip.

### Recommended architecture change
- Separate rendering into two groups ONLY visually, not by hiding bars:
  - Group A (consumed > 0): rendered as animated bars (current behaviour, unchanged)
  - Group B (consumed == 0): rendered as muted grey bars with a "Not yet tracked" style — still bars, but visually subdued (lower opacity or explicit label "–")
- This communicates that tracking IS happening, just not yet filled, without creating a demoralising wall.
- Total rendered rows: 10 always. The info footer listing untracked names can be removed once all 10 are shown as bars.

### ExpansionTile haptic gap (from post-impl audit)
- micronutrient_section.dart has no haptic on expand/collapse. onExpansionChanged callback must be added with HapticFeedback.selectionClick().

---

## Change 2 — Day Completion Sheet (Trophy + Score)

### Bottom sheet vs dialog: bottom sheet is the RIGHT pattern
- The existing unlock action already uses AlertDialog correctly (it is a short, 2-button confirmation). Complete Day is richer content (animation, score, summary) — bottom sheet is the right container.
- ModalBottomSheet with DraggableScrollableSheet or a fixed-height showModalBottomSheet is appropriate.
- Ensure `isDismissible: true` and `enableDrag: true` are set explicitly, and handle the dismiss-by-swipe case carefully (see below).

### Swipe-to-dismiss = cancel (CRITICAL decision)
- If the sheet is draggable, swiping down MUST mean "cancel / do not complete the day". This is the standard iOS/Android sheet convention.
- The sheet must NOT complete the day on swipe-dismiss. The `Navigator.pop(context, false)` path must be triggered on drag-dismiss.
- Implement: pass a result value; only call `completeDay(ref)` when the explicit confirm button is tapped. Use `showModalBottomSheet<bool>(...)` and check result == true.
- Risk if not implemented: user admires the trophy animation, then swipes down thinking they confirmed — day is NOT completed and they don't know it.

### Score (0-100): motivating vs discouraging
- A score of 0 on day start (or 12 at 10am) is actively discouraging and will cause users to skip the celebration sheet entirely.
- Recommendation:
  - Only show the score if it is >= 50. Below 50, replace score with "You logged today — that's what matters." This preserves the positive reinforcement framing.
  - Score display: large number with coloured ring (green >= 90, amber 50-89, no score < 50). Do NOT show red scores.
  - Alternatively: show "X macros hit" as stars (3-star system) rather than a 0-100 number. Stars are universally understood as achievement, not judgment.

### Trophy animation note
- If using a Lottie or custom animation, ensure it has a semanticLabel on the widget wrapping it.
- Animation should play once and stop; avoid looping trophies (feels cheap after first view).
- Fallback: if animation package is not available, a large Icon(Icons.emoji_events, size: 72, color: colorScheme.tertiary) with a ScaleTransition is sufficient.

### Current CompleteDayButton error branch gap (from post-impl audit, line 26)
- error: (_, _) => const SizedBox.shrink() silently hides the button. This MUST be fixed before adding the sheet — if the provider fails, users need to know the button is unavailable, not just see empty space.
- Fix: replace with the TextButton.icon retry widget currently used in the loading branch, but styled as a minimal error state.

### Haptic on confirm
- mediumImpact is already fired in onComplete (complete_day_button.dart line 41). This is correct for the confirmation tap.
- If a trophy animation plays, consider adding a second mediumImpact when the animation peaks (after ~500ms delay) to reinforce the moment.

---

## Change 3 — Settings Back Button Navigation Fix

### context.go('/dashboard') is WRONG for most user journeys
- Settings is opened via context.go('/settings') from DashboardScreen (dashboard_screen.dart line 63). This replaces the shell location, not pushes onto a stack.
- However settings is defined as a standalone GoRoute ABOVE the StatefulShellRoute, and uses slideUpTransitionPage — it is a modal, not a tab.
- When the user navigates /settings from the dashboard, go_router's navigator stack has the shell at /dashboard underneath /settings.
- context.go('/dashboard') will navigate to dashboard — this WORKS in the common case but is semantically wrong and will break in any other entry point.

### The correct fix: context.pop()
- context.pop() respects the navigator stack. From /settings, pop returns to wherever the user came from.
- context.go('/dashboard') hardcodes the destination. If settings is later reachable from another screen (e.g., progress screen), go('/dashboard') would disorient users by landing them on dashboard instead of where they came from.
- The same applies to /settings/edit-profile — it should pop, not go.

### CloseButton vs BackButton
- CloseButton (the X icon) is semantically correct for modal screens (slide-up from bottom). Keep using CloseButton.
- The icon itself is fine. The action behind it should change to context.pop().
- On Android, the OS back gesture and hardware back button both fire pop() automatically — context.go() would be ignored by those. This is another reason go('/dashboard') is wrong: it creates inconsistency between the OS back gesture (pops correctly) and tapping the button (goes to dashboard, may behave differently).

### edit-profile sub-route
- Same issue applies. edit_profile_screen.dart should use context.pop() to return to /settings, not context.go('/settings') (which would re-push a new settings instance).

---

## Change 4 — Nutrition Search Instant Local Results

### Current architecture is already correct — no async gap
- food_search_screen.dart line 51-52: `foodLocalSearchProvider(_currentQuery)` is watched synchronously (it returns `List<FoodSearchResult>`, not `AsyncValue<...>`).
- On first frame after `_currentQuery` is set, `localResults` is immediately available — no loading state, no shimmer needed for the local section.
- The only async gap is the 400ms debounce (line 35) before `_currentQuery` is updated. This is intentional and correct (avoids searching on every keystroke).

### Potential race condition on rapid query changes
- If the user types "chicken breast" quickly, the debounce fires for the final value. However `_currentQuery` changes via setState, which triggers a build. If the user clears the field mid-debounce, the stale Timer fires with an empty string — but the check `value.trim().length >= 2 ? value.trim() : ''` guards this correctly.
- The remote provider uses the query as a family key: `foodRemoteSearchProvider(_currentQuery)`. Riverpod family providers cache by key, so rapid typing creates multiple providers that all fire network requests. Each will be resolved and cached separately, but only the current `_currentQuery` key is watched.
- Risk: network requests for intermediate queries (e.g. "chi", "chic", "chick") are all fired and may complete out of order. Riverpod family caching means none will cause a visible glitch, but it creates unnecessary network load.
- Recommendation: the debounce covers this — only the final debounced query is set into `_currentQuery`, so only that key triggers the remote provider. This is already correctly implemented.

### Shimmer placement: correct
- Shimmer is shown only for the remote section (lines 155-172). Local section renders immediately without a shimmer. This is exactly right.

### One genuine issue: local provider return type verification needed
- The plan assumes `foodLocalSearchProvider` is synchronous. If it reads from an Isar query, confirm the provider returns `List<FoodSearchResult>` directly (not `Future<...>` or `AsyncValue<...>`). If it returns a Future, local results WILL have an async gap and need their own shimmer.
- This is a question to verify before shipping, not a confirmed bug.

### Missing haptic on food result tap (from post-impl audit)
- _FoodResultTile ListTile onTap (line 327) has no HapticFeedback call. Add lightImpact() before context.go().

---

## Change 5 — Macro Breakdown Colour Coding (Cronometer Style)

### Current implementation in NutritionSummaryCard is mostly correct
- `_macroColor` in daily_summary_header.dart (lines 97-115): primary = under 90%, secondary = 90-110%, error = over 110%. Logic is sound.
- TweenAnimationBuilder fills animate from 0 correctly (600ms easeOutCubic).
- Label row shows "Xg / Yg" — this is correct grams display.

### Missing percentage text: MAJOR gap for Cronometer parity
- The bar label row (lines 140-156 of _MacroProgressBar) shows "Xg / Yg" but NO percentage value.
- Cronometer style means showing the percentage alongside the grams. Without it, users must mentally calculate progress.
- Recommendation: add a percentage text to the right of the label:
  `'${consumed.toInt()}g / ${target.toInt()}g  (${(progress * 100).toInt()}%)'`
  Use labelSmall in onSurfaceVariant to keep it small, matching the pattern already used in micronutrient_section.dart lines 167-170.

### Colour semantics are ambiguous with Material 3 tokens
- colorScheme.primary (under target), colorScheme.secondary (on target), colorScheme.error (over target) — this is a custom semantic mapping that contradicts Material 3 intent.
- `secondary` in Material 3 is not conventionally "success" or "on target" — it is a complementary accent. Users familiar with Material 3 apps will not associate secondary with "you've hit your goal".
- More critically: both "under target" (primary) and "on target" (secondary) are positive states. The visual distinction between them depends entirely on colour, and primary/secondary can be very similar colours in some themes (especially with the planned dark-first emerald palette).
- Recommendation:
  1. Use colorScheme.tertiary or a hard-coded success green for "on target" to ensure it reads distinctly.
  2. Add a small icon or text label to the "at target" state (e.g., a checkmark icon alongside the bar) so the state is communicated beyond colour alone.
  3. Never use error colour for "slightly over on protein" — error should only appear for values meaningfully over target (>120% is a more appropriate threshold).

### Accessibility gap: no Semantics on progress bars
- _MacroProgressBar LinearProgressIndicator has no Semantics wrapper (from recurring_patterns.md and post-impl audit).
- Screen reader announces nothing useful for these bars.
- Fix: wrap each bar in `Semantics(label: 'Protein: ${consumed.toInt()} of ${target.toInt()} grams, ${(progress*100).toInt()}%')`.

---

## Change 6 — Full UI Design System Overhaul

### Dark-first palette with light mode parity — CRITICAL risk
- A "dark-first" palette designed around #00C853 (emerald) must still produce a functioning light theme.
- Material 3 colour system requires separate light and dark ColorScheme objects. Designing only the dark palette and "inverting" for light frequently produces unacceptable contrast ratios.
- Specific risk with #00C853: on a dark background (~#121212) this is WCAG AA compliant (contrast ~4.8:1). On a white background (#FFFFFF) the contrast ratio is ~3.4:1 — WCAG AA FAILS for body text.
- Mitigation: use a darker shade of emerald (~#00A846) as the primary colour in the light scheme. The dark scheme can use the lighter #00C853. Test both in Flutter's Material Theme Builder.
- Severity: CRITICAL — if light mode launches with sub-AA contrast, App Store reviewers and accessibility audits will flag it.

### Google Fonts async loading — FOUT risk: MAJOR
- Outfit and DM Sans via the google_fonts package load font files asynchronously at first launch.
- On first app open, Flutter renders text with the fallback system font (San Francisco / Roboto) for ~200-500ms, then reflows when the font loads. This is visible FOUT.
- Mitigation:
  1. Bundle the font files as local assets in pubspec.yaml rather than using google_fonts network loading.
  2. If google_fonts is used, call `GoogleFonts.config.allowRuntimeFetching = false` after pre-caching, and include fonts in the assets bundle.
  3. Pre-warm fonts in main() before runApp() using `FontLoader`.
- Severity: MAJOR — visible reflow on app launch is a quality signal to users.

### Glassmorphism effects — accessibility and performance: MAJOR
- BackdropFilter (blur) with low-opacity frosted containers fails in two ways:
  1. Text on a blurred/semi-transparent background frequently fails WCAG contrast ratio. The background changes dynamically based on what's behind the card, so contrast cannot be guaranteed statically.
  2. High-contrast mode on Android (and iOS Increase Contrast setting) disables translucency effects. The widget will fall back to a solid colour — design must degrade gracefully.
- Performance: BackdropFilter is expensive on the render tree. Using it on multiple stacked cards will drop frames on mid-range devices (particularly Android devices in the target demographic for fitness apps).
- Mitigation:
  1. Use glassmorphism sparingly — one or two accent cards maximum, never on lists.
  2. Ensure text within glass cards uses a text shadow or solid backdrop to guarantee contrast.
  3. Implement a `reduceTransparency` check using `MediaQuery.of(context).disableAnimations` or `AccessibilityFeatures` and fall back to opaque Card.filled.
- Severity: MAJOR.

### Screen entry animations — fatigue risk: MAJOR
- Fade + slide-up on every screen entry plays every time the user navigates. After the third session the animation actively slows the user down (adds perceived ~150-300ms to every navigation event).
- The worst case: if the animation is applied to the bottom nav tab switches (which happen dozens of times per session), users will feel the app is sluggish.
- Mitigation:
  1. Apply entry animations only to modal/push routes (food search, settings, workout detail), NOT to tab switches inside StatefulShellRoute.
  2. Cap animation duration at 200ms. Beyond 200ms, users perceive animation as lag, not polish.
  3. Respect `MediaQuery.of(context).disableAnimations` — if the user has reduced motion enabled, skip the animation entirely (zero duration).
- Severity: MAJOR if applied to tab switches. Minor if limited to push routes.

### Per-screen personality — coherence risk: MAJOR
- "Dashboard=premium, Nutrition=clinical, Workouts=energetic, AI Coach=conversational" creates four distinct visual languages in one app.
- This level of differentiation is only successful when each screen has very different content TYPE (e.g., games with different themes per level). For a fitness app where the same user sees all four screens in a 10-minute session, jarring tonal shifts destroy the sense of a unified product.
- The risk is not that it will "confuse" users cognitively — it is that it will feel unfinished or inconsistent, reducing trust in the app.
- Mitigation:
  1. Keep typography (Outfit/DM Sans) consistent across ALL screens. Typography is the strongest coherence signal.
  2. Keep the ColorScheme (emerald primary, error red, neutral surface) identical across all screens.
  3. Express "personality" only through illustration style, icon weight choice, and copy tone — NOT through different colour palettes or card shapes per screen.
  4. Maximum allowed per-screen variation: card elevation/shadow depth (premium = higher elevation) and copy tone. Nothing else.
- Severity: MAJOR — violates the principle of least surprise.

### Bottom nav redesign — pattern breakage risk: MINOR
- Five tabs with filled/outlined icon pairs is already a well-established pattern in this codebase (shell_screen.dart). Users will have built muscle memory for icon positions.
- Any redesign must preserve: same number of tabs, same order, same icons or immediately recognisable variants.
- The main risk is using a completely custom bottom nav widget instead of Material 3 NavigationBar — custom implementations frequently miss accessibility (focus management, semantic roles, keyboard navigation).
- Mitigation: keep Material 3 NavigationBar as the base widget. Apply custom styling via NavigationBarTheme rather than rebuilding from scratch.
- Severity: MINOR if icons and order are preserved; MAJOR if either changes.

---

## Current State Audit — Dashboard, AI Coach, Progress, Shell

### DashboardScreen (dashboard_screen.dart)

#### Issues
1. profile == null returns SizedBox.shrink() (line 39): If the profile query returns data: null (new install, no profile yet), the dashboard is a blank screen. This should never happen post-onboarding, but the silent fail is a bad fallback. Should redirect to onboarding or show an error state.
2. Settings icon (line 62) has no semanticLabel. `IconButton(icon: const Icon(Icons.settings_outlined))` — Icon needs `semanticLabel: 'Settings'`.
3. WaterTracker + and - buttons: Not reviewed here but flag for haptic check — increment/decrement should fire lightImpact or selectionClick.
4. No haptic on "Log Meal" and "Log Workout" FilledButton (lines 176-191). Both navigate to new screens — add lightImpact() in onPressed before the context.go() call.
5. AnimatedSwitcher wraps each section individually (5 separate switchers). This is fine architecturally but means each section independently transitions, which can feel visually noisy when multiple sections resolve at slightly different times. Consider a single AsyncValue.whenAll guard that shows DashboardSkeleton until ALL providers have first values.

#### Good
- DashboardSkeleton shimmer is used correctly.
- AnimatedSwitcher key ValueKey('ring-loading') / ValueKey('ring-loaded') ensures clean widget identity transitions.
- Streak, water, workout, calorie are all independently shimmer-guarded.

### AICoachScreen (ai_coach_screen.dart)

#### Issues
1. _EmptyState has no CTA button (lines 176-208). The empty state explains what the coach does but provides no prompt or example question. Users must know what to ask without any starter guidance. Add 2-3 suggestion chips below the description (e.g., "How was my week?", "What should I eat for protein?", "Review my last workout") — tapping a chip pre-fills the input bar.
2. _confirmClear (line 145): `FilledButton` for "Clear" fires no haptic. Since this is a destructive action (deletes all chat history), add HapticFeedback.heavyImpact() inside the onPressed handler. This is a known recurring pattern.
3. PopupMenuButton for "Clear History" (line 78): The menu item text "Clear History" gives no indication of permanence. Should read "Clear Chat History..." (with ellipsis convention indicating a confirmation follows).
4. Error is shown as SnackBar (lines 44-61). This is acceptable for transient errors, but if the AI service is persistently unavailable, a snackbar that auto-dismisses leaves no visible error state. The input bar remains enabled (isBusy is false when there's no streaming), so users can keep sending messages that will keep failing. Consider disabling the send button and showing an inline error banner when a persistent error is detected.
5. No semanticLabel on the smart_toy_outlined icon in the empty state (line 184). Also no semanticLabel on the PopupMenuButton.

#### Good
- TypingIndicator and streaming ChatBubble are distinct — users can see activity.
- Scroll-to-bottom on new messages/streaming updates is correctly implemented.
- Error message is user-friendly (passed as a string from the controller, not raw exception).

### ProgressScreen (progress_screen.dart)

#### Issues
1. StrengthChart and NutritionTrends are `const` widgets (lines 73 and 83) with no error or loading state visible from this screen. From the post-impl audit, both use silent `SizedBox.shrink()` error branches internally. The progress screen has no visibility into these failures.
2. ErrorCard on milestones (line 34) has no onRetry callback. `const ErrorCard(message: 'Could not load milestones.')` — ErrorCard supports onRetry but it is not wired up.
3. ErrorCard on weight (line 62) also has no onRetry callback. Same issue.
4. WeightEntryDialog is opened via showDialog (line 49-53) using the `_` context from the builder (not the screen's context). This is a minor anti-pattern — if the dialog needs to show a SnackBar, it cannot reach the Scaffold's SnackBar host. Pass `context` explicitly: `builder: (context) => const WeightEntryDialog()` uses the dialog context, which is correct for dialogs. This is fine as-is.
5. "Log Weight" button (line 48): FilledButton.tonalIcon has no haptic in onPressed. Add lightImpact() before showDialog.
6. StrengthChart has no title header like "Body Weight" and "Nutrition Trends" have. Inconsistent heading pattern — add a title row with a label above StrengthChart.
7. No screen-level empty state: if the user has no weight entries, no workout entries, and no nutrition logs, the progress screen shows shimmer-then-empty charts with no context. The top-level screen should detect a "new user" state and show a prompt: "Start logging workouts and meals to see your progress here."

#### Good
- ShimmerBox used correctly for both milestones and weight sections.
- WeightChart has its own internal empty state (not visible here but confirmed in codebase overview).

### ShellScreen (shell_screen.dart)

#### Issues
1. NavigationDestination icons have no explicit semanticLabel (lines 23-49). `Icon(Icons.dashboard_outlined)` — the label text ("Dashboard") is set on the NavigationDestination.label, which NavigationBar passes to semantics correctly. This is actually fine for NavigationBar specifically, as the label is the semantic label. Not a bug.
2. Five tabs is at the upper edge for bottom nav — Material 3 recommends 3-5 destinations. Five is acceptable but the "AI Coach" tab being last means it receives the fewest organic visits (Fitts's Law — last tab is hardest to reach on large phones, and users anchor on position 1-3). Consider moving AI Coach to position 2 or 3 to increase engagement.
3. HapticFeedback.selectionClick() on tab switch (line 17) — CORRECT, already implemented. Preserve this.

#### Good
- StatefulShellRoute.indexedStack preserves each branch's scroll position and widget state.
- Filled/outlined icon pairs (selectedIcon/icon) give clear active-state indication.

---

## Priority Summary for Implementation Teams

### Must-fix before shipping
1. Settings back: use context.pop() not context.go('/dashboard').
2. Dark palette light mode contrast: verify #00C853 meets WCAG AA in light scheme before finalising.
3. Day completion sheet: swipe-to-dismiss must mean cancel, not confirm.
4. Screen entry animations: must NOT apply to tab switches; must respect disableAnimations.

### Should-fix in same PR
5. Micronutrient always-visible: collapse default preserved; add haptic on expand; render zero bars as muted/subdued, not identical to tracked bars.
6. Macro bars: add percentage text; Semantics wrappers; consider tertiary for on-target colour.
7. AI Coach empty state: add suggestion chips.
8. Progress screen: wire onRetry to ErrorCard widgets; add haptics to Log Weight button.
9. Google Fonts: bundle locally, do not rely on runtime fetching.

### Defer to follow-up
10. Per-screen personality: limit to copy tone and icon weight; keep palette and typography unified.
11. Glassmorphism: use sparingly with reduceTransparency fallback; test contrast on every card.
12. Bottom nav position of AI Coach: consider moving to position 2-3 in a future navigation audit.
