import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/logger.dart';
import '../core/utils/scoped_prefs.dart';
import '../features/ranks/domain/exercise_standards.dart';
import 'auth_provider.dart';
import 'unit_system_provider.dart' show sharedPreferencesProvider;

// Base key — stored uid-scoped as `custom_exercise_groups_v1_<uid>` (PR-B).
const _kCustomExerciseGroupsKey = 'custom_exercise_groups_v1';

/// Persistent registry mapping a user-created custom exercise NAME (original
/// casing) → the [RankGroup] the user chose for it at creation.
///
/// Backed by SharedPreferences (a JSON string) so we avoid an Isar schema
/// change — consistent with how the rest of this project stores small bits of
/// user state. The group is captured ONCE when the custom exercise is first
/// created and reused on every later log, so the user is never re-prompted and
/// the exercise scores consistently. Without this, a custom exercise had no
/// group and silently scored as Chest.
class CustomExerciseRegistry {
  CustomExerciseRegistry(this._prefs, this._uid);

  final SharedPreferences _prefs;

  /// The account whose registry this is; null (signed out) reads empty and
  /// writes nothing — custom exercises can only be created signed in.
  final String? _uid;

  Map<String, RankGroup> _read() {
    final uid = _uid;
    if (uid == null) return {};
    final raw = _prefs.getString(scopedKey(_kCustomExerciseGroupsKey, uid));
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final result = <String, RankGroup>{};
      decoded.forEach((name, groupName) {
        final group = _parseGroup(groupName as String?);
        if (group != null) result[name as String] = group;
      });
      return result;
    } catch (e, st) {
      // Corrupt/legacy value — treat as empty rather than crash.
      AppLogger.error('Custom exercise registry: corrupt stored value',
          error: e, stack: st);
      return {};
    }
  }

  static RankGroup? _parseGroup(String? name) {
    if (name == null) return null;
    for (final g in RankGroup.values) {
      if (g.name == name) return g;
    }
    return null;
  }

  /// The chosen group for [name] (matched case-insensitively), or null if this
  /// name was never registered as a custom exercise.
  RankGroup? groupFor(String name) {
    final lower = name.toLowerCase().trim();
    for (final entry in _read().entries) {
      if (entry.key.toLowerCase().trim() == lower) return entry.value;
    }
    return null;
  }

  /// True when [name] has already been categorised — used to skip the prompt
  /// when re-logging a previously-created custom exercise.
  bool isKnown(String name) => groupFor(name) != null;

  /// Records [group] for the custom exercise [name]. Overwrites any prior
  /// entry for the same (case-insensitive) name so a re-categorisation sticks.
  Future<void> setGroup(String name, RankGroup group) async {
    final uid = _uid;
    if (uid == null) return; // signed out: dormant — no anon keys
    final trimmed = name.trim();
    final lower = trimmed.toLowerCase();
    final map = _read()
      ..removeWhere((k, _) => k.toLowerCase().trim() == lower);
    map[trimmed] = group;
    await _prefs.setString(
      scopedKey(_kCustomExerciseGroupsKey, uid),
      jsonEncode({for (final e in map.entries) e.key: e.value.name}),
    );
  }
}

final customExerciseRegistryProvider = Provider<CustomExerciseRegistry>((ref) {
  return CustomExerciseRegistry(
    ref.watch(sharedPreferencesProvider),
    ref.watch(currentUserIdProvider),
  );
});
