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

  // The public ExerciseDB deployments are flaky; we try each in order and
  // fall back to the next when a request returns no data. Format strings
  // contain `{q}` which is replaced with the URL-encoded lowercase query.
  static const List<String> _searchUrls = [
    // v2 search endpoint — newest, returns `data: [...]` envelope.
    'https://exercisedb-api.vercel.app/api/v2/exercises?search={q}&limit=1',
    // v1 path-based — returns a bare list.
    'https://exercisedb-api.vercel.app/api/v1/exercises/name/{q}?limit=1',
    // v1 query-based — same payload as path-based but some mirrors honour
    // only this form.
    'https://exercisedb-api.vercel.app/api/v1/exercises?search={q}&limit=1',
  ];

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

  /// Walks the [_searchUrls] in order; returns the first endpoint that
  /// responds with a usable record. Each attempt is logged in debug mode
  /// so it's clear from the console which endpoint produced the hit (or
  /// why all of them missed).
  Future<ExerciseDBExercise?> _fetch(String query) async {
    if (query.trim().isEmpty) return null;
    final encoded = Uri.encodeComponent(query.toLowerCase());
    for (final template in _searchUrls) {
      final uri = Uri.parse(template.replaceFirst('{q}', encoded));
      try {
        debugPrint('[ExerciseDB] GET $uri');
        final request = await _client.getUrl(uri);
        request.headers.set('User-Agent', 'FitAI/1.0 (Flutter)');
        request.headers.set('Accept', 'application/json');
        final response = await request.close();
        debugPrint('[ExerciseDB] → ${response.statusCode}');
        if (response.statusCode != 200) {
          // 4xx / 5xx → try next mirror.
          continue;
        }
        final body = await response.transform(utf8.decoder).join();
        if (kDebugMode) {
          final preview =
              body.length > 500 ? '${body.substring(0, 500)}…' : body;
          debugPrint('[ExerciseDB] body: $preview');
        }
        final decoded = jsonDecode(body);
        // v2 wraps results in `{ data: [...] }`; v1 returns a bare list or
        // a `{ success, data }` envelope. Handle all three defensively.
        List<dynamic>? list;
        if (decoded is Map<String, dynamic>) {
          final data = decoded['data'];
          if (data is List) list = data;
        } else if (decoded is List) {
          list = decoded;
        }
        if (list == null || list.isEmpty) continue;
        final first = list.first;
        if (first is! Map<String, dynamic>) continue;
        final parsed = ExerciseDBExercise.fromJson(first);
        debugPrint(
            '[ExerciseDB] hit "${parsed.name}" image=${parsed.fullImageUrl}');
        return parsed;
      } catch (e, st) {
        debugPrint('[ExerciseDB] $uri threw: $e');
        _logQuiet(e, st);
        // continue to next mirror
      }
    }
    debugPrint('[ExerciseDB] all mirrors missed for "$query"');
    return null;
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
