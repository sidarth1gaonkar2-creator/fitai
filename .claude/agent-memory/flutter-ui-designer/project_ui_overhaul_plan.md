---
name: UI Design System — Current State
description: Post-Cupertino migration design system state; iOS-native black/white/blue palette, CupertinoApp.router, remaining Material widgets
type: project
---

## Current Design System (as of 2026-04-08 Cupertino migration)

The app was originally built with Material 3 and a purple/lime color scheme. It went through two major migrations:
1. Purple/lime Material 3 overhaul (phases 1-5)
2. Cupertino migration — replaced MaterialApp with CupertinoApp.router, adopted iOS-native black/white/blue palette

### App Entry
- `CupertinoApp.router` in `lib/app.dart`
- `Theme` wrapper in builder injects Material `ThemeData` for remaining Material widgets
- Theme mode controlled by `themeModeProvider` (defaults to dark)

### Design Language
- **Dark mode**: Pure black (#000000) background, #1C1C1E surfaces, iOS system blue (#0A84FF) accent, white text
- **Light mode**: iOS grouped background (#F2F2F7), white surfaces, iOS system blue (#007AFF) accent, black text
- Font: Poppins headings, League Spartan body

### Legacy Variable Names
The `AppColors` class retains old names (`purple`, `lime`, `purpleDark`, etc.) that now map to completely different colors. See `ui_theme_pattern.md` for the full mapping.

### Remaining Material Widgets (not yet converted to Cupertino)
See `audit_cupertino_migration_2026-04-08.md` in ux-review-specialist for the full list.

Key unconverted areas:
- AlertDialog/showDialog in complete_day_button, weight_entry_dialog
- FilledButton/ElevatedButton in several screens
- Card/ListTile throughout nutrition and workout screens
- TextField inputs (should be CupertinoTextField)
- showModalBottomSheet (Material) in template/exercise pickers
- ScaffoldMessenger.showSnackBar in 7+ locations

### Key UI Patterns Established
- **Tab toggle**: Container with border + two pill widgets, AnimatedContainer transitions
- **Bottom nav**: 6-tab custom bar (HIG max is 5), GestureDetector with haptics
- **Shimmer loading**: Custom ShimmerBox/ShimmerList/ShimmerCard system, no external package
- **Error handling**: ErrorCard widget with optional onRetry

**How to apply:** When building new UI, use `AppColors.of(context)` Palette API and Cupertino widgets. Reference the actual hex values, not the legacy variable names, when describing colors.
