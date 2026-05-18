import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/exercise_name_map.dart';
import '../models/exercisedb_exercise.dart';

/// Thin wrapper around the ExerciseDB v2 API.
///
/// Caching strategy (in priority order):
///   1. **In-memory map** — populated lazily per service instance, lookup
///      is by lowercased exercise name. Cleared when the app process dies.
///   2. **SharedPreferences** — disk cache keyed by lowercased name. 30-day
///      TTL because exercise data essentially never changes. Misses are
///      also cached (as `null`) for 24h to avoid re-hitting the API for
///      every typo'd / unmappable exercise name.
///   3. **Network** — last resort. Errors and 4xx responses fall back to a
///      negative-cache entry so we don't hammer the API on flaky days.
///
/// The service is process-wide singleton-ish via the Riverpod provider.
class ExerciseDBService {
  ExerciseDBService();

  // v1 has no auth requirement and exposes the `/exercises/name/{name}`
  // endpoint we want. Keep this as a single constant so a future swap to a
  // self-hosted instance is a one-line change.
  static const _baseUrl = 'https://exercisedb-api.vercel.app/api/v1';
  static const _cachePrefix = 'exercisedb_v1_';
  static const _hitTtl = Duration(days: 30);
  static const _missTtl = Duration(hours: 24);

  final Map<String, ExerciseDBExercise?> _mem = {};
  final HttpClient _client = HttpClient();

  /// Fetches an exercise by the app's local name. Applies the name overrides
  /// from [ExerciseNameMap] so the API search uses the term most likely to
  /// match an ExerciseDB record.
  Future<ExerciseDBExercise?> getExercise(String localName) async {
    final key = localName.toLowerCase().trim();
    if (key.isEmpty) return null;

    // 1. In-memory
    if (_mem.containsKey(key)) return _mem[key];

    // 2. Disk
    final cached = await _readCache(key);
    if (cached != null) {
      _mem[key] = cached.exercise;
      return cached.exercise;
    }

    // 3. Network
    final searchTerm = ExerciseNameMap.searchTermFor(localName);
    final result = await _fetch(searchTerm);
    _mem[key] = result;
    await _writeCache(key, result);
    return result;
  }

  /// Batch convenience. Returns a map keyed by the ORIGINAL local name
  /// (so callers can match it back to their state) and drops misses.
  ///
  /// Sequential with a small inter-request delay to play nice with the
  /// public ExerciseDB instance's rate limits.
  Future<Map<String, ExerciseDBExercise>> getExercises(
    List<String> localNames,
  ) async {
    final out = <String, ExerciseDBExercise>{};
    for (final name in localNames) {
      final ex = await getExercise(name);
      if (ex != null) out[name] = ex;
      // Small delay only for genuine network round-trips, not cache hits.
      if (!_mem.containsKey(name.toLowerCase().trim())) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
    return out;
  }

  // ───────────────────────────────────────────────────────────────────
  // Network
  // ───────────────────────────────────────────────────────────────────

  Future<ExerciseDBExercise?> _fetch(String query) async {
    if (query.trim().isEmpty) return null;
    try {
      // v1 path-based search: /exercises/name/{name}. ExerciseDB expects
      // lowercase, hyphen-or-space-tolerant names — the name map upstream
      // already lowercases its overrides.
      final encoded = Uri.encodeComponent(query.toLowerCase());
      final uri = Uri.parse('$_baseUrl/exercises/name/$encoded?limit=1');
      final request = await _client.getUrl(uri);
      request.headers.set('User-Agent', 'FitAI/1.0 (Flutter)');
      final response = await request.close();
      if (response.statusCode != 200) {
        dev.log('[ExerciseDB] $query → ${response.statusCode}',
            name: 'FitAI.ExerciseDB');
        return null;
      }
      final body = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(body);
      // v2 wraps results in { data: [...] } but some legacy paths return a
      // bare list. Handle both defensively.
      List<dynamic>? list;
      if (decoded is Map<String, dynamic>) {
        final data = decoded['data'];
        if (data is List) list = data;
      } else if (decoded is List) {
        list = decoded;
      }
      if (list == null || list.isEmpty) return null;
      final first = list.first;
      if (first is! Map<String, dynamic>) return null;
      return ExerciseDBExercise.fromJson(first);
    } catch (e, st) {
      debugPrint('[ExerciseDB] Fetch failed for "$query": $e');
      // Don't rethrow — caller treats null as "no data".
      _logQuiet(e, st);
      return null;
    }
  }

  void _logQuiet(Object e, StackTrace st) {
    // Keep stack traces in dev mode only.
    if (kDebugMode) {
      dev.log('[ExerciseDB] error', error: e, stackTrace: st);
    }
  }

  // ───────────────────────────────────────────────────────────────────
  // Disk cache (SharedPreferences)
  //
  // Each entry is stored as a JSON envelope:
  //   { "expiresAt": <millis>, "exercise": { ...ExerciseDBExercise toJson }? }
  // Missing `exercise` indicates a negative cache entry.
  // ───────────────────────────────────────────────────────────────────

  Future<_CachedEntry?> _readCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_cachePrefix$key');
      if (raw == null) return null;
      final envelope = jsonDecode(raw) as Map<String, dynamic>;
      final expiresAt = (envelope['expiresAt'] as num?)?.toInt() ?? 0;
      if (DateTime.now().millisecondsSinceEpoch > expiresAt) {
        // Expired — drop it so the next call refetches.
        await prefs.remove('$_cachePrefix$key');
        return null;
      }
      final exJson = envelope['exercise'];
      if (exJson is Map<String, dynamic>) {
        return _CachedEntry(ExerciseDBExercise.fromJson(exJson));
      }
      // Negative cache hit.
      return const _CachedEntry(null);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(String key, ExerciseDBExercise? ex) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ttl = ex == null ? _missTtl : _hitTtl;
      final envelope = <String, dynamic>{
        'expiresAt':
            DateTime.now().add(ttl).millisecondsSinceEpoch,
        if (ex != null) 'exercise': ex.toJson(),
      };
      await prefs.setString('$_cachePrefix$key', jsonEncode(envelope));
    } catch (_) {
      // Cache write failures are non-fatal — next call will just refetch.
    }
  }
}

class _CachedEntry {
  const _CachedEntry(this.exercise);
  final ExerciseDBExercise? exercise;
}
