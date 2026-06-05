import '../features/community/domain/challenge.dart';

/// A curated, rank-focused challenge the user can start with one tap. Every
/// premade challenge now targets a strength rank objective rather than a daily
/// habit streak — earning rank is the point.
class PremadeChallenge {
  const PremadeChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.durationDays,
    required this.icon,
    required this.difficulty,
    required this.rankGoalType,
    this.targetRankIndex,
    this.goalExerciseId,
    this.goalExerciseLabel,
    this.targetWeightLbs,
    this.targetBodyweightMultiple,
    this.requiresPhotoProof = false,
    this.proofInstructions = '',
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

  final RankGoalType rankGoalType;
  final int? targetRankIndex;
  final String? goalExerciseId;
  final String? goalExerciseLabel;
  final double? targetWeightLbs;
  final double? targetBodyweightMultiple;
}

// MilitaryRank ordinals (kept inline so this data file has no widget deps):
//   PVT 0 · PFC 1 · CPL 2 · SPC 3 · SGT 4 · SSG 5 · SFC 6 · MSG 7 · SGM 8 · SMA 9
const List<PremadeChallenge> premadeChallenges = [
  PremadeChallenge(
    id: 'rank_earn_sergeant',
    title: 'Earn Sergeant',
    description:
        'Climb to Sergeant (E5) overall rank. Build a balanced base across '
        'every muscle group to pin on those stripes.',
    category: 'Rank',
    durationDays: 60,
    icon: '🎖️',
    difficulty: 'Hard',
    rankGoalType: RankGoalType.overallRank,
    targetRankIndex: 4,
  ),
  PremadeChallenge(
    id: 'rank_bench_corporal',
    title: 'Bench Press Corporal',
    description:
        'Reach Corporal rank on the barbell bench press. Drill the press '
        'until your bench earns its stripes.',
    category: 'Strength',
    durationDays: 30,
    icon: '🏋️',
    difficulty: 'Medium',
    rankGoalType: RankGoalType.exerciseRank,
    targetRankIndex: 2,
    goalExerciseId: 'barbell_bench_press',
    goalExerciseLabel: 'Bench',
  ),
  PremadeChallenge(
    id: 'rank_full_body_specialist',
    title: 'Full Body Specialist',
    description:
        'Reach Specialist rank in ALL six muscle groups. No weak links — '
        'chest, back, legs, shoulders, arms, and core.',
    category: 'Rank',
    durationDays: 90,
    icon: '🛡️',
    difficulty: 'Hard',
    rankGoalType: RankGoalType.allMuscleGroups,
    targetRankIndex: 3,
  ),
  PremadeChallenge(
    id: 'rank_100lb_club',
    title: '100 lb Club',
    description:
        'Bench press at least 100 lb. The first checkpoint on every '
        'recruit\'s strength ladder.',
    category: 'Strength',
    durationDays: 30,
    icon: '💯',
    difficulty: 'Easy',
    rankGoalType: RankGoalType.liftWeight,
    goalExerciseId: 'barbell_bench_press',
    goalExerciseLabel: 'Bench',
    targetWeightLbs: 100,
  ),
  PremadeChallenge(
    id: 'rank_2x_bw_squat',
    title: '2x Bodyweight Squat',
    description:
        'Back squat twice your bodyweight. A benchmark of serious lower-body '
        'strength.',
    category: 'Strength',
    durationDays: 60,
    icon: '🦵',
    difficulty: 'Hard',
    rankGoalType: RankGoalType.bodyweightMultiple,
    goalExerciseId: 'barbell_back_squat',
    goalExerciseLabel: 'Squat',
    targetBodyweightMultiple: 2.0,
  ),
  PremadeChallenge(
    id: 'rank_big3_1000',
    title: 'The Big 3: 1000 lb Total',
    description:
        'Combined bench + squat + deadlift of 1000 lb. Join the four-figure '
        'club.',
    category: 'Strength',
    durationDays: 90,
    icon: '🏅',
    difficulty: 'Hard',
    rankGoalType: RankGoalType.big3Total,
    targetWeightLbs: 1000,
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
    case 'rank':
    case 'strength':
      return 'workout';
    default:
      return 'habit';
  }
}
