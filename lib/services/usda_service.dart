import 'dart:convert';
import 'dart:developer' as dev;
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

    // Debug: dump every non-zero nutrient on the first hit so we can see
    // exactly which IDs USDA returned for this query. Helps diagnose
    // missing-micros bugs (e.g. iron/calcium showing as 0 in totals).
    if (foods.isNotEmpty) {
      final first = foods[0] as Map<String, dynamic>;
      final nutrients = first['foodNutrients'] as List<dynamic>? ?? [];
      final lines = <String>[];
      for (final raw in nutrients) {
        final n = raw as Map<String, dynamic>;
        final id = n['nutrientId'] ??
            (n['nutrient'] is Map ? (n['nutrient'] as Map)['id'] : null);
        final number = n['nutrientNumber'] ??
            (n['nutrient'] is Map ? (n['nutrient'] as Map)['number'] : null);
        final name = n['nutrientName'] ??
            (n['nutrient'] is Map ? (n['nutrient'] as Map)['name'] : null);
        final value = n['value'] ?? n['amount'];
        if (value is num && value > 0) {
          lines.add('  $name (id=$id, num=$number) = $value');
        }
      }
      dev.log(
        '[USDA] "${first['description']}" — ${nutrients.length} nutrients '
        '(${lines.length} non-zero):\n${lines.join('\n')}',
        name: 'FitAI.USDA',
      );
    }

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
