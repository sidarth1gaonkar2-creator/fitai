import '../models/enums.dart';

class MealPlanFood {
  const MealPlanFood({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.servingSize,
    this.servingUnit = 'g',
    this.ironMg = 0,
    this.calciumMg = 0,
    this.vitaminCMg = 0,
    this.vitaminDMcg = 0,
    this.magnesiumMg = 0,
    this.potassiumMg = 0,
    this.zincMg = 0,
    this.vitaminB12Mcg = 0,
    this.folateMcg = 0,
    this.sodiumMg = 0,
  });

  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double servingSize;
  final String servingUnit;
  final double ironMg;
  final double calciumMg;
  final double vitaminCMg;
  final double vitaminDMcg;
  final double magnesiumMg;
  final double potassiumMg;
  final double zincMg;
  final double vitaminB12Mcg;
  final double folateMcg;
  final double sodiumMg;
}

class MealPlanMeal {
  const MealPlanMeal({
    required this.type,
    required this.foods,
  });

  final MealType type;
  final List<MealPlanFood> foods;

  double get totalCalories => foods.fold(0, (s, f) => s + f.calories);
  double get totalProtein => foods.fold(0, (s, f) => s + f.protein);
  double get totalCarbs => foods.fold(0, (s, f) => s + f.carbs);
  double get totalFat => foods.fold(0, (s, f) => s + f.fat);
}

class CuratedMealPlan {
  const CuratedMealPlan({
    required this.id,
    required this.name,
    required this.goalDescription,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.meals,
  });

  final String id;
  final String name;
  final String goalDescription;
  final int totalCalories;
  final int totalProtein;
  final int totalCarbs;
  final int totalFat;
  final List<MealPlanMeal> meals;

  int get mealCount => meals.length;
}

