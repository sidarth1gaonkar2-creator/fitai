import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/insight_service.dart';
import 'isar_provider.dart';

/// Pure-local insight cards generated from Isar data. Auto-disposes so we
/// don't keep stale insight lists in memory between tab switches.
///
/// The list is capped at 5 inside [InsightService.generate]. Caller is
/// expected to render them as dismissable cards; refresh by invalidating
/// this provider whenever new workout / nutrition data is saved.
final dashboardInsightsProvider =
    FutureProvider.autoDispose<List<Insight>>((ref) async {
  final isar = ref.watch(isarProvider);
  final service = InsightService(isar);
  return service.generate();
});
