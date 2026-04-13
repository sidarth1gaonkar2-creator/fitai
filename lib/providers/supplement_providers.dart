import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../data/supplement_library.dart';
import '../models/enums.dart';
import '../models/supplement.dart';
import '../models/supplement_log.dart';
import '../services/supplement_api_service.dart';
import 'isar_provider.dart';

/// Supplement catalog: hardcoded English library is the primary source.
/// API supplements are appended only if they return English content
/// and aren't already in the hardcoded list.
final supplementCatalogProvider =
    FutureProvider<List<ApiSupplement>>((ref) async {
  // Primary: hardcoded English library
  final primary = supplementLibrary
      .map((def) => ApiSupplement(
            name: def.name,
            rating: 4,
            recommendation: '',
            tags: [def.category],
            benefits: def.benefits,
            whoShouldUse: const [],
            dose: '${def.dosage} ${def.unit}',
            timing: def.timing.label,
            suggestions: def.sideEffects,
            url: '',
            isVitamin: false,
          ))
      .toList();

  // Secondary: try to add unique API items that are in English
  final apiResult = await SupplementApiService.instance.fetchAll();
  if (apiResult != null && apiResult.isNotEmpty) {
    final existingNames =
        primary.map((s) => s.name.toLowerCase()).toSet();
    for (final api in apiResult) {
      // Skip items already in the hardcoded list
      if (existingNames.contains(api.name.toLowerCase())) continue;
      // Skip non-English content (heuristic: check for common Turkish chars)
      if (_looksLikeTurkish(api.benefits) || _looksLikeTurkish(api.tags)) {
        continue;
      }
      primary.add(api);
    }
  }

  return primary;
});

/// Simple heuristic: if any string contains Turkish-specific characters
/// or common Turkish words, it's probably not English.
bool _looksLikeTurkish(List<String> strings) {
  const turkishMarkers = ['ı', 'ş', 'ğ', 'ç', 'ö', 'ü', 'İ', 'Ş', 'Ğ', 'Ç', 'Ö', 'Ü'];
  for (final s in strings) {
    for (final marker in turkishMarkers) {
      if (s.contains(marker)) return true;
    }
  }
  return false;
}

/// All supplements (including inactive) for management screen.
final allSupplementsProvider =
    FutureProvider<List<Supplement>>((ref) async {
  final isar = ref.watch(isarProvider);
  return isar.supplements.where().findAll();
});

/// Active supplements only.
final activeSupplementsProvider =
    FutureProvider<List<Supplement>>((ref) async {
  final isar = ref.watch(isarProvider);
  final all = await isar.supplements.where().findAll();
  return all.where((s) => s.isActive).toList();
});

/// Today's supplement logs.
final todaySupplementLogsProvider =
    FutureProvider<List<SupplementLog>>((ref) async {
  final isar = ref.watch(isarProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  final all = await isar.supplementLogs.where().findAll();
  return all
      .where((l) =>
          l.date.isAfter(today.subtract(const Duration(seconds: 1))) &&
          l.date.isBefore(tomorrow))
      .toList();
});

/// Checklist item for dashboard display.
class SupplementChecklistItem {
  const SupplementChecklistItem({
    required this.supplement,
    required this.taken,
    this.timeTaken,
  });

  final Supplement supplement;
  final bool taken;
  final DateTime? timeTaken;
}

/// Joins active supplements with today's logs for checklist UI.
final supplementChecklistProvider =
    FutureProvider<List<SupplementChecklistItem>>((ref) async {
  final supplements = await ref.watch(activeSupplementsProvider.future);
  final logs = await ref.watch(todaySupplementLogsProvider.future);

  return supplements.map((s) {
    final log = logs.where((l) => l.supplementId == s.id).firstOrNull;
    return SupplementChecklistItem(
      supplement: s,
      taken: log?.taken ?? false,
      timeTaken: log?.timeTaken,
    );
  }).toList();
});

/// Consistency % for a given supplement over last 30 days.
final supplementConsistencyProvider =
    FutureProvider.family<double, int>((ref, supplementId) async {
  final isar = ref.watch(isarProvider);
  final now = DateTime.now();
  final thirtyDaysAgo = DateTime(now.year, now.month, now.day - 30);

  final logs = await isar.supplementLogs.where().findAll();
  final relevantLogs = logs
      .where((l) =>
          l.supplementId == supplementId &&
          l.date.isAfter(thirtyDaysAgo) &&
          l.taken)
      .toList();

  return relevantLogs.length / 30.0;
});

/// Toggle a supplement as taken/untaken for today.
Future<void> toggleSupplementTaken(
  WidgetRef ref,
  int supplementId,
  bool taken,
) async {
  final isar = ref.read(isarProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // Find existing log for today
  final allLogs = await isar.supplementLogs.where().findAll();
  final existing = allLogs
      .where((l) =>
          l.supplementId == supplementId &&
          l.date.year == today.year &&
          l.date.month == today.month &&
          l.date.day == today.day)
      .firstOrNull;

  await isar.writeTxn(() async {
    if (existing != null) {
      existing.taken = taken;
      existing.timeTaken = taken ? DateTime.now() : null;
      await isar.supplementLogs.put(existing);
    } else {
      final log = SupplementLog()
        ..supplementId = supplementId
        ..date = today
        ..taken = taken
        ..timeTaken = taken ? DateTime.now() : null;
      await isar.supplementLogs.put(log);
    }
  });

  ref.invalidate(todaySupplementLogsProvider);
  ref.invalidate(supplementChecklistProvider);
}

/// Add a supplement to Isar.
Future<void> addSupplement(WidgetRef ref, Supplement supplement) async {
  final isar = ref.read(isarProvider);
  await isar.writeTxn(() async {
    await isar.supplements.put(supplement);
  });
  ref.invalidate(allSupplementsProvider);
  ref.invalidate(activeSupplementsProvider);
  ref.invalidate(supplementChecklistProvider);
}

/// Deactivate a supplement.
Future<void> deactivateSupplement(WidgetRef ref, int id) async {
  final isar = ref.read(isarProvider);
  final supplement = await isar.supplements.get(id);
  if (supplement == null) return;
  supplement.isActive = false;
  await isar.writeTxn(() async {
    await isar.supplements.put(supplement);
  });
  ref.invalidate(allSupplementsProvider);
  ref.invalidate(activeSupplementsProvider);
  ref.invalidate(supplementChecklistProvider);
}

/// Reactivate a supplement.
Future<void> reactivateSupplement(WidgetRef ref, int id) async {
  final isar = ref.read(isarProvider);
  final supplement = await isar.supplements.get(id);
  if (supplement == null) return;
  supplement.isActive = true;
  await isar.writeTxn(() async {
    await isar.supplements.put(supplement);
  });
  ref.invalidate(allSupplementsProvider);
  ref.invalidate(activeSupplementsProvider);
  ref.invalidate(supplementChecklistProvider);
}

/// Delete a supplement and all its logs.
Future<void> deleteSupplement(WidgetRef ref, int id) async {
  final isar = ref.read(isarProvider);
  await isar.writeTxn(() async {
    // Delete logs
    final logs = await isar.supplementLogs.where().findAll();
    final logIds = logs.where((l) => l.supplementId == id).map((l) => l.id).toList();
    await isar.supplementLogs.deleteAll(logIds);
    // Delete supplement
    await isar.supplements.delete(id);
  });
  ref.invalidate(allSupplementsProvider);
  ref.invalidate(activeSupplementsProvider);
  ref.invalidate(supplementChecklistProvider);
}