const List<CuratedMealPlan> curatedMealPlans = [
  // 1. High Protein Bulk — 3000 kcal, 200g protein
  CuratedMealPlan(
    id: 'high_protein_bulk',
    name: 'High Protein Bulk',
    goalDescription: 'Build muscle with high calories and protein',
    totalCalories: 3000,
    totalProtein: 200,
    totalCarbs: 325,
    totalFat: 90,
    meals: [
      MealPlanMeal(type: MealType.breakfast, foods: [
        MealPlanFood(name: 'Oatmeal', calories: 300, protein: 10, carbs: 54, fat: 5, servingSize: 80, ironMg: 3.8, calciumMg: 43, vitaminCMg: 0, vitaminDMcg: 0, magnesiumMg: 142, potassiumMg: 343, zincMg: 3.2, vitaminB12Mcg: 0, folateMcg: 45, sodiumMg: 4),
        MealPlanFood(name: 'Whey Protein Shake', calories: 240, protein: 48, carbs: 6, fat: 2, servingSize: 60, ironMg: 1.0, calciumMg: 120, vitaminCMg: 0, vitaminDMcg: 0, magnesiumMg: 20, potassiumMg: 200, zincMg: 1.0, vitaminB12Mcg: 0.5, folateMcg: 0, sodiumMg: 100),
        MealPlanFood(name: 'Banana', calories: 105, protein: 1, carbs: 27, fat: 0, servingSize: 118, ironMg: 0.4, calciumMg: 6, vitaminCMg: 10.3, vitaminDMcg: 0, magnesiumMg: 32, potassiumMg: 422, zincMg: 0.2, vitaminB12Mcg: 0, folateMcg: 24, sodiumMg: 1),
      ]),
      MealPlanMeal(type: MealType.lunch, foods: [
        MealPlanFood(name: 'Chicken Breast', calories: 330, protein: 62, carbs: 0, fat: 7, servingSize: 200, ironMg: 1.0, calciumMg: 10, vitaminCMg: 0, vitaminDMcg: 0.2, magnesiumMg: 56, potassiumMg: 512, zincMg: 1.4, vitaminB12Mcg: 0.6, folateMcg: 8, sodiumMg: 148),
        MealPlanFood(name: 'Brown Rice', calories: 360, protein: 8, carbs: 76, fat: 3, servingSize: 280, ironMg: 1.1, calciumMg: 28, vitaminCMg: 0, vitaminDMcg: 0, magnesiumMg: 123, potassiumMg: 221, zincMg: 1.7, vitaminB12Mcg: 0, folateMcg: 11, sodiumMg: 6),
        MealPlanFood(name: 'Broccoli', calories: 55, protein: 4, carbs: 11, fat: 1, servingSize: 160, ironMg: 1.1, calciumMg: 75, vitaminCMg: 143, vitaminDMcg: 0, magnesiumMg: 34, potassiumMg: 506, zincMg: 0.6, vitaminB12Mcg: 0, folateMcg: 101, sodiumMg: 52),
      ]),
      MealPlanMeal(type: MealType.dinner, foods: [
        MealPlanFood(name: 'Salmon Fillet', calories: 410, protein: 40, carbs: 0, fat: 27, servingSize: 200, ironMg: 0.6, calciumMg: 24, vitaminCMg: 0, vitaminDMcg: 22.0, magnesiumMg: 58, potassiumMg: 726, zincMg: 0.8, vitaminB12Mcg: 6.4, folateMcg: 50, sodiumMg: 118),
        MealPlanFood(name: 'Sweet Potato', calories: 180, protein: 4, carbs: 41, fat: 0, servingSize: 200, ironMg: 1.2, calciumMg: 60, vitaminCMg: 4.8, vitaminDMcg: 0, magnesiumMg: 50, potassiumMg: 674, zincMg: 0.6, vitaminB12Mcg: 0, folateMcg: 22, sodiumMg: 72),
        MealPlanFood(name: 'Mixed Salad', calories: 50, protein: 2, carbs: 8, fat: 1, servingSize: 150, ironMg: 2.3, calciumMg: 90, vitaminCMg: 30, vitaminDMcg: 0, magnesiumMg: 45, potassiumMg: 450, zincMg: 0.5, vitaminB12Mcg: 0, folateMcg: 150, sodiumMg: 30),
      ]),
      MealPlanMeal(type: MealType.snack, foods: [
        MealPlanFood(name: 'Greek Yogurt', calories: 200, protein: 20, carbs: 8, fat: 11, servingSize: 200, ironMg: 0.2, calciumMg: 230, vitaminCMg: 0, vitaminDMcg: 0, magnesiumMg: 22, potassiumMg: 282, zincMg: 1.0, vitaminB12Mcg: 1.6, folateMcg: 14, sodiumMg: 80),
        MealPlanFood(name: 'Almonds', calories: 170, protein: 6, carbs: 6, fat: 15, servingSize: 28, ironMg: 1.0, calciumMg: 75, vitaminCMg: 0, vitaminDMcg: 0, magnesiumMg: 76, potassiumMg: 205, zincMg: 0.9, vitaminB12Mcg: 0, folateMcg: 12, sodiumMg: 0),
        MealPlanFood(name: 'Protein Bar', calories: 210, protein: 20, carbs: 24, fat: 8, servingSize: 60, ironMg: 2.5, calciumMg: 100, vitaminCMg: 0, vitaminDMcg: 0, magnesiumMg: 30, potassiumMg: 150, zincMg: 1.5, vitaminB12Mcg: 0.5, folateMcg: 20, sodiumMg: 180),
      ]),
    ],
  ),

  // 2. Fat Loss Cut — 1600 kcal, 150g protein
  CuratedMealPlan(
    id: 'fat_loss_cut',
    name: 'Fat Loss Cut',
    goalDescription: 'Lose fat while preserving muscle mass',
    totalCalories: 1600,
    totalProtein: 150,
    totalCarbs: 120,
    totalFat: 55,
    meals: [
      MealPlanMeal(type: MealType.breakfast, foods: [
        MealPlanFood(name: 'Egg Whites', calories: 100, protein: 22, carbs: 1, fat: 0, servingSize: 200, ironMg: 0.2, calciumMg: 14, vitaminCMg: 0, vitaminDMcg: 0, magnesiumMg: 22, potassiumMg: 326, zincMg: 0.06, vitaminB12Mcg: 0.2, folateMcg: 8, sodiumMg: 322),
        MealPlanFood(name: 'Whole Wheat Toast', calories: 130, protein: 5, carbs: 24, fat: 2, servingSize: 50, ironMg: 1.3, calciumMg: 54, vitaminCMg: 0, vitaminDMcg: 0, magnesiumMg: 38, potassiumMg: 125, zincMg: 0.9, vitaminB12Mcg: 0, folateMcg: 21, sodiumMg: 264),
        MealPlanFood(name: 'Avocado (quarter)', calories: 80, protein: 1, carbs: 4, fat: 7, servingSize: 50, ironMg: 0.3, calciumMg: 6, vitaminCMg: 5, vitaminDMcg: 0, magnesiumMg: 15, potassiumMg: 243, zincMg: 0.3, vitaminB12Mcg: 0, folateMcg: 41, sodiumMg: 4),
      ]),
      MealPlanMeal(type: MealType.lunch, foods: [
        MealPlanFood(name: 'Turkey Breast', calories: 220, protein: 42, carbs: 0, fat: 5, servingSize: 170, ironMg: 0.9, calciumMg: 14, vitaminCMg: 0, vitaminDMcg: 0.2, magnesiumMg: 46, potassiumMg: 459, zincMg: 2.0, vitaminB12Mcg: 0.7, folateMcg: 10, sodiumMg: 102),
        MealPlanFood(name: 'Quinoa', calories: 180, protein: 7, carbs: 32, fat: 3, servingSize: 150, ironMg: 2.3, calciumMg: 26, vitaminCMg: 0, vitaminDMcg: 0, magnesiumMg: 96, potassiumMg: 258, zincMg: 1.7, vitaminB12Mcg: 0, folateMcg: 63, sodiumMg: 11),
        MealPlanFood(name: 'Spinach Salad', calories: 40, protein: 3, carbs: 4, fat: 1, servingSize: 120, ironMg: 3.2, calciumMg: 119, vitaminCMg: 34, vitaminDMcg: 0, magnesiumMg: 95, potassiumMg: 670, zincMg: 0.6, vitaminB12Mcg: 0, folateMcg: 233, sodiumMg: 95),
      ]),
      MealPlanMeal(type: MealType.dinner, foods: [
        MealPlanFood(name: 'White Fish (Tilapia)', calories: 200, protein: 42, carbs: 0, fat: 4, servingSize: 200, ironMg: 1.2, calciumMg: 20, vitaminCMg: 0, vitaminDMcg: 6.2, magnesiumMg: 54, potassiumMg: 604, zincMg: 0.6, vitaminB12Mcg: 3.2, folateMcg: 48, sodiumMg: 106),
        MealPlanFood(name: 'Steamed Vegetables', calories: 70, protein: 3, carbs: 14, fat: 1, servingSize: 200, ironMg: 1.0, calciumMg: 50, vitaminCMg: 20, vitaminDMcg: 0, magnesiumMg: 30, potassiumMg: 350, zincMg: 0.5, vitaminB12Mcg: 0, folateMcg: 50, sodiumMg: 30),
        MealPlanFood(name: 'Brown Rice', calories: 130, protein: 3, carbs: 27, fat: 1, servingSize: 100, ironMg: 0.4, calciumMg: 10, vitaminCMg: 0, vitaminDMcg: 0, magnesiumMg: 44, potassiumMg: 79, zincMg: 0.6, vitaminB12Mcg: 0, folateMcg: 4, sodiumMg: 2),
      ]),
      MealPlanMeal(type: MealType.snack, foods: [
        MealPlanFood(name: 'Protein Shake', calories: 200, protein: 40, carbs: 4, fat: 2, servingSize: 50, ironMg: 2.0, calciumMg: 200, vitaminCMg: 0, vitaminDMcg: 0, magnesiumMg: 30, potassiumMg: 300, zincMg: 1.5, vitaminB12Mcg: 0.8, folateMcg: 10, sodiumMg: 150),
        MealPlanFood(name: 'Celery with Almond Butter', calories: 130, protein: 4, carbs: 6, fat: 11, servingSize: 40, ironMg: 0.5, calciumMg: 30, vitaminCMg: 1, vitaminDMcg: 0, magnesiumMg: 25, potassiumMg: 100, zincMg: 0.4, vitaminB12Mcg: 0, folateMcg: 10, sodiumMg: 50),
      ]),
    ],
  ),

  // 3. Balanced Maintenance — 2200 kcal, 130g protein
  CuratedMealPlan(
    id: 'balanced_maintenance',
    name: 'Balanced Maintenance',
    goalDescription: 'Maintain weight with balanced nutrition',
    totalCalories: 2200,
    totalProtein: 130,
    totalCarbs: 260,
    totalFat: 72,
    meals: [
      MealPlanMeal(type: MealType.breakfast, foods: [
        MealPlanFood(name: 'Greek Yogurt with Berries', calories: 200, protein: 18, carbs: 22, fat: 6, servingSize: 250, ironMg: 0.3, calciumMg: 288, vitaminCMg: 5, vitaminDMcg: 0, magnesiumMg: 28, potassiumMg: 352, zincMg: 1.3, vitaminB12Mcg: 2.0, folateMcg: 18, sodiumMg: 100),
        MealPlanFood(name: 'Granola', calories: 180, protein: 4, carbs: 30, fat: 6, servingSize: 40, ironMg: 1.4, calciumMg: 20, vitaminCMg: 0.3, vitaminDMcg: 0, magnesiumMg: 48, potassiumMg: 160, zincMg: 1.2, vitaminB12Mcg: 0, folateMcg: 22, sodiumMg: 20),
        MealPlanFood(name: 'Whole Wheat Toast with Honey', calories: 150, protein: 4, carbs: 28, fat: 2, servingSize: 50, ironMg: 1.3, calciumMg: 54, vitaminCMg: 0, vitaminDMcg: 0, magnesiumMg: 38, potassiumMg: 125, zincMg: 0.9, vitaminB12Mcg: 0, folateMcg: 21, sodiumMg: 264),
      ]),
      MealPlanMeal(type: MealType.lunch, foods: [
        MealPlanFood(name: 'Grilled Chicken Wrap', calories: 380, protein: 32, carbs: 38, fat: 12, servingSize: 250, ironMg: 2.0, calciumMg: 80, vitaminCMg: 3, vitaminDMcg: 0.1, magnesiumMg: 40, potassiumMg: 350, zincMg: 2.0, vitaminB12Mcg: 0.4, folateMcg: 30, sodiumMg: 600),
        MealPlanFood(name: 'Side Salad', calories: 60, protein: 2, carbs: 8, fat: 2, servingSize: 120, ironMg: 1.0, calciumMg: 40, vitaminCMg: 10, vitaminDMcg: 0, magnesiumMg: 15, potassiumMg: 200, zincMg: 0.3, vitaminB12Mcg: 0, folateMcg: 40, sodiumMg: 20),
        MealPlanFood(name: 'Apple', calories: 95, protein: 0, carbs: 25, fat: 0, servingSize: 180, ironMg: 0.2, calciumMg: 11, vitaminCMg: 8.3, vitaminDMcg: 0, magnesiumMg: 9, potassiumMg: 193, zincMg: 0.07, vitaminB12Mcg: 0, folateMcg: 5, sodiumMg: 2),
      ]),
      MealPlanMeal(type: MealType.dinner, foods: [
        MealPlanFood(name: 'Lean Beef Stir-Fry', calories: 350, protein: 35, carbs: 20, fat: 14, servingSize: 250, ironMg: 5.5, calciumMg: 30, vitaminCMg: 5, vitaminDMcg: 0.3, magnesiumMg: 53, potassiumMg: 825, zincMg: 11.5, vitaminB12Mcg: 6.5, folateMcg: 20, sodiumMg: 500),
        MealPlanFood(name: 'Jasmine Rice', calories: 240, protein: 5, carbs: 52, fat: 1, servingSize: 180, ironMg: 0.4, calciumMg: 18, vitaminCMg: 0, vitaminDMcg: 0, magnesiumMg: 22, potassiumMg: 63, zincMg: 0.9, vitaminB12Mcg: 0, folateMcg: 104, sodiumMg: 2),
        MealPlanFood(name: 'Steamed Broccoli', calories: 55, protein: 4, carbs: 11, fat: 1, servingSize: 160, ironMg: 1.1, calciumMg: 75, vitaminCMg: 143, vitaminDMcg: 0, magnesiumMg: 34, potassiumMg: 506, zincMg: 0.6, vitaminB12Mcg: 0, folateMcg: 101, sodiumMg: 52),
      ]),
      MealPlanMeal(type: MealType.snack, foods: [
        MealPlanFood(name: 'Trail Mix', calories: 200, protein: 6, carbs: 18, fat: 13, servingSize: 40, ironMg: 1.0, calciumMg: 32, vitaminCMg: 0.2, vitaminDMcg: 0, magnesiumMg: 52, potassiumMg: 200, zincMg: 1.0, vitaminB12Mcg: 0, folateMcg: 14, sodiumMg: 60),
        MealPlanFood(name: 'Cottage Cheese', calories: 160, protein: 22, carbs: 6, fat: 7, servingSize: 200, ironMg: 0.2, calciumMg: 166, vitaminCMg: 0, vitaminDMcg: 0, magnesiumMg: 16, potassiumMg: 208, zincMg: 0.8, vitaminB12Mcg: 0.8, folateMcg: 24, sodiumMg: 700),
      ]),
    ],
  ),

  // 4. Vegetarian High Protein — 2000 kcal, 120g protein
  CuratedMealPlan(
    id: 'vegetarian_high_protein',
    name: 'Vegetarian High Protein',
    goalDescription: 'Plant-based meals packed with protein',
    totalCalories: 2000,
    totalProtein: 120,
    totalCarbs: 230,
    totalFat: 65,
    meals: [
      MealPlanMeal(type: MealType.breakfast, foods: [
        MealPlanFood(name: 'Tofu Scramble', calories: 220, protein: 20, carbs: 8, fat: 12, servingSize: 200, ironMg: 10.8, calciumMg: 700, vitaminCMg: 0, vitaminDMcg: 0, magnesiumMg: 60, potassiumMg: 242, zincMg: 1.6, vitaminB12Mcg: 0, folateMcg: 30, sodiumMg: 14),
        MealPlanFood(name: 'Whole Grain Toast', calories: 130, protein: 5, carbs: 24, fat: 2, servingSize: 50, ironMg: 1.3, calciumMg: 54, vitaminCMg: 0, vitaminDMcg: 0, magnesiumMg: 38, potassiumMg: 125, zincMg: 0.9, vitaminB12Mcg: 0, folateMcg: 21, sodiumMg: 264),
        MealPlanFood(name: 'Orange Juice', calories: 110, protein: 2, carbs: 26, fat: 0, servingSize: 240, ironMg: 0.5, calciumMg: 27, vitaminCMg: 124, vitaminDMcg: 0, magnesiumMg: 27, potassiumMg: 496, zincMg: 0.1, vitaminB12Mcg: 0, folateMcg: 74, sodiumMg: 2),
      ]),
      MealPlanMeal(type: MealType.lunch, foods: [
        MealPlanFood(name: 'Lentil Soup', calories: 300, protein: 22, carbs: 40, fat: 6, servingSize: 350, ironMg: 11.6, calciumMg: 67, vitaminCMg: 5.3, vitaminDMcg: 0, magnesiumMg: 126, potassiumMg: 1292, zincMg: 4.6, vitaminB12Mcg: 0, folateMcg: 634, sodiumMg: 420),
        MealPlanFood(name: 'Hummus with Pita', calories: 250, protein: 8, carbs: 32, fat: 10, servingSize: 120, ironMg: 1.9, calciumMg: 46, vitaminCMg: 0, vitaminDMcg: 0, magnesiumMg: 35, potassiumMg: 208, zincMg: 1.3, vitaminB12Mcg: 0, folateMcg: 71, sodiumMg: 400),
      ]),
      MealPlanMeal(type: MealType.dinner, foods: [
        MealPlanFood(name: 'Chickpea Curry', calories: 350, protein: 18, carbs: 42, fat: 12, servingSize: 300, ironMg: 8.7, calciumMg: 147, vitaminCMg: 4, vitaminDMcg: 0, magnesiumMg: 144, potassiumMg: 873, zincMg: 4.5, vitaminB12Mcg: 0, folateMcg: 516, sodiumMg: 600),
        MealPlanFood(name: 'Basmati Rice', calories: 200, protein: 4, carbs: 44, fat: 1, servingSize: 150, ironMg: 0.3, calciumMg: 15, vitaminCMg: 0, vitaminDMcg: 0, magnesiumMg: 18, potassiumMg: 53, zincMg: 0.8, vitaminB12Mcg: 0, folateMcg: 87, sodiumMg: 1),
        MealPlanFood(name: 'Greek Salad', calories: 80, protein: 3, carbs: 6, fat: 5, servingSize: 150, ironMg: 0.5, calciumMg: 75, vitaminCMg: 8, vitaminDMcg: 0, magnesiumMg: 12, potassiumMg: 180, zincMg: 0.4, vitaminB12Mcg: 0.2, folateMcg: 20, sodiumMg: 350),
      ]),
      MealPlanMeal(type: MealType.snack, foods: [
        MealPlanFood(name: 'Edamame', calories: 180, protein: 18, carbs: 14, fat: 8, servingSize: 150, ironMg: 3.5, calciumMg: 95, vitaminCMg: 9.2, vitaminDMcg: 0, magnesiumMg: 96, potassiumMg: 654, zincMg: 2.1, vitaminB12Mcg: 0, folateMcg: 467, sodiumMg: 9),
        MealPlanFood(name: 'Peanut Butter on Rice Cakes', calories: 200, protein: 7, carbs: 20, fat: 11, servingSize: 50, ironMg: 0.9, calciumMg: 22, vitaminCMg: 0, vitaminDMcg: 0, magnesiumMg: 77, potassiumMg: 325, zincMg: 1.3, vitaminB12Mcg: 0, folateMcg: 44, sodiumMg: 150),
        MealPlanFood(name: 'Soy Milk', calories: 100, protein: 7, carbs: 8, fat: 4, servingSize: 240, ironMg: 1.0, calciumMg: 300, vitaminCMg: 0, vitaminDMcg: 2.7, magnesiumMg: 39, potassiumMg: 287, zincMg: 0.6, vitaminB12Mcg: 2.1, folateMcg: 22, sodiumMg: 91),
      ]),
    ],
  ),

  // 5. Keto Low Carb — 1800 kcal, 140g protein
  CuratedMealPlan(
    id: 'keto_low_carb',
    name: 'Keto Low Carb',
    goalDescription: 'High-fat, low-carb for ketosis',
    totalCalories: 1800,
    totalProtein: 140,
    totalCarbs: 30,
    totalFat: 130,
    meals: [
      MealPlanMeal(type: MealType.breakfast, foods: [
        MealPlanFood(name: 'Scrambled Eggs (3)', calories: 280, protein: 21, carbs: 2, fat: 21, servingSize: 180, ironMg: 3.2, calciumMg: 101, vitaminCMg: 0, vitaminDMcg: 3.6, magnesiumMg: 22, potassiumMg: 248, zincMg: 2.3, vitaminB12Mcg: 1.6, folateMcg: 85, sodiumMg: 450),
        MealPlanFood(name: 'Bacon (3 strips)', calories: 130, protein: 9, carbs: 0, fat: 10, servingSize: 40, ironMg: 0.4, calciumMg: 4, vitaminCMg: 0, vitaminDMcg: 0.2, magnesiumMg: 8, potassiumMg: 120, zincMg: 1.0, vitaminB12Mcg: 0.3, folateMcg: 1, sodiumMg: 600),
        MealPlanFood(name: 'Avocado Half', calories: 160, protein: 2, carbs: 4, fat: 15, servingSize: 100, ironMg: 0.6, calciumMg: 12, vitaminCMg: 10, vitaminDMcg: 0, magnesiumMg: 29, potassiumMg: 485, zincMg: 0.6, vitaminB12Mcg: 0, folateMcg: 81, sodiumMg: 7),
      ]),
      MealPlanMeal(type: MealType.lunch, foods: [
        MealPlanFood(name: 'Grilled Salmon', calories: 350, protein: 38, carbs: 0, fat: 22, servingSize: 180, ironMg: 0.5, calciumMg: 22, vitaminCMg: 0, vitaminDMcg: 19.8, magnesiumMg: 52, potassiumMg: 653, zincMg: 0.7, vitaminB12Mcg: 5.8, folateMcg: 45, sodiumMg: 106),
        MealPlanFood(name: 'Caesar Salad (no croutons)', calories: 150, protein: 5, carbs: 4, fat: 13, servingSize: 150, ironMg: 1.0, calciumMg: 50, vitaminCMg: 5, vitaminDMcg: 0, magnesiumMg: 15, potassiumMg: 200, zincMg: 0.3, vitaminB12Mcg: 0.1, folateMcg: 30, sodiumMg: 400),
      ]),
      MealPlanMeal(type: MealType.dinner, foods: [
        MealPlanFood(name: 'Ribeye Steak', calories: 380, protein: 40, carbs: 0, fat: 24, servingSize: 200, ironMg: 4.0, calciumMg: 14, vitaminCMg: 0, vitaminDMcg: 0.2, magnesiumMg: 44, potassiumMg: 630, zincMg: 8.8, vitaminB12Mcg: 5.2, folateMcg: 16, sodiumMg: 100),
        MealPlanFood(name: 'Sautéed Mushrooms', calories: 60, protein: 3, carbs: 4, fat: 4, servingSize: 120, ironMg: 0.6, calciumMg: 4, vitaminCMg: 2.5, vitaminDMcg: 8.4, magnesiumMg: 11, potassiumMg: 382, zincMg: 0.6, vitaminB12Mcg: 0, folateMcg: 20, sodiumMg: 5),
        MealPlanFood(name: 'Butter-Roasted Asparagus', calories: 80, protein: 3, carbs: 4, fat: 6, servingSize: 150, ironMg: 3.2, calciumMg: 36, vitaminCMg: 8.4, vitaminDMcg: 0, magnesiumMg: 21, potassiumMg: 303, zincMg: 0.8, vitaminB12Mcg: 0, folateMcg: 78, sodiumMg: 3),
      ]),
      MealPlanMeal(type: MealType.snack, foods: [
        MealPlanFood(name: 'Macadamia Nuts', calories: 200, protein: 2, carbs: 4, fat: 21, servingSize: 30, ironMg: 1.1, calciumMg: 26, vitaminCMg: 0.4, vitaminDMcg: 0, magnesiumMg: 39, potassiumMg: 110, zincMg: 0.4, vitaminB12Mcg: 0, folateMcg: 3, sodiumMg: 2),
        MealPlanFood(name: 'String Cheese (2)', calories: 160, protein: 14, carbs: 2, fat: 12, servingSize: 56, ironMg: 0.1, calciumMg: 280, vitaminCMg: 0, vitaminDMcg: 0.2, magnesiumMg: 16, potassiumMg: 50, zincMg: 1.6, vitaminB12Mcg: 0.5, folateMcg: 4, sodiumMg: 380),
      ]),
    ],
  ),

  // 6. Clean Eating — 2000 kcal, 120g protein
  CuratedMealPlan(
    id: 'clean_eating',
    name: 'Clean Eating',
    goalDescription: 'Whole foods, no processed ingredients',
    totalCalories: 2000,
    totalProtein: 120,
    totalCarbs: 240,
    totalFat: 60,
    meals: [
      MealPlanMeal(type: MealType.breakfast, foods: [
        MealPlanFood(name: 'Steel-Cut Oats', calories: 250, protein: 8, carbs: 44, fat: 5, servingSize: 70, ironMg: 3.3, calciumMg: 38, vitaminCMg: 0, vitaminDMcg: 0, magnesiumMg: 124, potassiumMg: 300, zincMg: 2.8, vitaminB12Mcg: 0, folateMcg: 39, sodiumMg: 4),
        MealPlanFood(name: 'Blueberries', calories: 80, protein: 1, carbs: 20, fat: 0, servingSize: 140, ironMg: 0.4, calciumMg: 8, vitaminCMg: 13.6, vitaminDMcg: 0, magnesiumMg: 8, potassiumMg: 108, zincMg: 0.2, vitaminB12Mcg: 0, folateMcg: 8, sodiumMg: 1),
        MealPlanFood(name: 'Hard-Boiled Eggs (2)', calories: 140, protein: 12, carbs: 1, fat: 10, servingSize: 100, ironMg: 1.8, calciumMg: 56, vitaminCMg: 0, vitaminDMcg: 2.0, magnesiumMg: 12, potassiumMg: 138, zincMg: 1.3, vitaminB12Mcg: 0.9, folateMcg: 47, sodiumMg: 248),
      ]),
      MealPlanMeal(type: MealType.lunch, foods: [
        MealPlanFood(name: 'Grilled Chicken Salad', calories: 350, protein: 35, carbs: 20, fat: 14, servingSize: 300, ironMg: 2.5, calciumMg: 60, vitaminCMg: 15, vitaminDMcg: 0.1, magnesiumMg: 50, potassiumMg: 500, zincMg: 2.0, vitaminB12Mcg: 0.3, folateMcg: 60, sodiumMg: 400),
        MealPlanFood(name: 'Sweet Potato Wedges', calories: 180, protein: 3, carbs: 40, fat: 1, servingSize: 200, ironMg: 1.2, calciumMg: 60, vitaminCMg: 4.8, vitaminDMcg: 0, magnesiumMg: 50, potassiumMg: 674, zincMg: 0.6, vitaminB12Mcg: 0, folateMcg: 22, sodiumMg: 72),
      ]),
      MealPlanMeal(type: MealType.dinner, foods: [
        MealPlanFood(name: 'Baked Cod', calories: 200, protein: 40, carbs: 0, fat: 3, servingSize: 200, ironMg: 0.8, calciumMg: 32, vitaminCMg: 0, vitaminDMcg: 1.8, magnesiumMg: 64, potassiumMg: 826, zincMg: 1.0, vitaminB12Mcg: 1.8, folateMcg: 14, sodiumMg: 140),
        MealPlanFood(name: 'Quinoa', calories: 180, protein: 7, carbs: 32, fat: 3, servingSize: 150, ironMg: 2.3, calciumMg: 26, vitaminCMg: 0, vitaminDMcg: 0, magnesiumMg: 96, potassiumMg: 258, zincMg: 1.7, vitaminB12Mcg: 0, folateMcg: 63, sodiumMg: 11),
        MealPlanFood(name: 'Roasted Vegetables', calories: 100, protein: 3, carbs: 18, fat: 3, servingSize: 200, ironMg: 1.0, calciumMg: 50, vitaminCMg: 20, vitaminDMcg: 0, magnesiumMg: 30, potassiumMg: 400, zincMg: 0.5, vitaminB12Mcg: 0, folateMcg: 50, sodiumMg: 30),
      ]),
      MealPlanMeal(type: MealType.snack, foods: [
        MealPlanFood(name: 'Apple with Almond Butter', calories: 250, protein: 6, carbs: 30, fat: 14, servingSize: 220, ironMg: 1.2, calciumMg: 81, vitaminCMg: 8, vitaminDMcg: 0, magnesiumMg: 81, potassiumMg: 412, zincMg: 0.9, vitaminB12Mcg: 0, folateMcg: 15, sodiumMg: 3),
        MealPlanFood(name: 'Walnuts', calories: 180, protein: 4, carbs: 4, fat: 18, servingSize: 28, ironMg: 0.8, calciumMg: 27, vitaminCMg: 0.4, vitaminDMcg: 0, magnesiumMg: 44, potassiumMg: 123, zincMg: 0.9, vitaminB12Mcg: 0, folateMcg: 27, sodiumMg: 1),
      ]),
    ],
  ),

  // 7. Athlete Performance — 3500 kcal, 220g protein
  CuratedMealPlan(
    id: 'athlete_performance',
    name: 'Athlete Performance',
    goalDescription: 'Fuel intense training and recovery',
    totalCalories: 3500,
    totalProtein: 220,
    totalCarbs: 420,
    totalFat: 95,
    meals: [
      MealPlanMeal(type: MealType.breakfast, foods: [
        MealPlanFood(name: 'Oatmeal with Protein Powder', calories: 450, protein: 38, carbs: 60, fat: 8, servingSize: 120, ironMg: 5.6, calciumMg: 163, vitaminCMg: 0, vitaminDMcg: 0, magnesiumMg: 162, potassiumMg: 543, zincMg: 4.2, vitaminB12Mcg: 0.5, folateMcg: 45, sodiumMg: 104),
        MealPlanFood(name: 'Banana', calories: 105, protein: 1, carbs: 27, fat: 0, servingSize: 118, ironMg: 0.4, calciumMg: 6, vitaminCMg: 10.3, vitaminDMcg: 0, magnesiumMg: 32, potassiumMg: 422, zincMg: 0.2, vitaminB12Mcg: 0, folateMcg: 24, sodiumMg: 1),
        MealPlanFood(name: 'Whole Eggs (3)', calories: 210, protein: 18, carbs: 1, fat: 15, servingSize: 150, ironMg: 2.7, calciumMg: 84, vitaminCMg: 0, vitaminDMcg: 3.0, magnesiumMg: 18, potassiumMg: 207, zincMg: 2.0, vitaminB12Mcg: 1.4, folateMcg: 71, sodiumMg: 213),
      ]),
      MealPlanMeal(type: MealType.lunch, foods: [
        MealPlanFood(name: 'Double Chicken Breast', calories: 460, protein: 86, carbs: 0, fat: 10, servingSize: 350, ironMg: 1.8, calciumMg: 18, vitaminCMg: 0, vitaminDMcg: 0.4, magnesiumMg: 98, potassiumMg: 896, zincMg: 2.5, vitaminB12Mcg: 1.1, folateMcg: 14, sodiumMg: 259),
        MealPlanFood(name: 'White Rice', calories: 390, protein: 8, carbs: 86, fat: 1, servingSize: 300, ironMg: 0.6, calciumMg: 30, vitaminCMg: 0, vitaminDMcg: 0, magnesiumMg: 36, potassiumMg: 105, zincMg: 1.5, vitaminB12Mcg: 0, folateMcg: 174, sodiumMg: 3),
        MealPlanFood(name: 'Mixed Vegetables', calories: 70, protein: 4, carbs: 14, fat: 1, servingSize: 200, ironMg: 1.0, calciumMg: 40, vitaminCMg: 10, vitaminDMcg: 0, magnesiumMg: 25, potassiumMg: 250, zincMg: 0.5, vitaminB12Mcg: 0, folateMcg: 40, sodiumMg: 40),
      ]),
      MealPlanMeal(type: MealType.dinner, foods: [
        MealPlanFood(name: 'Lean Ground Beef', calories: 400, protein: 44, carbs: 0, fat: 24, servingSize: 250, ironMg: 5.5, calciumMg: 30, vitaminCMg: 0, vitaminDMcg: 0.3, magnesiumMg: 53, potassiumMg: 825, zincMg: 11.5, vitaminB12Mcg: 6.3, folateMcg: 15, sodiumMg: 165),
        MealPlanFood(name: 'Pasta', calories: 350, protein: 12, carbs: 70, fat: 2, servingSize: 200, ironMg: 1.0, calciumMg: 14, vitaminCMg: 0, vitaminDMcg: 0, magnesiumMg: 36, potassiumMg: 88, zincMg: 1.0, vitaminB12Mcg: 0, folateMcg: 14, sodiumMg: 2),
        MealPlanFood(name: 'Tomato Sauce', calories: 60, protein: 2, carbs: 12, fat: 1, servingSize: 120, ironMg: 0.6, calciumMg: 18, vitaminCMg: 14, vitaminDMcg: 0, magnesiumMg: 14, potassiumMg: 378, zincMg: 0.2, vitaminB12Mcg: 0, folateMcg: 11, sodiumMg: 500),
      ]),
      MealPlanMeal(type: MealType.snack, foods: [
        MealPlanFood(name: 'Mass Gainer Shake', calories: 450, protein: 40, carbs: 60, fat: 8, servingSize: 100, ironMg: 5.0, calciumMg: 300, vitaminCMg: 15, vitaminDMcg: 2.5, magnesiumMg: 100, potassiumMg: 400, zincMg: 3.0, vitaminB12Mcg: 1.5, folateMcg: 100, sodiumMg: 200),
        MealPlanFood(name: 'PB&J Sandwich', calories: 400, protein: 12, carbs: 52, fat: 18, servingSize: 140, ironMg: 2.5, calciumMg: 70, vitaminCMg: 3, vitaminDMcg: 0, magnesiumMg: 65, potassiumMg: 300, zincMg: 1.5, vitaminB12Mcg: 0, folateMcg: 60, sodiumMg: 500),
        MealPlanFood(name: 'Greek Yogurt', calories: 150, protein: 15, carbs: 8, fat: 6, servingSize: 170, ironMg: 0.2, calciumMg: 196, vitaminCMg: 0, vitaminDMcg: 0, magnesiumMg: 19, potassiumMg: 240, zincMg: 0.9, vitaminB12Mcg: 1.4, folateMcg: 12, sodiumMg: 68),
      ]),
    ],
  ),

  // 8. Budget Friendly — 1800 kcal, 110g protein
  CuratedMealPlan(
    id: 'budget_friendly',
    name: 'Budget Friendly',
    goalDescription: 'Affordable meals that hit your macros',
    totalCalories: 1800,
    totalProtein: 110,
    totalCarbs: 220,
    totalFat: 55,
    meals: [
      MealPlanMeal(type: MealType.breakfast, foods: [
        MealPlanFood(name: 'Oatmeal with Milk', calories: 250, protein: 10, carbs: 42, fat: 5, servingSize: 80, ironMg: 3.8, calciumMg: 130, vitaminCMg: 0, vitaminDMcg: 0.5, magnesiumMg: 142, potassiumMg: 400, zincMg: 3.2, vitaminB12Mcg: 0.2, folateMcg: 45, sodiumMg: 50),
        MealPlanFood(name: 'Boiled Eggs (2)', calories: 140, protein: 12, carbs: 1, fat: 10, servingSize: 100, ironMg: 1.8, calciumMg: 56, vitaminCMg: 0, vitaminDMcg: 2.0, magnesiumMg: 12, potassiumMg: 138, zincMg: 1.3, vitaminB12Mcg: 0.9, folateMcg: 47, sodiumMg: 248),
      ]),
      MealPlanMeal(type: MealType.lunch, foods: [
        MealPlanFood(name: 'Rice and Beans', calories: 350, protein: 14, carbs: 62, fat: 4, servingSize: 300, ironMg: 4.5, calciumMg: 55, vitaminCMg: 1, vitaminDMcg: 0, magnesiumMg: 80, potassiumMg: 500, zincMg: 2.0, vitaminB12Mcg: 0, folateMcg: 180, sodiumMg: 400),
        MealPlanFood(name: 'Canned Tuna', calories: 180, protein: 36, carbs: 0, fat: 4, servingSize: 150, ironMg: 1.5, calciumMg: 17, vitaminCMg: 0, vitaminDMcg: 2.6, magnesiumMg: 41, potassiumMg: 311, zincMg: 0.9, vitaminB12Mcg: 3.2, folateMcg: 6, sodiumMg: 507),
        MealPlanFood(name: 'Frozen Mixed Veggies', calories: 60, protein: 3, carbs: 12, fat: 0, servingSize: 150, ironMg: 0.9, calciumMg: 38, vitaminCMg: 9, vitaminDMcg: 0, magnesiumMg: 26, potassiumMg: 263, zincMg: 0.6, vitaminB12Mcg: 0, folateMcg: 45, sodiumMg: 60),
      ]),
      MealPlanMeal(type: MealType.dinner, foods: [
        MealPlanFood(name: 'Chicken Thighs', calories: 300, protein: 28, carbs: 0, fat: 20, servingSize: 200, ironMg: 1.4, calciumMg: 16, vitaminCMg: 0, vitaminDMcg: 0.4, magnesiumMg: 46, potassiumMg: 444, zincMg: 3.0, vitaminB12Mcg: 0.8, folateMcg: 10, sodiumMg: 100),
        MealPlanFood(name: 'Baked Potato', calories: 160, protein: 4, carbs: 36, fat: 0, servingSize: 200, ironMg: 1.6, calciumMg: 24, vitaminCMg: 11.4, vitaminDMcg: 0, magnesiumMg: 46, potassiumMg: 842, zincMg: 0.6, vitaminB12Mcg: 0, folateMcg: 30, sodiumMg: 12),
        MealPlanFood(name: 'Cabbage Slaw', calories: 50, protein: 2, carbs: 10, fat: 1, servingSize: 120, ironMg: 0.6, calciumMg: 48, vitaminCMg: 44, vitaminDMcg: 0, magnesiumMg: 14, potassiumMg: 204, zincMg: 0.2, vitaminB12Mcg: 0, folateMcg: 52, sodiumMg: 22),
      ]),
      MealPlanMeal(type: MealType.snack, foods: [
        MealPlanFood(name: 'Peanut Butter on Bread', calories: 260, protein: 10, carbs: 26, fat: 14, servingSize: 70, ironMg: 1.5, calciumMg: 45, vitaminCMg: 0, vitaminDMcg: 0, magnesiumMg: 50, potassiumMg: 200, zincMg: 1.0, vitaminB12Mcg: 0, folateMcg: 40, sodiumMg: 300),
        MealPlanFood(name: 'Banana', calories: 105, protein: 1, carbs: 27, fat: 0, servingSize: 118, ironMg: 0.4, calciumMg: 6, vitaminCMg: 10.3, vitaminDMcg: 0, magnesiumMg: 32, potassiumMg: 422, zincMg: 0.2, vitaminB12Mcg: 0, folateMcg: 24, sodiumMg: 1),
      ]),
    ],
  ),

  // 9. Quick Prep — 2000 kcal, 125g protein
  CuratedMealPlan(
    id: 'quick_prep',
    name: 'Quick Prep',
    goalDescription: 'All meals ready in under 15 minutes',
    totalCalories: 2000,
    totalProtein: 125,
    totalCarbs: 230,
    totalFat: 65,
    meals: [
      MealPlanMeal(type: MealType.breakfast, foods: [
        MealPlanFood(name: 'Protein Smoothie', calories: 350, protein: 35, carbs: 40, fat: 6, servingSize: 400, ironMg: 2.0, calciumMg: 250, vitaminCMg: 30, vitaminDMcg: 1.0, magnesiumMg: 50, potassiumMg: 500, zincMg: 1.5, vitaminB12Mcg: 1.0, folateMcg: 30, sodiumMg: 150),
        MealPlanFood(name: 'Granola Bar', calories: 150, protein: 4, carbs: 24, fat: 5, servingSize: 40, ironMg: 1.4, calciumMg: 20, vitaminCMg: 0, vitaminDMcg: 0, magnesiumMg: 25, potassiumMg: 100, zincMg: 0.8, vitaminB12Mcg: 0, folateMcg: 15, sodiumMg: 120),
      ]),
      MealPlanMeal(type: MealType.lunch, foods: [
        MealPlanFood(name: 'Deli Turkey Wrap', calories: 350, protein: 30, carbs: 34, fat: 12, servingSize: 200, ironMg: 1.5, calciumMg: 60, vitaminCMg: 3, vitaminDMcg: 0.1, magnesiumMg: 30, potassiumMg: 300, zincMg: 1.5, vitaminB12Mcg: 0.5, folateMcg: 25, sodiumMg: 800),
        MealPlanFood(name: 'Baby Carrots with Hummus', calories: 150, protein: 5, carbs: 18, fat: 7, servingSize: 150, ironMg: 1.0, calciumMg: 45, vitaminCMg: 5, vitaminDMcg: 0, magnesiumMg: 20, potassiumMg: 350, zincMg: 0.5, vitaminB12Mcg: 0, folateMcg: 30, sodiumMg: 300),
      ]),
      MealPlanMeal(type: MealType.dinner, foods: [
        MealPlanFood(name: 'Pre-Cooked Rotisserie Chicken', calories: 300, protein: 35, carbs: 0, fat: 17, servingSize: 200, ironMg: 1.0, calciumMg: 12, vitaminCMg: 0, vitaminDMcg: 0.2, magnesiumMg: 44, potassiumMg: 400, zincMg: 2.0, vitaminB12Mcg: 0.6, folateMcg: 6, sodiumMg: 500),
        MealPlanFood(name: 'Microwaved Sweet Potato', calories: 180, protein: 4, carbs: 42, fat: 0, servingSize: 200, ironMg: 1.2, calciumMg: 60, vitaminCMg: 4.8, vitaminDMcg: 0, magnesiumMg: 50, potassiumMg: 674, zincMg: 0.6, vitaminB12Mcg: 0, folateMcg: 22, sodiumMg: 72),
        MealPlanFood(name: 'Bagged Salad Mix', calories: 50, protein: 2, carbs: 6, fat: 2, servingSize: 120, ironMg: 1.0, calciumMg: 40, vitaminCMg: 10, vitaminDMcg: 0, magnesiumMg: 15, potassiumMg: 200, zincMg: 0.3, vitaminB12Mcg: 0, folateMcg: 50, sodiumMg: 20),
      ]),
      MealPlanMeal(type: MealType.snack, foods: [
        MealPlanFood(name: 'Greek Yogurt', calories: 150, protein: 15, carbs: 8, fat: 6, servingSize: 170, ironMg: 0.2, calciumMg: 196, vitaminCMg: 0, vitaminDMcg: 0, magnesiumMg: 19, potassiumMg: 240, zincMg: 0.9, vitaminB12Mcg: 1.4, folateMcg: 12, sodiumMg: 68),
        MealPlanFood(name: 'Mixed Nuts', calories: 200, protein: 6, carbs: 8, fat: 18, servingSize: 30, ironMg: 0.9, calciumMg: 30, vitaminCMg: 0.2, vitaminDMcg: 0, magnesiumMg: 60, potassiumMg: 180, zincMg: 1.1, vitaminB12Mcg: 0, folateMcg: 12, sodiumMg: 2),
        MealPlanFood(name: 'Cheese Stick', calories: 80, protein: 7, carbs: 1, fat: 6, servingSize: 28, ironMg: 0.1, calciumMg: 140, vitaminCMg: 0, vitaminDMcg: 0.1, magnesiumMg: 8, potassiumMg: 25, zincMg: 0.8, vitaminB12Mcg: 0.3, folateMcg: 2, sodiumMg: 190),
      ]),
    ],
  ),

  // 10. Mediterranean — 2100 kcal, 115g protein
  CuratedMealPlan(
    id: 'mediterranean',
    name: 'Mediterranean',
    goalDescription: 'Heart-healthy Mediterranean-style eating',
    totalCalories: 2100,
    totalProtein: 115,
    totalCarbs: 240,
    totalFat: 75,
    meals: [
      MealPlanMeal(type: MealType.breakfast, foods: [
        MealPlanFood(name: 'Greek Yogurt with Honey', calories: 200, protein: 16, carbs: 24, fat: 6, servingSize: 220, ironMg: 0.2, calciumMg: 253, vitaminCMg: 0, vitaminDMcg: 0, magnesiumMg: 24, potassiumMg: 310, zincMg: 1.1, vitaminB12Mcg: 1.8, folateMcg: 15, sodiumMg: 88),
        MealPlanFood(name: 'Whole Grain Pita', calories: 170, protein: 6, carbs: 33, fat: 2, servingSize: 60, ironMg: 1.4, calciumMg: 10, vitaminCMg: 0, vitaminDMcg: 0, magnesiumMg: 22, potassiumMg: 72, zincMg: 0.5, vitaminB12Mcg: 0, folateMcg: 16, sodiumMg: 322),
        MealPlanFood(name: 'Feta Cheese', calories: 100, protein: 6, carbs: 2, fat: 8, servingSize: 40, ironMg: 0.3, calciumMg: 196, vitaminCMg: 0, vitaminDMcg: 0.2, magnesiumMg: 8, potassiumMg: 24, zincMg: 1.1, vitaminB12Mcg: 0.7, folateMcg: 13, sodiumMg: 504),
      ]),
      MealPlanMeal(type: MealType.lunch, foods: [
        MealPlanFood(name: 'Grilled Fish', calories: 250, protein: 35, carbs: 0, fat: 12, servingSize: 200, ironMg: 0.6, calciumMg: 20, vitaminCMg: 0, vitaminDMcg: 6, magnesiumMg: 50, potassiumMg: 500, zincMg: 0.6, vitaminB12Mcg: 2.0, folateMcg: 20, sodiumMg: 100),
        MealPlanFood(name: 'Tabbouleh', calories: 180, protein: 4, carbs: 28, fat: 7, servingSize: 150, ironMg: 1.5, calciumMg: 20, vitaminCMg: 8, vitaminDMcg: 0, magnesiumMg: 25, potassiumMg: 200, zincMg: 0.5, vitaminB12Mcg: 0, folateMcg: 30, sodiumMg: 300),
        MealPlanFood(name: 'Olive Oil Drizzle', calories: 120, protein: 0, carbs: 0, fat: 14, servingSize: 14, ironMg: 0.1, calciumMg: 0, vitaminCMg: 0, vitaminDMcg: 0, magnesiumMg: 0, potassiumMg: 0, zincMg: 0, vitaminB12Mcg: 0, folateMcg: 0, sodiumMg: 0),
      ]),
      MealPlanMeal(type: MealType.dinner, foods: [
        MealPlanFood(name: 'Lamb Kebab', calories: 320, protein: 30, carbs: 4, fat: 20, servingSize: 180, ironMg: 2.9, calciumMg: 22, vitaminCMg: 0, vitaminDMcg: 0.2, magnesiumMg: 41, potassiumMg: 558, zincMg: 6.1, vitaminB12Mcg: 4.1, folateMcg: 32, sodiumMg: 120),
        MealPlanFood(name: 'Couscous', calories: 220, protein: 8, carbs: 42, fat: 1, servingSize: 180, ironMg: 0.5, calciumMg: 14, vitaminCMg: 0, vitaminDMcg: 0, magnesiumMg: 14, potassiumMg: 90, zincMg: 0.4, vitaminB12Mcg: 0, folateMcg: 15, sodiumMg: 7),
        MealPlanFood(name: 'Roasted Eggplant', calories: 80, protein: 2, carbs: 12, fat: 3, servingSize: 150, ironMg: 0.4, calciumMg: 9, vitaminCMg: 2.2, vitaminDMcg: 0, magnesiumMg: 17, potassiumMg: 230, zincMg: 0.2, vitaminB12Mcg: 0, folateMcg: 22, sodiumMg: 2),
      ]),
      MealPlanMeal(type: MealType.snack, foods: [
        MealPlanFood(name: 'Hummus with Veggies', calories: 180, protein: 6, carbs: 18, fat: 10, servingSize: 150, ironMg: 1.5, calciumMg: 40, vitaminCMg: 5, vitaminDMcg: 0, magnesiumMg: 30, potassiumMg: 250, zincMg: 1.0, vitaminB12Mcg: 0, folateMcg: 50, sodiumMg: 350),
        MealPlanFood(name: 'Dates (3)', calories: 200, protein: 2, carbs: 52, fat: 0, servingSize: 60, ironMg: 0.5, calciumMg: 23, vitaminCMg: 0, vitaminDMcg: 0, magnesiumMg: 26, potassiumMg: 404, zincMg: 0.2, vitaminB12Mcg: 0, folateMcg: 11, sodiumMg: 1),
        MealPlanFood(name: 'Pistachios', calories: 160, protein: 6, carbs: 8, fat: 13, servingSize: 28, ironMg: 1.1, calciumMg: 29, vitaminCMg: 1.6, vitaminDMcg: 0, magnesiumMg: 34, potassiumMg: 287, zincMg: 0.6, vitaminB12Mcg: 0, folateMcg: 14, sodiumMg: 0),
      ]),
    ],
  ),
];
