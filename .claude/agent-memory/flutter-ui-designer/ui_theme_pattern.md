---
name: UI Patterns - Theme
description: AppColors token palette (iOS-native black/white/blue), Palette system, usage conventions, and light/dark approach after Cupertino migration
type: project
---

## Architecture

App uses `CupertinoApp.router` (lib/app.dart) with a `Theme` wrapper that injects Material `ThemeData` for remaining Material widgets (Card, ListTile, Switch, TextField). Two systems coexist:
- `CupertinoThemeData` — primary, drives nav bars and Cupertino widgets
- `AppTheme.dark` / `AppTheme.light` (Material ThemeData) — injected via `builder:` for legacy Material widgets

## Color Palette — AppColors (lib/core/theme/app_colors.dart)

### Palette system (preferred API)
`AppColors.dark`, `AppColors.light`, and `AppColors.of(context)` return a `Palette` object:

| Palette field     | Dark value   | Light value  | Usage                          |
|-------------------|-------------|-------------|--------------------------------|
| `background`      | #000000     | #F2F2F7     | Scaffold background            |
| `surface`         | #1C1C1E     | #FFFFFF     | Card/sheet surfaces            |
| `surfaceElevated` | #2C2C2E     | #F2F2F7     | Elevated surfaces, search fields|
| `border`          | white 12%   | black 10%   | Card/container borders         |
| `separator`       | white 8%    | black 6%    | Thin dividers                  |
| `text`            | #FFFFFF     | #000000     | Primary text                   |
| `textSecondary`   | #8E8E93     | #8E8E93     | Secondary/subtitle text        |
| `accent`          | #0A84FF     | #007AFF     | iOS system blue; primary accent|
| `success`         | #32D74B     | #34C759     | Success states                 |
| `destructive`     | #FF453A     | #FF3B30     | Errors, over-budget, delete    |
| `warning`         | #FF9F0A     | #FF9500     | Warning states                 |

### Legacy aliases (still in code, point to dark palette values)

**WARNING:** Variable names are misleading — they are vestiges of the old purple/lime design.

| Legacy name          | Actual value | What it really is             |
|----------------------|-------------|-------------------------------|
| `AppColors.purple`   | #0A84FF     | iOS dark system blue (accent) |
| `AppColors.purpleLight`| #64B5FF   | Light blue variant            |
| `AppColors.purpleDark` | #0050A0   | Dark blue variant             |
| `AppColors.lime`     | #FFFFFF     | White (was lime green)        |
| `AppColors.darkBackground` | #000000 | Pure black                 |
| `AppColors.darkSurface`    | #1C1C1E | iOS dark surface            |
| `AppColors.darkSearchField` | #2C2C2E | Elevated surface           |
| `AppColors.darkSurfaceBorder`| white 12% | Subtle white border     |
| `AppColors.error`    | #FF453A     | iOS red                       |
| `AppColors.warning`  | #FF9F0A     | iOS orange                    |
| `AppColors.success`  | #32D74B     | iOS green                     |
| `AppColors.lightBackground` | #F2F2F7 | iOS grouped background     |
| `AppColors.lightSurface`    | #FFFFFF | White                       |
| `AppColors.lightPrimary`    | #007AFF | iOS light system blue       |
| `AppColors.lightCta`        | #007AFF | Same as lightPrimary        |
| `AppColors.bottomNavBar`    | #000000 | Pure black                  |

## Font Pairing
- **Poppins** Bold/SemiBold/Medium — headings, nav titles, CTAs
- **League Spartan** Regular/Medium — body text, labels, subtitles
- Both declared as asset fonts in pubspec.yaml (not google_fonts package)

## Material ThemeData mapping (AppTheme)
- `colorScheme.primary` = `AppColors.purple` (#0A84FF blue)
- `colorScheme.secondary` = `AppColors.lime` (#FFFFFF white)
- `colorScheme.tertiary` = `AppColors.purpleLight` (#64B5FF light blue)
- `colorScheme.error` = `AppColors.error` (#FF453A red)
- `filledButtonTheme` bg = `AppColors.lime` (white bg, black text)
- `appBarTheme` bg = `AppColors.purple` (#0A84FF blue)
- `cardTheme` = `AppColors.darkSurface` with `darkSurfaceBorder`

**How to apply:** Always use `AppColors.of(context)` Palette for new code. Be aware that legacy alias names are misleading. Never assume `AppColors.purple` is purple or `AppColors.lime` is lime — check the actual hex values.
