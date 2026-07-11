import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/utils/scoped_prefs.dart';
import '../features/nutrition/domain/saved_quick_add.dart';
import 'auth_provider.dart';
import 'unit_system_provider.dart' show sharedPreferencesProvider;

// Base key — stored uid-scoped as `saved_quick_adds_v1_<uid>` (PR-B).
const _prefsKeyBase = 'saved_quick_adds_v1';

/// Stream of saved Quick Add presets, sorted by `lastUsedAt` desc. Backed by
/// SharedPreferences under the current account's key, so it rebuilds empty
/// for a different account (and signed out) instead of leaking presets. The
/// list is small (capped at 20 entries below) so re-reading every refresh is
/// cheap.
final savedQuickAddsProvider =
    FutureProvider<List<SavedQuickAdd>>((ref) async {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return const [];
  final prefs = ref.watch(sharedPreferencesProvider);
  final raw = prefs.getString(scopedKey(_prefsKeyBase, uid));
  final items = SavedQuickAdd.decodeAll(raw)
    ..sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
  return items;
});

/// Persist a new Quick Add or update an existing one (matched by id). Caps
/// the stored list to 20 entries by dropping the oldest. Returns the saved
/// row so the caller can show feedback. Signed out (unreachable from the
/// nutrition UI) the row is returned but nothing is persisted — no anon keys.
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
  final uid = ref.read(currentUserIdProvider);
  final prefs = ref.read(sharedPreferencesProvider);
  final key = uid == null ? null : scopedKey(_prefsKeyBase, uid);
  final existing =
      key == null ? <SavedQuickAdd>[] : SavedQuickAdd.decodeAll(prefs.getString(key));
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

  if (key != null) {
    existing.sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
    final trimmed = existing.take(20).toList();
    await prefs.setString(key, SavedQuickAdd.encodeAll(trimmed));
    ref.invalidate(savedQuickAddsProvider);
  }
  return row;
}

/// Bump the use count + recency on an existing preset (e.g. when the user
/// taps Recent → preset → Add). Different from [upsertQuickAdd] which is
/// used when the user explicitly opts into "Save for later".
Future<void> touchQuickAdd(WidgetRef ref, String id) async {
  final uid = ref.read(currentUserIdProvider);
  if (uid == null) return;
  final prefs = ref.read(sharedPreferencesProvider);
  final key = scopedKey(_prefsKeyBase, uid);
  final existing = SavedQuickAdd.decodeAll(prefs.getString(key));
  final idx = existing.indexWhere((e) => e.id == id);
  if (idx < 0) return;
  existing[idx] = existing[idx].copyWith(
    lastUsedAt: DateTime.now(),
    useCount: existing[idx].useCount + 1,
  );
  existing.sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
  await prefs.setString(key, SavedQuickAdd.encodeAll(existing));
  ref.invalidate(savedQuickAddsProvider);
}

Future<void> deleteQuickAdd(WidgetRef ref, String id) async {
  final uid = ref.read(currentUserIdProvider);
  if (uid == null) return;
  final prefs = ref.read(sharedPreferencesProvider);
  final key = scopedKey(_prefsKeyBase, uid);
  final existing = SavedQuickAdd.decodeAll(prefs.getString(key))
    ..removeWhere((e) => e.id == id);
  await prefs.setString(key, SavedQuickAdd.encodeAll(existing));
  ref.invalidate(savedQuickAddsProvider);
}
