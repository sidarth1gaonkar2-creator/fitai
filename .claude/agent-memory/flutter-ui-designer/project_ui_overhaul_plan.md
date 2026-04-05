---
name: UI Design System Overhaul Plan
description: Planned Fix 6 — dark-first emerald theme, Outfit+DM Sans fonts, per-screen redesign, AnimatedScreenEntry, icon audit
type: project
---

## Theme Changes
- Seed color: `Color(0xFF00C853)` (deep emerald, replaces `Color(0xFF4CAF50)`)
- Add `google_fonts` package to pubspec.yaml
- File to change: `lib/core/theme/app_theme.dart`

## Font Pairing
- Outfit Bold/SemiBold for headings (displayLarge→titleLarge)
- DM Sans Regular/Medium for body (bodyLarge→labelSmall)
- Applied via `GoogleFonts.outfitTextTheme()` + `GoogleFonts.dmSansTextTheme()` merge

## New Widget: AnimatedScreenEntry
- File: `lib/core/widgets/animated_screen_entry.dart`
- Fade + slide up: offset 24dp, 300ms, Curves.easeOutCubic
- Wrap every top-level screen body in this widget

## Per-Screen Plans
### Dashboard
- CalorieRing stays 200dp (already correct)
- Greeting: change "Hi, name!" to time-aware "Good morning/afternoon/evening, name!"
- StreakCounter: add pulse/glow animation when streak > 0 (AnimatedContainer scale)
- Quick action buttons: add icons that better describe actions

### Shell (Bottom Nav)
- No structural change needed; icons already use outlined/filled pair
- Consider replacing `Icons.dashboard_outlined` with `Icons.home_outlined` / `Icons.home`

### Workouts
- ExerciseCard: add muscle group color indicator on left border
- TemplateCard: already has difficulty color badge — no change needed

### Nutrition
- NutritionSummaryCard: add percentage to _MacroProgressBar label row
- MicronutrientSection: remove visibility guard

### AI Coach
- Add suggested prompt chips above ChatInputBar when messages list is empty
- Chips: "Review my macros", "Plan my week", "Help me recover faster"

### Progress
- WeightChart: increase gradient fill opacity for more visual weight
- MilestoneBadges: earned badges get a subtle scale(1.05) + shadow

## Icon Audit (replacements needed)
| Location | Current | Replace With |
|---|---|---|
| Dashboard AppBar settings | Icons.settings_outlined | Icons.manage_accounts_outlined |
| AI Coach empty state | Icons.smart_toy_outlined | Icons.psychology_outlined |
| AI Coach AppBar | (no icon) | Icons.psychology_outlined as leading |
| Workouts empty state | Icons.fitness_center_outlined | Icons.sports_gymnastics |
| Nutrition search empty | Icons.search | Icons.manage_search |
| Micronutrient section | Icons.science_outlined | Icons.biotech_outlined |
| Water tracker | Icons.water_drop_outlined | Icons.water_drop (filled when full) |
| Complete Day button | Icons.check_circle_outline | Icons.task_alt |
| Workout logging close | Icons.close | Icons.close (keep, it's a discard action) |
| Settings profile | Icons.chevron_right | Icons.edit_outlined |
