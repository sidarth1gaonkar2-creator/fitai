import '../models/enums.dart';

class SupplementDefinition {
  const SupplementDefinition({
    required this.name,
    required this.dosage,
    required this.unit,
    required this.timing,
    this.category = '',
    this.benefits = const [],
    this.sideEffects = const [],
    this.foodSources = const [],
  });

  final String name;
  final String dosage;
  final String unit;
  final SupplementTiming timing;
  final String category;
  final List<String> benefits;
  final List<String> sideEffects;
  final List<String> foodSources;

  /// Short summary of the first 2 benefits.
  String get benefitsSummary {
    if (benefits.isEmpty) return '';
    return benefits.take(2).join(', ');
  }
}

/// Hardcoded English supplement library — the primary catalog source.
const List<SupplementDefinition> supplementLibrary = [
  // ── Supplements ─────────────────────────────────────────────────────────
  SupplementDefinition(
    name: 'Creatine Monohydrate',
    dosage: '5',
    unit: 'g',
    timing: SupplementTiming.morning,
    category: 'Performance',
    benefits: [
      'Increases maximal strength and power output',
      'Promotes lean muscle mass gain',
      'Improves high-intensity exercise capacity',
      'Enhances muscle recovery between sets',
    ],
    sideEffects: ['Water retention', 'Bloating at loading doses', 'Stomach cramps if not hydrated'],
    foodSources: ['Red meat', 'Salmon', 'Herring', 'Tuna'],
  ),
  SupplementDefinition(
    name: 'Whey Protein',
    dosage: '25',
    unit: 'g',
    timing: SupplementTiming.withMeal,
    category: 'Muscle Growth',
    benefits: [
      'Fast-absorbing complete protein source',
      'Stimulates muscle protein synthesis',
      'Supports post-workout recovery',
      'Helps meet daily protein targets conveniently',
    ],
    sideEffects: ['Bloating if lactose intolerant', 'Digestive discomfort at high doses'],
    foodSources: ['Dairy', 'Milk', 'Yogurt', 'Cheese'],
  ),
  SupplementDefinition(
    name: 'Vitamin D3',
    dosage: '2000',
    unit: 'IU',
    timing: SupplementTiming.morning,
    category: 'Health',
    benefits: [
      'Maintains bone density and calcium absorption',
      'Supports immune system function',
      'May reduce symptoms of depression',
      'Improves cardiovascular health markers',
    ],
    sideEffects: ['Nausea at very high doses', 'Hypercalcemia with chronic overdose'],
    foodSources: ['Sunlight exposure', 'Fatty fish', 'Egg yolks', 'Fortified milk'],
  ),
  SupplementDefinition(
    name: 'Fish Oil (Omega-3)',
    dosage: '1000',
    unit: 'mg',
    timing: SupplementTiming.withMeal,
    category: 'Health',
    benefits: [
      'Reduces inflammation and muscle soreness',
      'Supports heart and cardiovascular health',
      'Improves brain function and memory',
      'Boosts immune system response',
    ],
    sideEffects: ['Fishy aftertaste', 'Mild nausea', 'Blood thinning at high doses'],
    foodSources: ['Salmon', 'Mackerel', 'Sardines', 'Walnuts'],
  ),
  SupplementDefinition(
    name: 'Magnesium',
    dosage: '400',
    unit: 'mg',
    timing: SupplementTiming.beforeBed,
    category: 'Health',
    benefits: [
      'Regulates blood pressure levels',
      'Improves sleep quality and relaxation',
      'Supports muscle recovery and reduces cramps',
      'Aids energy production and nerve function',
    ],
    sideEffects: ['Diarrhea at high doses', 'Stomach cramps'],
    foodSources: ['Spinach', 'Almonds', 'Dark chocolate', 'Avocado'],
  ),
  SupplementDefinition(
    name: 'Zinc',
    dosage: '15',
    unit: 'mg',
    timing: SupplementTiming.evening,
    category: 'Health',
    benefits: [
      'Supports healthy testosterone levels',
      'Boosts immune defense and wound healing',
      'Aids protein synthesis and cell division',
      'Improves skin health',
    ],
    sideEffects: ['Nausea on empty stomach', 'Copper depletion at chronic high doses'],
    foodSources: ['Oysters', 'Beef', 'Pumpkin seeds', 'Lentils'],
  ),
  SupplementDefinition(
    name: 'Vitamin C',
    dosage: '500',
    unit: 'mg',
    timing: SupplementTiming.morning,
    category: 'Health',
    benefits: [
      'Powerful antioxidant protecting cells from damage',
      'Strengthens immune system',
      'Enhances iron absorption from food',
      'Supports collagen production for skin and joints',
    ],
    sideEffects: ['Stomach upset at very high doses', 'Diarrhea above 2000 mg'],
    foodSources: ['Citrus fruits', 'Bell peppers', 'Strawberries', 'Broccoli'],
  ),
  SupplementDefinition(
    name: 'Multivitamin',
    dosage: '1',
    unit: 'capsule',
    timing: SupplementTiming.morning,
    category: 'Health',
    benefits: [
      'Covers daily vitamin and mineral gaps',
      'Supports overall immune function',
      'Provides baseline micronutrient insurance',
      'Convenient all-in-one supplementation',
    ],
    sideEffects: ['Nausea if taken on empty stomach', 'May interact with other supplements'],
    foodSources: ['Varied whole-food diet'],
  ),
  SupplementDefinition(
    name: 'Caffeine',
    dosage: '200',
    unit: 'mg',
    timing: SupplementTiming.morning,
    category: 'Performance',
    benefits: [
      'Increases fat oxidation during exercise',
      'Improves focus, alertness, and reaction time',
      'Boosts endurance and time to exhaustion',
      'Enhances strength output',
    ],
    sideEffects: ['Insomnia if taken late', 'Jitters and anxiety', 'Tolerance buildup'],
    foodSources: ['Coffee', 'Green tea', 'Dark chocolate', 'Yerba mate'],
  ),
  SupplementDefinition(
    name: 'Melatonin',
    dosage: '3',
    unit: 'mg',
    timing: SupplementTiming.beforeBed,
    category: 'Health',
    benefits: [
      'Helps fall asleep faster',
      'Improves overall sleep quality',
      'Useful for jet lag and shift work adjustment',
      'Non-habit-forming sleep aid',
    ],
    sideEffects: ['Morning grogginess', 'Vivid dreams', 'Headache at high doses'],
    foodSources: ['Tart cherries', 'Walnuts', 'Warm milk', 'Bananas'],
  ),

  // ── Additional supplements ──────────────────────────────────────────────
  SupplementDefinition(
    name: 'Ashwagandha',
    dosage: '600',
    unit: 'mg',
    timing: SupplementTiming.evening,
    category: 'Adaptogen',
    benefits: [
      'Reduces cortisol and perceived stress',
      'Supports healthy testosterone levels',
      'Improves sleep quality and recovery',
      'May enhance endurance performance',
    ],
    sideEffects: ['Drowsiness', 'Mild GI upset', 'Not recommended during pregnancy'],
    foodSources: ['Ashwagandha root (herb)'],
  ),
  SupplementDefinition(
    name: 'Collagen Peptides',
    dosage: '10',
    unit: 'g',
    timing: SupplementTiming.morning,
    category: 'Recovery',
    benefits: [
      'Supports skin elasticity and hydration',
      'Promotes joint and tendon health',
      'Strengthens hair and nails',
      'May reduce exercise-related joint pain',
    ],
    sideEffects: ['Mild bloating', 'Aftertaste in unflavored forms'],
    foodSources: ['Bone broth', 'Chicken skin', 'Fish skin', 'Gelatin'],
  ),
  SupplementDefinition(
    name: 'BCAA',
    dosage: '10',
    unit: 'g',
    timing: SupplementTiming.morning,
    category: 'Performance',
    benefits: [
      'Reduces muscle soreness after training',
      'Supports muscle protein synthesis',
      'Decreases exercise-induced fatigue',
      'Useful during fasted training sessions',
    ],
    sideEffects: ['Nausea if taken in excess', 'May affect blood sugar'],
    foodSources: ['Chicken breast', 'Eggs', 'Beef', 'Greek yogurt'],
  ),
  SupplementDefinition(
    name: 'Citrulline Malate',
    dosage: '6',
    unit: 'g',
    timing: SupplementTiming.morning,
    category: 'Performance',
    benefits: [
      'Enhances muscle pump and blood flow',
      'Increases endurance and reduces fatigue',
      'Improves aerobic energy production',
      'Supports nitric oxide levels',
    ],
    sideEffects: ['Mild stomach discomfort', 'Heartburn at high doses'],
    foodSources: ['Watermelon', 'Cucumber', 'Pumpkin'],
  ),
  SupplementDefinition(
    name: 'Pre-Workout',
    dosage: '1',
    unit: 'scoop',
    timing: SupplementTiming.morning,
    category: 'Performance',
    benefits: [
      'Boosts energy and focus for training',
      'Increases strength and endurance output',
      'Enhances blood flow and muscle pump',
      'Contains combined performance ingredients',
    ],
    sideEffects: ['Tingling (beta-alanine)', 'Insomnia if taken late', 'Jitters from caffeine'],
    foodSources: ['N/A — supplement blend'],
  ),
  SupplementDefinition(
    name: 'Glutamine',
    dosage: '5',
    unit: 'g',
    timing: SupplementTiming.withMeal,
    category: 'Recovery',
    benefits: [
      'Supports gut lining and digestive health',
      'Aids immune function during heavy training',
      'Promotes tissue repair after injury',
      'May reduce muscle soreness',
    ],
    sideEffects: ['Bloating', 'Mild GI discomfort at high doses'],
    foodSources: ['Beef', 'Chicken', 'Fish', 'Eggs', 'Cabbage'],
  ),
  SupplementDefinition(
    name: 'Probiotics',
    dosage: '10',
    unit: 'billion CFU',
    timing: SupplementTiming.morning,
    category: 'Health',
    benefits: [
      'Balances gut microbiome for better digestion',
      'Strengthens immune system response',
      'May reduce bloating and IBS symptoms',
      'Supports nutrient absorption',
    ],
    sideEffects: ['Temporary gas or bloating', 'Mild digestive adjustment period'],
    foodSources: ['Yogurt', 'Kefir', 'Sauerkraut', 'Kimchi', 'Kombucha'],
  ),
  SupplementDefinition(
    name: 'Beta-Alanine',
    dosage: '3',
    unit: 'g',
    timing: SupplementTiming.morning,
    category: 'Performance',
    benefits: [
      'Buffers lactic acid for longer sets',
      'Increases muscular endurance',
      'Improves performance in 1-4 minute efforts',
      'Delays fatigue during high-rep training',
    ],
    sideEffects: ['Skin tingling (paraesthesia)', 'Flushing sensation'],
    foodSources: ['Chicken breast', 'Turkey', 'Fish'],
  ),
  SupplementDefinition(
    name: 'Iron',
    dosage: '18',
    unit: 'mg',
    timing: SupplementTiming.morning,
    category: 'Health',
    benefits: [
      'Prevents iron-deficiency anemia',
      'Supports oxygen transport in blood',
      'Maintains energy levels and reduces fatigue',
      'Essential for female athletes and vegetarians',
    ],
    sideEffects: ['Constipation', 'Stomach cramps', 'Nausea on empty stomach'],
    foodSources: ['Red meat', 'Spinach', 'Lentils', 'Fortified cereals'],
  ),
  SupplementDefinition(
    name: 'Electrolytes',
    dosage: '1',
    unit: 'serving',
    timing: SupplementTiming.withMeal,
    category: 'Hydration',
    benefits: [
      'Replaces sodium, potassium, and magnesium lost in sweat',
      'Prevents muscle cramps during exercise',
      'Maintains proper hydration balance',
      'Supports nerve and muscle function',
    ],
    sideEffects: ['Excess sodium if over-consumed', 'Mild bloating'],
    foodSources: ['Coconut water', 'Bananas', 'Pickles', 'Salt'],
  ),
];
