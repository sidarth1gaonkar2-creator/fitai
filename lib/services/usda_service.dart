import 'dart:convert';
import 'dart:io';

import '../features/nutrition/domain/food_search_result.dart';

class UsdaService {
  UsdaService(this.apiKey);

  final String apiKey;
  static const _baseUrl = 'api.nal.usda.gov';
  final _client = HttpClient();

  /// Search foods by query. Returns up to 20 results.
  Future<List<FoodSearchResult>> search(String query) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.https(_baseUrl, '/fdc/v1/foods/search', {
      'query': query,
      'api_key': apiKey,
      'pageSize': '20',
    });

    final request = await _client.getUrl(uri);
    request.headers.set('User-Agent', 'FitAI/1.0 (Flutter)');
    final response = await request.close();

    if (response.statusCode != 200) return [];

    final body = await response.transform(utf8.decoder).join();
    final json = jsonDecode(body) as Map<String, dynamic>;
    final foods = json['foods'] as List<dynamic>? ?? [];

    return foods
        .map((f) => FoodSearchResult.fromUsda(f as Map<String, dynamic>))
        .where((r) => r.name != 'Unknown Food')
        .toList();
  }

  /// Fetch full nutrient detail for a single food by FDC ID.
  Future<FoodSearchResult?> getFoodDetail(int fdcId) async {
    final uri = Uri.https(_baseUrl, '/fdc/v1/food/$fdcId', {
      'api_key': apiKey,
    });

    final request = await _client.getUrl(uri);
    request.headers.set('User-Agent', 'FitAI/1.0 (Flutter)');
    final response = await request.close();

    if (response.statusCode != 200) return null;

    final body = await response.transform(utf8.decoder).join();
    final json = jsonDecode(body) as Map<String, dynamic>;

    return FoodSearchResult.fromUsda(json);
  }
}
