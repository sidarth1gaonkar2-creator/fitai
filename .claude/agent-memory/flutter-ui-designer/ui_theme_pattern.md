---
name: UI Patterns - Theme
description: AppColors token palette, usage conventions, and light/dark approach for FitAI after UI overhaul
type: project
---

## Color Palette — AppColors (lib/core/theme/app_colors.dart)

Dark mode canonical tokens:
- `AppColors.darkBackground` (#1A1A1A) — Scaffold background
- `AppColors.darkSurface` (#242424) — Card/sheet surfaces
- `AppColors.darkSurfaceBorder` (white 12%) — Card outline borders
- `AppColors.darkSearchField` (#2E2E2E) — Search input background
- `AppColors.purple` (#7B5CF6) — Primary accent; hero card backgrounds, progress fills
- `AppColors.purpleLight` (#A78BFA) — Carbs macro bar; subtitle text (purpleLight used as darkTextSecondary)
- `AppColors.purpleDark` (#3D2FA0) — Icon containers (48x48 circles); streak card background
- `AppColors.lime` (#C8F135) — CTA buttons; selected calendar dates; water dots (filled); chevrons; FABs; workout dots; lime badge

Shared accents:
- `AppColors.error` (#EF4444) — Over-budget calorie ring; error states
- `AppColors.warning` (#F59E0B)
- `AppColors.success` (#22C55E)

Light mode: `lightBackground` #F5F5F5, `lightSurface` white, `lightPrimary` #6D4FE0, `lightCta` #8DB000.

## Semantic Usage Patterns

| Element | Token |
|---|---|
| Calorie ring normal | purple → purpleLight gradient |
| Calorie ring ≥80% | lime → lime 70% alpha gradient |
| Calorie ring ≥100% | error → error 60% alpha gradient |
| Macro bar — Protein | AppColors.purple |
| Macro bar — Carbs | AppColors.purpleLight |
| Macro bar — Fat | AppColors.lime |
| Macro bar track | AppColors.darkSurface |
| Icon circle containers | AppColors.purpleDark background, white icon |
| Hero cards (workout, etc.) | AppColors.purple background, white text |
| CTA / FAB / quick-action buttons | AppColors.lime background, Colors.black text |
| Streak card | AppColors.purpleDark container, lime fire icon, white text |
| Water dots filled | AppColors.lime |
| Water dots empty | white border, transparent |
| Calendar selected day | AppColors.lime circle, black text |
| Calendar today | AppColors.purple 20% alpha background |
| Calendar day headers | AppColors.purple |
| Calendar workout dot | AppColors.lime (black when day is selected) |
| Workout tile subtitle | AppColors.purpleLight |
| Workout tile chevron | AppColors.lime |
| Tab bar active pill | AppColors.lime fill, black text |
| Tab bar inactive | AppColors.purple border 50% alpha, purple text |

## Material 3 colorScheme tokens still in use
- `colorScheme.onSurface` / `onSurfaceVariant` — body text and secondary labels
- `colorScheme.surfaceContainerHighest` — shimmer base (in shimmer widgets only)
- `colorScheme.surfaceContainerLow` — shimmer highlight

**How to apply:** Use AppColors tokens for design-system-specific colors. Use colorScheme tokens for generic text/surface roles. Never hardcode hex values in widget files.
