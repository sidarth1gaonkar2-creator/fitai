import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/cupertino_helpers.dart';
import '../../../../models/enums.dart';
import '../../../../models/food_entry.dart';
import '../../../../providers/isar_provider.dart';
import '../../../../providers/nutrition_providers.dart';

/// One row in the recent foods list — deduplicated to the most recent
/// occurrence of a unique food name. Stores enough info to re-log without
/// another search.
class _RecentFoodRow {
  _RecentFoodRow({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.servingSize,
    required this.servingUnit,
    required this.loggedAt,
  });

  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double servingSize;
  final String servingUnit;
  final DateTime loggedAt;
}

/// Pulls every FoodEntry from the last 30 days, dedups by name (keeping the
/// most-recent), and sorts by `loggedAt` desc. The FoodEntry → Meal backlink
/// gives us the time via Meal.time; entries without a parent meal fall back
/// to now() so they still surface.
final recentFoodsProvider =
    FutureProvider.autoDispose<List<_RecentFoodRow>>((ref) async {
  final isar = ref.watch(isarProvider);
  final cutoff = DateTime.now().subtract(const Duration(days: 30));

  // Pull every food entry — Isar is local and the dataset is small, no
  // need for a complex query.
  final entries = await isar.foodEntrys.where().findAll();

  // Resolve each entry's meal time via its backlink. We batch the lookups
  // by collecting meal IDs and querying once.
  final rows = <String, _RecentFoodRow>{};
  for (final e in entries) {
    await e.meal.load();
    final time = e.meal.firstOrNull?.time ?? DateTime.now();
    if (time.isBefore(cutoff)) continue;

    final key = e.name.toLowerCase().trim();
    final existing = rows[key];
    if (existing != null && existing.loggedAt.isAfter(time)) continue;
    rows[key] = _RecentFoodRow(
      name: e.name,
      calories: e.calories,
      protein: e.protein,
      carbs: e.carbs,
      fat: e.fat,
      servingSize: e.servingSize ?? 1,
      servingUnit: e.servingUnit ?? 'serving',
      loggedAt: time,
    );
  }

  final result = rows.values.toList()
    ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
  return result.take(20).toList();
});

/// Bottom sheet showing the last 20 distinct foods the user has logged.
/// Grouped by Today / Yesterday / This Week / Earlier. One-tap re-add
/// drops it into the chosen meal type.
class RecentFoodsSheet extends ConsumerWidget {
  const RecentFoodsSheet({super.key, this.mealType = MealType.lunch});

  final MealType mealType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    final async = ref.watch(recentFoodsProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, controller) => Container(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 8),
              child: Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: palette.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Row(
                children: [
                  Text(
                    'Recent Foods',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: palette.text,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(CupertinoIcons.xmark, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    color: palette.textSecondary,
                  ),
                ],
              ),
            ),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CupertinoActivityIndicator()),
                error: (e, _) => _Empty(
                  message: 'Couldn’t load recent foods.',
                  palette: palette,
                ),
                data: (rows) {
                  if (rows.isEmpty) {
                    return _Empty(
                      message: 'No recent foods yet. Log something first!',
                      palette: palette,
                    );
                  }
                  return _GroupedList(
                    rows: rows,
                    controller: controller,
                    onTap: (row) => _onTap(context, ref, row),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onTap(
      BuildContext context, WidgetRef ref, _RecentFoodRow row) async {
    HapticFeedback.lightImpact();
    final ok = await addFoodEntry(
      ref,
      mealType: mealType,
      name: row.name,
      calories: row.calories,
      protein: row.protein,
      carbs: row.carbs,
      fat: row.fat,
      servingSize: row.servingSize,
      servingUnit: row.servingUnit,
    );
    if (!context.mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      showCupertinoToast(context, 'Added ${row.name} to ${mealType.label}');
    } else {
      showCupertinoToast(context, 'Failed to add. Try again.');
    }
  }
}

class _GroupedList extends StatelessWidget {
  const _GroupedList({
    required this.rows,
    required this.controller,
    required this.onTap,
  });

  final List<_RecentFoodRow> rows;
  final ScrollController controller;
  final void Function(_RecentFoodRow) onTap;

  String _bucket(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));
    final logged = DateTime(d.year, d.month, d.day);
    if (logged == today) return 'Today';
    if (logged == yesterday) return 'Yesterday';
    if (logged.isAfter(weekAgo)) return 'This Week';
    return 'Earlier';
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    // Group preserving order — rows is already sorted desc by time.
    final grouped = <String, List<_RecentFoodRow>>{};
    for (final r in rows) {
      grouped.putIfAbsent(_bucket(r.loggedAt), () => []).add(r);
    }
    final order = ['Today', 'Yesterday', 'This Week', 'Earlier']
        .where(grouped.containsKey)
        .toList();

    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: order.fold<int>(0, (sum, k) => sum + grouped[k]!.length + 1),
      itemBuilder: (context, index) {
        var remaining = index;
        for (final k in order) {
          if (remaining == 0) {
            return Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 6, left: 4),
              child: Text(
                k,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: palette.textSecondary,
                  letterSpacing: 0.4,
                ),
              ),
            );
          }
          remaining -= 1;
          final group = grouped[k]!;
          if (remaining < group.length) {
            return _Tile(row: group[remaining], onTap: () => onTap(group[remaining]));
          }
          remaining -= group.length;
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.row, required this.onTap});

  final _RecentFoodRow row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: palette.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: palette.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${row.servingUnit} · '
                        'P${row.protein.toInt()} '
                        'C${row.carbs.toInt()} '
                        'F${row.fat.toInt()}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${row.calories.toInt()}',
                      style: TextStyle(
                        fontFamily: 'LeagueSpartan',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: palette.text,
                      ),
                    ),
                    Text(
                      'kcal',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        fontSize: 10,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(
                  CupertinoIcons.add_circled_solid,
                  size: 22,
                  color: palette.accent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.message, required this.palette});

  final String message;
  final Palette palette;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: palette.textSecondary,
          ),
        ),
      ),
    );
  }
}
