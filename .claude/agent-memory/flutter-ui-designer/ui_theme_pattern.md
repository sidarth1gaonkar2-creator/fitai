---
name: UI Patterns - Theme
description: Theme seed, token usage conventions, and light/dark approach for FitAI
type: project
---

Seed color: Color(0xFF4CAF50) — Material 3 green.
Both light and dark ThemeData use the same seed with useMaterial3: true.

InputDecorationTheme: OutlineInputBorder, contentPadding symmetric(horizontal:16, vertical:12).

Color tokens observed in use across widgets:
- colorScheme.primary — main accent (green-derived); used for progress fills, icons, active states
- colorScheme.primaryContainer / onPrimaryContainer — filled card backgrounds (StreakCounter, selected GoalCard)
- colorScheme.tertiary — carbs macro bar color
- colorScheme.secondary — fat macro bar color
- colorScheme.surfaceContainerHighest — track/background for progress indicators, shimmer base
- colorScheme.surfaceContainerLow — shimmer highlight color
- colorScheme.onSurface / onSurfaceVariant — body text and secondary labels

No custom ThemeExtension or additional color tokens are defined yet.

**How to apply:** Never hardcode colors. Map new UI elements to the token set above or introduce a ThemeExtension if semantic tokens are needed beyond the standard Material 3 set.
