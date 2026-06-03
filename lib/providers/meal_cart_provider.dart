import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One fully-composed restaurant item sitting in the in-memory meal cart.
///
/// Each cart item is itself a complete entry — a Chipotle bowl, a Dunkin'
/// latte, a breakfast sandwich — already summed from its components. The cart
/// gathers several of these so the whole order logs as one grouped meal.
class MealCartItem {
  const MealCartItem({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fibre,
    this.sodiumMg,
    required this.restaurantId,
    required this.restaurantName,
    this.restaurantEmoji,
  });

  /// Stable per-item id so the review sheet can delete a specific row even
  /// when two items share a name.
  final String id;
  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double? fibre;
  final double? sodiumMg;

  // Restaurant source (an item carries its origin so the cart can detect when
  // the user has wandered into a different restaurant).
  final String restaurantId;
  final String restaurantName;
  final String? restaurantEmoji;
}

/// Immutable snapshot of the cart plus the restaurant session that owns it.
class MealCartState {
  const MealCartState({this.items = const [], this.restaurantId});

  final List<MealCartItem> items;

  /// Which restaurant session owns the cart. Adding an item from a different
  /// restaurant starts a fresh cart (you can't mix a Dunkin' coffee with a
  /// Chipotle bowl in one grouped meal — and leaving a restaurant clears it).
  final String? restaurantId;

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
  int get count => items.length;

  double get totalCalories => items.fold(0, (s, i) => s + i.calories);
  double get totalProtein => items.fold(0, (s, i) => s + i.protein);
  double get totalCarbs => items.fold(0, (s, i) => s + i.carbs);
  double get totalFat => items.fold(0, (s, i) => s + i.fat);

  /// Summed fibre/sodium, but only when at least one item carried the value —
  /// otherwise null so the log doesn't write a misleading "0 g".
  double? get totalFibre {
    final withValue = items.where((i) => i.fibre != null);
    if (withValue.isEmpty) return null;
    return withValue.fold<double>(0, (s, i) => s + (i.fibre ?? 0));
  }

  double? get totalSodium {
    final withValue = items.where((i) => i.sodiumMg != null);
    if (withValue.isEmpty) return null;
    return withValue.fold<double>(0, (s, i) => s + (i.sodiumMg ?? 0));
  }
}

class MealCartNotifier extends StateNotifier<MealCartState> {
  MealCartNotifier() : super(const MealCartState());

  /// Monotonic counter for unique item ids within a session. Avoids relying
  /// on timestamps so two rapid taps never collide.
  int _seq = 0;

  /// Adds a configured item to the cart. If the cart currently belongs to a
  /// different restaurant, it is replaced (a meal cart can't span two chains).
  /// Returns the new item count.
  int addItem({
    required String name,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
    double? fibre,
    double? sodiumMg,
    required String restaurantId,
    required String restaurantName,
    String? restaurantEmoji,
  }) {
    final item = MealCartItem(
      id: 'cart-${_seq++}',
      name: name,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      fibre: fibre,
      sodiumMg: sodiumMg,
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      restaurantEmoji: restaurantEmoji,
    );
    final owner = state.restaurantId;
    if (owner != null && owner != restaurantId) {
      state = MealCartState(items: [item], restaurantId: restaurantId);
    } else {
      state = MealCartState(
        items: [...state.items, item],
        restaurantId: restaurantId,
      );
    }
    return state.count;
  }

  void remove(String id) {
    final next = state.items.where((i) => i.id != id).toList();
    state = MealCartState(
      items: next,
      restaurantId: next.isEmpty ? null : state.restaurantId,
    );
  }

  void clear() => state = const MealCartState();
}

/// Session-only meal cart for the restaurant builder. Not persisted — leaving
/// the restaurant (or logging the meal) clears it.
final mealCartProvider =
    StateNotifierProvider<MealCartNotifier, MealCartState>(
  (ref) => MealCartNotifier(),
);
