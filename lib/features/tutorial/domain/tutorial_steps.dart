import 'package:flutter/widgets.dart';

import 'tutorial_controller.dart';

/// GlobalKey registry — attach each key to the widget that the matching
/// tutorial step needs to highlight. Keep this map stable across hot reloads
/// (top-level final) so the keys are the same object the widgets bind to.
final Map<String, GlobalKey> tutorialKeys = {
  'calorie_ring': GlobalKey(debugLabel: 'tutorial:calorie_ring'),
  'macro_row': GlobalKey(debugLabel: 'tutorial:macro_row'),
  'workouts_tab': GlobalKey(debugLabel: 'tutorial:workouts_tab'),
  'workout_templates': GlobalKey(debugLabel: 'tutorial:workout_templates'),
  'nutrition_tab': GlobalKey(debugLabel: 'tutorial:nutrition_tab'),
  'add_food_button': GlobalKey(debugLabel: 'tutorial:add_food_button'),
  'barcode_scanner': GlobalKey(debugLabel: 'tutorial:barcode_scanner'),
  'restaurants_chip': GlobalKey(debugLabel: 'tutorial:restaurants_chip'),
  'meal_plans_section': GlobalKey(debugLabel: 'tutorial:meal_plans_section'),
  'progress_tab': GlobalKey(debugLabel: 'tutorial:progress_tab'),
  'community_tab': GlobalKey(debugLabel: 'tutorial:community_tab'),
  'settings_gear': GlobalKey(debugLabel: 'tutorial:settings_gear'),
};

/// Ordered tutorial sequence. Steps with a [TutorialStep.route] cause the
/// controller to navigate before showing the spotlight (the next frame is
/// awaited so the target widget has been laid out).
final List<TutorialStep> tutorialSteps = [
  TutorialStep(
    id: 'welcome',
    title: 'Welcome to AtlasFit!',
    description:
        "Let's take a quick tour. It'll only take a minute, and you can skip anytime.",
    targetKey: tutorialKeys['calorie_ring']!,
    shape: SpotlightShape.circle,
    route: '/dashboard',
  ),
  TutorialStep(
    id: 'calorie_ring',
    title: 'Your Daily Calories',
    description:
        "This ring tracks your calorie progress. It turns green when you're on track and red when you go over. Tap it to switch between consumed and net remaining views.",
    targetKey: tutorialKeys['calorie_ring']!,
    shape: SpotlightShape.circle,
  ),
  TutorialStep(
    id: 'macros',
    title: 'Macro Tracking',
    description:
        'Track protein, carbs, and fat. These bars fill up as you log food throughout the day.',
    targetKey: tutorialKeys['macro_row']!,
  ),
  TutorialStep(
    id: 'workouts',
    title: 'Log Workouts',
    description:
        "Tap the Workouts tab to start lifting. AtlasFit tracks sets, reps, weight, and PRs automatically as you go.",
    targetKey: tutorialKeys['workouts_tab']!,
    route: '/workouts',
  ),
  TutorialStep(
    id: 'workout_templates',
    title: 'Workout Templates',
    description:
        'Switch to the Templates tab for 20+ pre-built routines — push/pull/legs, full body, programs like 5/3/1. Or roll your own.',
    targetKey: tutorialKeys['workout_templates']!,
    route: '/workouts',
  ),
  TutorialStep(
    id: 'nutrition',
    title: 'Track Your Nutrition',
    description:
        "Head to Nutrition to log meals. Several ways to add food — we'll show you each one next.",
    targetKey: tutorialKeys['nutrition_tab']!,
    route: '/nutrition',
  ),
  TutorialStep(
    id: 'add_food',
    title: 'Search & Add Food',
    description:
        'Tap the search bar to look up any food from our 800,000+ database. Pick a serving size and it lands in your log.',
    targetKey: tutorialKeys['add_food_button']!,
  ),
  TutorialStep(
    id: 'barcode_scanner',
    title: 'Scan Barcodes',
    description:
        "Snap a barcode to log packaged foods in seconds — no typing. Works on most products you'll find in a supermarket.",
    targetKey: tutorialKeys['barcode_scanner']!,
  ),
  TutorialStep(
    id: 'restaurants',
    title: 'Restaurant Meal Builder',
    description:
        'Build your exact Chipotle bowl, Subway sandwich, or Starbucks drink ingredient by ingredient. Nutrition calculated automatically.',
    targetKey: tutorialKeys['restaurants_chip']!,
  ),
  TutorialStep(
    id: 'meal_plans',
    title: 'Custom Meal Plans',
    description:
        'Switch to Meal Plans to follow ready-made plans or design your own. Hit your targets without thinking about it day-to-day.',
    targetKey: tutorialKeys['meal_plans_section']!,
  ),
  TutorialStep(
    id: 'progress',
    title: 'Track Your Progress',
    description:
        'View strength curves, body weight trends, and personal records over time. See which muscle groups you train most.',
    targetKey: tutorialKeys['progress_tab']!,
    route: '/progress',
  ),
  TutorialStep(
    id: 'community',
    title: 'Join the Community',
    description:
        'Share workouts, challenge friends, climb the leaderboard. Earn coins for consistency and unlock new themes.',
    targetKey: tutorialKeys['community_tab']!,
    route: '/community',
  ),
  TutorialStep(
    id: 'settings',
    title: 'Customize Your Experience',
    description:
        "Connect Apple Health, tune notifications, and tweak your profile here. You're all set — go crush it.",
    targetKey: tutorialKeys['settings_gear']!,
    shape: SpotlightShape.circle,
    route: '/dashboard',
  ),
];
