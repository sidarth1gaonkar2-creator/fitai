enum Sex {
  male,
  female,
}

enum Goal {
  loseFat,
  buildMuscle,
  maintain,
}

enum ActivityLevel {
  sedentary,
  light,
  moderate,
  active,
  veryActive,
}

enum MuscleGroup {
  chest,
  upperBack,
  lats,
  shoulders,
  biceps,
  triceps,
  forearms,
  quads,
  hamstrings,
  glutes,
  calves,
  abs,
  obliques,
  cardio,
}

enum ExerciseEquipment {
  barbell,
  dumbbell,
  cable,
  machine,
  bodyweight,
  kettlebell,
  bands,
  cardioMachine,
  none,
}

enum ExerciseDifficulty {
  beginner,
  intermediate,
  advanced,
}

enum FoodSource {
  localDb,
  openFoodFacts,
  usda,
  spoonacular,
}

enum FoodCategory {
  eggs,
  dairy,
  meat,
  poultry,
  fish,
  grains,
  legumes,
  vegetables,
  fruits,
  nuts,
  oils,
  beverages,
  condiments,
  snacks,
  frozen,
  fastFood,
}

enum MealType {
  breakfast,
  lunch,
  dinner,
  snack,
}

enum MessageRole {
  user,
  assistant,
}

enum SupplementTiming {
  morning,
  afternoon,
  evening,
  withMeal,
  beforeBed,
}

extension SexLabel on Sex {
  String get label => switch (this) {
        Sex.male => 'Male',
        Sex.female => 'Female',
      };
}

extension GoalLabel on Goal {
  String get label => switch (this) {
        Goal.loseFat => 'Lose Fat',
        Goal.buildMuscle => 'Build Muscle',
        Goal.maintain => 'Maintain',
      };
}

extension ActivityLevelLabel on ActivityLevel {
  String get label => switch (this) {
        ActivityLevel.sedentary => 'Sedentary (little or no exercise)',
        ActivityLevel.light => 'Light (1-3 days/week)',
        ActivityLevel.moderate => 'Moderate (3-5 days/week)',
        ActivityLevel.active => 'Active (6-7 days/week)',
        ActivityLevel.veryActive => 'Very Active (twice/day)',
      };

  String get shortLabel => switch (this) {
        ActivityLevel.sedentary => 'Sedentary',
        ActivityLevel.light => 'Light',
        ActivityLevel.moderate => 'Moderate',
        ActivityLevel.active => 'Active',
        ActivityLevel.veryActive => 'Very Active',
      };

  String get description => switch (this) {
        ActivityLevel.sedentary => 'Little or no exercise',
        ActivityLevel.light => '1–3 days per week',
        ActivityLevel.moderate => '3–5 days per week',
        ActivityLevel.active => '6–7 days per week',
        ActivityLevel.veryActive => 'Twice per day',
      };

  double get multiplier => switch (this) {
        ActivityLevel.sedentary => 1.2,
        ActivityLevel.light => 1.375,
        ActivityLevel.moderate => 1.55,
        ActivityLevel.active => 1.725,
        ActivityLevel.veryActive => 1.9,
      };
}

extension MealTypeLabel on MealType {
  String get label => switch (this) {
        MealType.breakfast => 'Breakfast',
        MealType.lunch => 'Lunch',
        MealType.dinner => 'Dinner',
        MealType.snack => 'Snack',
      };
}

extension MuscleGroupLabel on MuscleGroup {
  String get label => switch (this) {
        MuscleGroup.chest => 'Chest',
        MuscleGroup.upperBack => 'Upper Back',
        MuscleGroup.lats => 'Lats',
        MuscleGroup.shoulders => 'Shoulders',
        MuscleGroup.biceps => 'Biceps',
        MuscleGroup.triceps => 'Triceps',
        MuscleGroup.forearms => 'Forearms',
        MuscleGroup.quads => 'Quads',
        MuscleGroup.hamstrings => 'Hamstrings',
        MuscleGroup.glutes => 'Glutes',
        MuscleGroup.calves => 'Calves',
        MuscleGroup.abs => 'Abs',
        MuscleGroup.obliques => 'Obliques',
        MuscleGroup.cardio => 'Cardio',
      };
}

extension ExerciseEquipmentLabel on ExerciseEquipment {
  String get label => switch (this) {
        ExerciseEquipment.barbell => 'Barbell',
        ExerciseEquipment.dumbbell => 'Dumbbell',
        ExerciseEquipment.cable => 'Cable',
        ExerciseEquipment.machine => 'Machine',
        ExerciseEquipment.bodyweight => 'Bodyweight',
        ExerciseEquipment.kettlebell => 'Kettlebell',
        ExerciseEquipment.bands => 'Bands',
        ExerciseEquipment.cardioMachine => 'Cardio Machine',
        ExerciseEquipment.none => 'None',
      };
}

extension ExerciseDifficultyExt on ExerciseDifficulty {
  String get label => switch (this) {
        ExerciseDifficulty.beginner => 'Beginner',
        ExerciseDifficulty.intermediate => 'Intermediate',
        ExerciseDifficulty.advanced => 'Advanced',
      };
}

extension FoodCategoryLabel on FoodCategory {
  String get label => switch (this) {
        FoodCategory.eggs => 'Eggs',
        FoodCategory.dairy => 'Dairy',
        FoodCategory.meat => 'Meat',
        FoodCategory.poultry => 'Poultry',
        FoodCategory.fish => 'Fish & Seafood',
        FoodCategory.grains => 'Grains',
        FoodCategory.legumes => 'Legumes',
        FoodCategory.vegetables => 'Vegetables',
        FoodCategory.fruits => 'Fruits',
        FoodCategory.nuts => 'Nuts & Seeds',
        FoodCategory.oils => 'Oils & Fats',
        FoodCategory.beverages => 'Beverages',
        FoodCategory.condiments => 'Condiments',
        FoodCategory.snacks => 'Snacks',
        FoodCategory.frozen => 'Frozen',
        FoodCategory.fastFood => 'Fast Food',
      };
}

extension SupplementTimingLabel on SupplementTiming {
  String get label => switch (this) {
        SupplementTiming.morning => 'Morning',
        SupplementTiming.afternoon => 'Afternoon',
        SupplementTiming.evening => 'Evening',
        SupplementTiming.withMeal => 'With Meal',
        SupplementTiming.beforeBed => 'Before Bed',
      };
}
