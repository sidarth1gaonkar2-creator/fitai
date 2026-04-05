import 'dart:convert';
import 'dart:io';

import '../features/nutrition/domain/food_search_result.dart';

class OpenFoodFactsService {
  static const _baseUrl = 'world.openfoodfacts.org';
  final _client = HttpClient();

  /// Search foods by name. Returns up to 20 results.
  Future<List<FoodSearchResult>> search(String query) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.https(_baseUrl, '/cgi/search.pl', {
      'search_terms': query,
      'json': '1',
      'page_size': '20',
      'fields':
          'product_name,brands,image_front_small_url,nutriments,code',
    });

    final request = await _client.getUrl(uri);
    request.headers.set('User-Agent', 'FitAI/1.0 (Flutter)');
    final response = await request.close();

    if (response.statusCode != 200) return [];

    final body = await response.transform(utf8.decoder).join();
    final json = jsonDecode(body) as Map<String, dynamic>;
    final products = json['products'] as List<dynamic>? ?? [];

    return products
        .map((p) =>
            FoodSearchResult.fromOpenFoodFacts(p as Map<String, dynamic>))
        .where((r) => r.name != 'Unknown Product' || r.barcode != null)
        .toList();
  }

  /// Look up a single product by barcode.
  Future<FoodSearchResult?> getByBarcode(String barcode) async {
    if (barcode.trim().isEmpty) return null;

    final uri = Uri.https(
        _baseUrl, '/api/v0/product/$barcode.json', {
      'fields':
          'product_name,brands,image_front_small_url,nutriments,code',
    });

    final request = await _client.getUrl(uri);
    request.headers.set('User-Agent', 'FitAI/1.0 (Flutter)');
    final response = await request.close();

    if (response.statusCode != 200) return null;

    final body = await response.transform(utf8.decoder).join();
    final json = jsonDecode(body) as Map<String, dynamic>;

    if (json['status'] != 1) return null;

    final product = json['product'] as Map<String, dynamic>?;
    if (product == null) return null;

    return FoodSearchResult.fromOpenFoodFacts(product);
  }
}
