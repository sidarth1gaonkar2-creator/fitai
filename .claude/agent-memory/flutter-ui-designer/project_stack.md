---
name: Project Stack
description: FitAI tech stack, key package versions, and architecture constraints
type: project
---

Packages in pubspec.yaml (as of 2026-04-05):
- flutter_riverpod: ^2.6.1
- isar: ^3.1.0+1 + isar_flutter_libs + isar_generator
- go_router: ^14.8.1
- fl_chart: ^0.70.2
- mobile_scanner: ^6.0.2
- flutter_dotenv: ^5.2.1
- path_provider: ^2.1.5

**Why:** Isar v3 codegen conflicts with modern build_runner-based codegen (like Riverpod's @riverpod). As a result, all Riverpod providers are written manually.

**How to apply:** Never suggest @riverpod annotations or code-generated providers. All providers must be manually declared using Provider, FutureProvider, StateProvider, StateNotifierProvider, etc.

No animation packages (e.g., lottie, rive) are currently installed. No SVG package (flutter_svg) is installed. The shimmer system is custom-built — no shimmer package installed.

Theme seed color: Color(0xFF4CAF50) — a green. Material 3 dynamic color scheme derived from this seed for both light and dark modes.

Assets directory: assets/ — currently only assets/.env is declared.
