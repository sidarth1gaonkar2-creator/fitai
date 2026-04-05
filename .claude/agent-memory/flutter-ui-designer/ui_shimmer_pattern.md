---
name: UI Patterns - Shimmer
description: Custom shimmer loading skeleton system already built in core/widgets/shimmer_loading.dart
type: project
---

Location: lib/core/widgets/shimmer_loading.dart

Three widget classes:
- ShimmerBox(width, height, borderRadius): base animated shimmer rectangle. Uses a single AnimationController with a LinearGradient sweep. Colors derived from colorScheme.surfaceContainerHighest (base) and colorScheme.surfaceContainerLow (highlight) — fully theme-aware.
- ShimmerList(itemCount): column of avatar + two-line row skeletons.
- ShimmerCard(height): full-width card-shaped shimmer.

**No external shimmer package is used.** The system is custom and already functional.

Dashboard currently uses ShimmerBox (circular, 200x200) + ShimmerCard for loading states when userProfileProvider is loading. However, per-widget shimmer skeletons for nutritionAsync, workoutAsync, and streakAsync are NOT implemented — the dashboard uses valueOrNull fallbacks silently showing zeros instead.

**How to apply:** When planning or building shimmer states, always use the existing ShimmerBox/ShimmerCard/ShimmerList classes. Do not suggest adding a shimmer package.
