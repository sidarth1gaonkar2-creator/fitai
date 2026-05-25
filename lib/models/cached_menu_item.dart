import 'package:isar/isar.dart';

part 'cached_menu_item.g.dart';

/// Persistent cache row for a Spoonacular menu-item search result. We hit a
/// daily quota on the free tier (≈ 150 calls), so caching ALL results means
/// repeated searches on the same restaurant cost nothing for a week.
///
/// Cache key strategy: [queryKey] is the lowercased "restaurant + space +
/// user query" string, indexed for O(log n) lookup. One row per item per
/// search, so a single "applebees burger" search produces ~20 rows that all
/// share the same queryKey. A 7-day TTL is enforced at read time via
/// [fetchedAt].
@collection
class CachedMenuItem {
  Id id = Isar.autoIncrement;

  /// Lowercased "restaurantName userQuery" — both joined with a single
  /// space, trimmed. Indexed for fast prefix matching when surfacing
  /// results.
  @Index(caseSensitive: false)
  late String queryKey;

  /// Restaurant the row belongs to. Used to dedupe across the catch-all
  /// "Other Restaurant" entry vs. the chain-specific entries.
  late String restaurantName;

  late String itemName;

  String? imageUrl;

  late double calories;
  late double protein;
  late double carbs;
  late double fat;

  double defaultServingSize = 100;
  String servingUnit = 'g';

  double? sodiumMg;
  double? fibre;

  /// Wall-clock fetched timestamp. Cache is honored for 7 days from this
  /// value; older rows are ignored and refreshed on the next online query.
  DateTime fetchedAt = DateTime.now();
}
