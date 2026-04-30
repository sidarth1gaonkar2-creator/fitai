/// A curated, solo-friendly challenge the user can start with one tap.
class PremadeChallenge {
  const PremadeChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.durationDays,
    required this.requiresPhotoProof,
    required this.proofInstructions,
    required this.icon,
    required this.difficulty,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final int durationDays;
  final bool requiresPhotoProof;
  final String proofInstructions;
  final String icon;
  final String difficulty; // Easy | Medium | Hard
}

const List<PremadeChallenge> premadeChallenges = [
  PremadeChallenge(
    id: 'homemade_meals_30',
    title: '30 Days of Home Cooking',
    description:
        'Cook and eat homemade meals for 30 days straight. No takeout, no restaurants. Photo proof required for each meal.',
    category: 'Nutrition',
    durationDays: 30,
    requiresPhotoProof: true,
    proofInstructions: 'Take a photo of your homemade meal before eating',
    icon: '🍳',
    difficulty: 'Medium',
  ),
  PremadeChallenge(
    id: 'workout_30',
    title: '30-Day Workout Streak',
    description:
        'Complete at least one workout every day for 30 days.',
    category: 'Fitness',
    durationDays: 30,
    requiresPhotoProof: false,
    proofInstructions: 'Log a workout in the app each day',
    icon: '💪',
    difficulty: 'Hard',
  ),
  PremadeChallenge(
    id: 'steps_10k_21',
    title: '21 Days of 10K Steps',
    description: 'Hit 10,000 steps every day for 21 days.',
    category: 'Cardio',
    durationDays: 21,
    requiresPhotoProof: false,
    proofInstructions: 'Screenshot your step count each day',
    icon: '🚶',
    difficulty: 'Medium',
  ),
  PremadeChallenge(
    id: 'no_sugar_14',
    title: '14-Day No Sugar Challenge',
    description:
        'Cut out all added sugars for 14 days. No sweets, no soda, no processed sugar.',
    category: 'Nutrition',
    durationDays: 14,
    requiresPhotoProof: true,
    proofInstructions: 'Photo your meals to show no sugar',
    icon: '🚫🍬',
    difficulty: 'Hard',
  ),
  PremadeChallenge(
    id: 'water_gallon_30',
    title: 'Gallon of Water Daily',
    description:
        'Drink a full gallon (3.8L) of water every day for 30 days.',
    category: 'Nutrition',
    durationDays: 30,
    requiresPhotoProof: false,
    proofInstructions: 'Log your water intake in the app',
    icon: '💧',
    difficulty: 'Easy',
  ),
  PremadeChallenge(
    id: 'pushup_100_30',
    title: '100 Push-ups a Day',
    description:
        'Complete 100 push-ups every day for 30 days. Split into sets however you like.',
    category: 'Fitness',
    durationDays: 30,
    requiresPhotoProof: false,
    proofInstructions: 'Log push-ups as a workout each day',
    icon: '🫸',
    difficulty: 'Hard',
  ),
  PremadeChallenge(
    id: 'sleep_8h_21',
    title: '21 Days of 8-Hour Sleep',
    description:
        'Get at least 8 hours of sleep every night for 21 days.',
    category: 'Recovery',
    durationDays: 21,
    requiresPhotoProof: true,
    proofInstructions: 'Screenshot your sleep tracker each morning',
    icon: '😴',
    difficulty: 'Medium',
  ),
  PremadeChallenge(
    id: 'protein_goal_14',
    title: '14 Days of Hitting Protein',
    description:
        'Hit your daily protein target every day for 14 days.',
    category: 'Nutrition',
    durationDays: 14,
    requiresPhotoProof: false,
    proofInstructions: 'Log all meals in the nutrition tracker',
    icon: '🥩',
    difficulty: 'Easy',
  ),
];

PremadeChallenge? premadeChallengeById(String id) {
  for (final c in premadeChallenges) {
    if (c.id == id) return c;
  }
  return null;
}

/// Maps premade category → challenge type used by the backend model.
String premadeTypeFromCategory(String category) {
  switch (category.toLowerCase()) {
    case 'nutrition':
      return 'nutrition';
    case 'fitness':
    case 'cardio':
      return 'workout';
    default:
      return 'habit';
  }
}
