import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// A supplement/vitamin item returned by the API.
class ApiSupplement {
  const ApiSupplement({
    required this.name,
    required this.rating,
    required this.recommendation,
    required this.tags,
    required this.benefits,
    required this.whoShouldUse,
    required this.dose,
    required this.timing,
    required this.suggestions,
    required this.url,
    required this.isVitamin,
  });

  final String name;
  final int rating;
  final String recommendation;
  final List<String> tags;
  final List<String> benefits;
  final List<String> whoShouldUse;
  final String dose;
  final String timing;
  final List<String> suggestions;
  final String url;
  final bool isVitamin;

  factory ApiSupplement.fromJson(Map<String, dynamic> json,
      {bool isVitamin = false}) {
    return ApiSupplement(
      name: json['name'] as String? ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      recommendation: json['recommendation'] as String? ?? '',
      tags: _toStringList(json['tags']),
      benefits: _toStringList(json['benefits']),
      whoShouldUse: _toStringList(json['whoShouldUse']),
      dose: json['dose'] as String? ?? '',
      timing: json['timing'] as String? ?? '',
      suggestions: _toStringList(json['suggestions']),
      url: json['url'] as String? ?? '',
      isVitamin: isVitamin,
    );
  }

  static List<String> _toStringList(dynamic value) {
    if (value is List) return value.cast<String>();
    return const [];
  }

  /// Category label derived from isVitamin flag and tags.
  String get category {
    if (isVitamin) return 'Vitamin';
    if (tags.isNotEmpty) return tags.first;
    return 'Supplement';
  }

  /// First 2 benefits joined as a short summary.
  String get benefitsSummary {
    if (benefits.isEmpty) return '';
    return benefits.take(2).join(', ');
  }
}

/// Service that fetches supplement and vitamin data from the API.
/// Caches responses in memory so repeated opens don't refetch.
class SupplementApiService {
  SupplementApiService._();
  static final SupplementApiService instance = SupplementApiService._();

  static const _baseUrl = 'https://vitamins-and-supplements.vercel.app';

  List<ApiSupplement>? _cache;
  DateTime? _cacheTime;
  static const _cacheDuration = Duration(minutes: 30);

  String get _apiToken => dotenv.env['SUPPLEMENT_API_TOKEN'] ?? '';

  /// Returns all supplements and vitamins combined.
  /// Uses in-memory cache; returns null on failure (caller should use fallback).
  Future<List<ApiSupplement>?> fetchAll() async {
    // Return cache if fresh
    if (_cache != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      return _cache;
    }

    final token = _apiToken;
    if (token.isEmpty) {
      debugPrint('[SupplementAPI] No API token configured');
      return null;
    }

    try {
      final results = <ApiSupplement>[];

      // Fetch supplements and vitamins in parallel
      final futures = await Future.wait([
        _fetchEndpoint('/api/supplement/', isVitamin: false),
        _fetchEndpoint('/api/vitamin/', isVitamin: true),
      ]);

      for (final list in futures) {
        if (list != null) results.addAll(list);
      }

      if (results.isEmpty) return null;

      // Sort by rating descending (best first)
      results.sort((a, b) => b.rating.compareTo(a.rating));

      _cache = results;
      _cacheTime = DateTime.now();
      debugPrint('[SupplementAPI] Fetched ${results.length} items');
      return results;
    } catch (e) {
      debugPrint('[SupplementAPI] fetchAll failed: $e');
      return null;
    }
  }

  Future<List<ApiSupplement>?> _fetchEndpoint(String path,
      {required bool isVitamin}) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);

      final uri = Uri.parse('$_baseUrl$path');
      final request = await client.getUrl(uri);
      request.headers.set('X-Auth-Token', _apiToken);

      final response = await request.close();
      if (response.statusCode != 200) {
        debugPrint(
            '[SupplementAPI] $path returned ${response.statusCode}');
        return null;
      }

      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body) as List;
      return json
          .map((item) =>
              ApiSupplement.fromJson(item as Map<String, dynamic>,
                  isVitamin: isVitamin))
          .toList();
    } catch (e) {
      debugPrint('[SupplementAPI] Failed to fetch $path: $e');
      return null;
    }
  }

  /// Clears the in-memory cache.
  void clearCache() {
    _cache = null;
    _cacheTime = null;
  }
}
