import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/utils/logger.dart';
import '../features/nutrition/domain/food_search_result.dart';
import '../models/enums.dart';

/// Thrown when Spoonacular returns 402 (payment required / daily quota
/// exhausted). Surfaced as a typed error so callers can show a graceful
/// "limit reached" message instead of an empty result list that looks
/// indistinguishable from a genuine miss.
class SpoonacularQuotaException implements Exception {
  const SpoonacularQuotaException(this.message);
  final String message;
  @override
  String toString() => 'SpoonacularQuotaException: $message';
}

/// Secondary nutrition lookup service. Used for:
///   * Branded packaged products (`/food/products/...`)
///   * Barcode fallback when OpenFoodFacts has no record
///   * Restaurant menu items not present in the hardcoded chain catalogue
///     (`/food/menuItems/...`)
///
/// The PRIMARY sources remain USDA (generic foods) and the hardcoded
/// restaurant builders. Treat Spoonacular as an enrichment layer with a
/// daily free-tier quota — every call costs against that quota, so all
/// methods are network-light, parameterised, and respond quickly to
/// auth/quota errors with empty results rather than throwing.
class SpoonacularService {
  SpoonacularService(this.apiKey);

  final String apiKey;
  static const _host = 'api.spoonacular.com';
  final _client = HttpClient();

  bool get _hasKey => apiKey.trim().isNotEmpty;

  /// `GET /food/menuItems/search` — restaurant menu items (e.g.
  /// "chipotle burrito"). Returns a list of result rows; detail nutrition
  /// is fetched via [getMenuItem] using each row's id.
  ///
  /// Throws [SpoonacularQuotaException] on HTTP 402 / 429 (daily quota
  /// exceeded or rate-limited at provider) so callers in the dedicated
  /// menu-item search UI can show a friendly limit message. Other
  /// callers (e.g. the merged USDA+Spoonacular food search) still wrap
  /// the call in `catchError` and will see an empty list as before.
  Future<List<FoodSearchResult>> searchMenuItems(String query) async {
    if (!_hasKey || query.trim().isEmpty) return const [];
    final uri = Uri.https(_host, '/food/menuItems/search', {
      'query': query,
      'apiKey': apiKey,
      'number': '20',
      'addMenuItemInformation': 'true',
    });
    return _searchEnvelope(
      uri,
      key: 'menuItems',
      parser: FoodSearchResult.fromSpoonacularMenuItem,
      logTag: 'menuItems',
      throwOnQuota: true,
    );
  }

  /// `GET /food/products/search` — branded grocery products (e.g.
  /// "protein bar"). Add UPC/barcode handling lives in [getProductByBarcode].
  Future<List<FoodSearchResult>> searchProducts(String query) async {
    if (!_hasKey || query.trim().isEmpty) return const [];
    final uri = Uri.https(_host, '/food/products/search', {
      'query': query,
      'apiKey': apiKey,
      'number': '20',
      'addProductInformation': 'true',
    });
    return _searchEnvelope(
      uri,
      key: 'products',
      parser: FoodSearchResult.fromSpoonacularProduct,
      logTag: 'products',
    );
  }

  /// `GET /food/ingredients/search` — raw ingredients (e.g. "chicken
  /// breast"). USDA covers this domain better but Spoonacular sometimes
  /// has prepared variants USDA lacks. Returns the rough search hits;
  /// per-100g nutrition has to be fetched from `/food/ingredients/{id}`
  /// to populate macros — kept out of scope for this initial drop.
  Future<List<FoodSearchResult>> searchIngredients(String query) async {
    if (!_hasKey || query.trim().isEmpty) return const [];
    final uri = Uri.https(_host, '/food/ingredients/search', {
      'query': query,
      'apiKey': apiKey,
      'number': '20',
    });
    final list = await _searchEnvelope(
      uri,
      key: 'results',
      parser: _parseIngredientStub,
      logTag: 'ingredients',
    );
    // The stubs above only have name + image; macros need a follow-up
    // GET. We drop any rows that came back without macros so callers
    // never receive a 0/0/0/0 ingredient.
    return list.where((r) => r.caloriesPer100g > 0).toList();
  }

  /// `GET /food/menuItems/{id}` — full nutrition for one menu item.
  Future<FoodSearchResult?> getMenuItem(int id) async {
    if (!_hasKey) return null;
    final uri =
        Uri.https(_host, '/food/menuItems/$id', {'apiKey': apiKey});
    final map = await _getJson(uri, logTag: 'menuItem/$id');
    if (map == null) return null;
    return FoodSearchResult.fromSpoonacularMenuItem(map);
  }

