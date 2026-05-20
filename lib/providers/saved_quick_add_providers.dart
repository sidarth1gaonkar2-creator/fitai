import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../features/nutrition/domain/saved_quick_add.dart';

const _prefsKey = 'saved_quick_adds_v1';

/// Stream of saved Quick Add presets, sorted by `lastUsedAt` desc. Backed by
/// SharedPreferences so it survives restarts without requiring an Isar
/// migration. The list is small (capped at 20 entries below) so re-reading
/// every refresh is cheap.
final savedQuickAddsProvider =
    FutureProvider<List<SavedQuickAdd>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_prefsKey);
  final items = SavedQuickAdd.decodeAll(raw)
    ..sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
  return items;
});

/// Persist a new Quick Add or update an existing one (matched by id). Caps
/// the stored list to 20 entries by dropping the oldest. Returns the saved
/// row so the caller can show feedback.
Future<SavedQuickAdd> upsertQuickAdd(
  WidgetRef ref, {
  String? id,
  required String name,
  required double calories,
  required double protein,
  required double carbs,
  required double fat,
  String? emoji,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final existing = SavedQuickAdd.decodeAll(prefs.getString(_prefsKey));
  final now = DateTime.now();

  SavedQuickAdd row;
  final idx = id == null ? -1 : existing.indexWhere((e) => e.id == id);
  if (idx >= 0) {
    row = existing[idx].copyWith(
      name: name,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      lastUsedAt: now,
      useCount: existing[idx].useCount + 1,
      emoji: emoji,
      clearEmoji: emoji == null,
    );
    existing[idx] = row;
  } else {
    row = SavedQuickAdd(
      id: const Uuid().v4(),
      name: name,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      lastUsedAt: now,
      useCount: 1,
      emoji: emoji,
    );
    existing.add(row);
  }

  existing.sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
  final trimmed = existing.take(20).toList();
  await prefs.setString(_prefsKey, SavedQuickAdd.encodeAll(trimmed));
  ref.invalidate(savedQuickAddsProvider);
  return row;
}

/// Bump the use count + recency on an existing preset (e.g. when the user
/// taps Recent → preset → Add). Different from [upsertQuickAdd] which is
/// used when the user explicitly opts into "Save for later".
Future<void> touchQuickAdd(WidgetRef ref, String id) async {
  final prefs = await SharedPreferences.getInstance();
  final existing = SavedQuickAdd.decodeAll(prefs.getString(_prefsKey));
  final idx = existing.indexWhere((e) => e.id == id);
  if (idx < 0) return;
  existing[idx] = existing[idx].copyWith(
    lastUsedAt: DateTime.now(),
    useCount: existing[idx].useCount + 1,
  );
  existing.sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
  await prefs.setString(_prefsKey, SavedQuickAdd.encodeAll(existing));
  ref.invalidate(savedQuickAddsProvider);
}

Future<void> deleteQuickAdd(WidgetRef ref, String id) async {
  final prefs = await SharedPreferences.getInstance();
  final existing = SavedQuickAdd.decodeAll(prefs.getString(_prefsKey))
    ..removeWhere((e) => e.id == id);
  await prefs.setString(_prefsKey, SavedQuickAdd.encodeAll(existing));
  ref.invalidate(savedQuickAddsProvider);
}