  /// `GET /food/products/{id}` — full nutrition for one branded product.
  Future<FoodSearchResult?> getProduct(int id) async {
    if (!_hasKey) return null;
    final uri =
        Uri.https(_host, '/food/products/$id', {'apiKey': apiKey});
    final map = await _getJson(uri, logTag: 'product/$id');
    if (map == null) return null;
    return FoodSearchResult.fromSpoonacularProduct(map);
  }

  /// `GET /food/products/upc/{upc}` — barcode lookup. Returns null on a
  /// miss or quota error so the caller can fall back to OpenFoodFacts.
  Future<FoodSearchResult?> getProductByBarcode(String upc) async {
    if (!_hasKey || upc.trim().isEmpty) return null;
    final uri =
        Uri.https(_host, '/food/products/upc/$upc', {'apiKey': apiKey});
    final map = await _getJson(uri, logTag: 'upc/$upc');
    if (map == null) return null;
    return FoodSearchResult.fromSpoonacularProduct({
      ...map,
      // Some responses don't include the upc field in the body but we
      // know it because we asked for it — set it so dedupe vs OFF works.
      'upc': map['upc'] ?? upc,
    });
  }

  // ───────────────────────────────────────────────────────────────────
  // Internals
  // ───────────────────────────────────────────────────────────────────

  Future<List<FoodSearchResult>> _searchEnvelope(
    Uri uri, {
    required String key,
    required FoodSearchResult Function(Map<String, dynamic>) parser,
    required String logTag,
    bool throwOnQuota = false,
  }) async {
    try {
      final request = await _client.getUrl(uri);
      request.headers.set('User-Agent', 'AtlasFit/1.0 (Flutter)');
      final response = await request.close();
      if (response.statusCode == 402 || response.statusCode == 429) {
        debugPrint('[Spoonacular] $logTag: '
            'quota/rate-limit error ${response.statusCode}');
        if (throwOnQuota) {
          throw SpoonacularQuotaException(
              'Daily quota exceeded (HTTP ${response.statusCode}).');
        }
        return const [];
      }
      if (response.statusCode == 401) {
        debugPrint('[Spoonacular] $logTag: auth error 401');
        return const [];
      }
      if (response.statusCode != 200) {
        dev.log('[Spoonacular] $logTag failed: ${response.statusCode}',
            name: 'AtlasFit.Spoonacular');
        return const [];
      }
      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      final list = json[key] as List<dynamic>? ?? const [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(parser)
          .where((r) => r.name != 'Unknown Item' && r.name != 'Unknown Product')
          .toList();
    } on SpoonacularQuotaException {
      rethrow;
    } catch (e, st) {
      AppLogger.error('Spoonacular $logTag threw', error: e, stack: st);
      return const [];
    }
  }

  Future<Map<String, dynamic>?> _getJson(
    Uri uri, {
    required String logTag,
  }) async {
    try {
      final request = await _client.getUrl(uri);
      request.headers.set('User-Agent', 'AtlasFit/1.0 (Flutter)');
      final response = await request.close();
      if (response.statusCode == 404) return null;
      if (response.statusCode == 401 || response.statusCode == 402) {
        debugPrint('[Spoonacular] $logTag: '
            'auth/quota error ${response.statusCode}');
        return null;
      }
      if (response.statusCode != 200) {
        dev.log('[Spoonacular] $logTag failed: ${response.statusCode}',
            name: 'AtlasFit.Spoonacular');
        return null;
      }
      final body = await response.transform(utf8.decoder).join();
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (e, st) {
      AppLogger.error('Spoonacular $logTag threw', error: e, stack: st);
      return null;
    }
  }

  /// Spoonacular's `/food/ingredients/search` returns rows with `id`, `name`,
  /// `image` only — no nutrition until you GET `/food/ingredients/{id}`.
  /// We return a stub-shaped FoodSearchResult that the caller drops
  /// (because `caloriesPer100g == 0`). Wire the detail follow-up later if
  /// you want this endpoint to surface usable results.
  static FoodSearchResult _parseIngredientStub(Map<String, dynamic> row) {
    final name = (row['name'] as String?) ?? 'Unknown';
    return FoodSearchResult(
      name: name.length > 80 ? '${name.substring(0, 80)}…' : name,
      caloriesPer100g: 0,
      proteinPer100g: 0,
      carbsPer100g: 0,
      fatPer100g: 0,
      source: FoodSource.spoonacular,
    );
  }
}
