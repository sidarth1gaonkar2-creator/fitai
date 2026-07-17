import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Divider, Icons;
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/field_manual.dart';
import '../../../../core/widgets/cupertino_helpers.dart';
import '../../../../models/enums.dart';
import '../../../../models/food_entry.dart';
import 'food_entry_tile.dart';
import 'meal_group_tile.dart';
import 'save_meal_sheet.dart';

class MealSection extends StatelessWidget {
  const MealSection({
    super.key,
    required this.mealType,
    required this.entries,
    required this.onAddFood,
    required this.onDeleteEntry,
    this.onDeleteGroup,
    this.onRestoreEntry,
    this.isLocked = false,
  });

  final MealType mealType;
  final List<FoodEntry> entries;
  final VoidCallback onAddFood;
  final void Function(int entryId) onDeleteEntry;

  /// Removes every entry that shares a [FoodEntry.mealGroupId]. Wired in
  /// the parent so this widget stays presentation-only.
  final void Function(String groupId)? onDeleteGroup;
  final void Function(MealType mealType, FoodEntry entry)? onRestoreEntry;

  /// When true, hides the "Add Food" button and disables swipe-to-delete.
  final bool isLocked;

  String _defaultMealName() {
    final weekday = switch (DateTime.now().weekday) {
      DateTime.monday => 'Monday',
      DateTime.tuesday => 'Tuesday',
      DateTime.wednesday => 'Wednesday',
      DateTime.thursday => 'Thursday',
      DateTime.friday => 'Friday',
      DateTime.saturday => 'Saturday',
      DateTime.sunday => 'Sunday',
      _ => '',
    };
    return '$weekday ${mealType.label}';
  }

  String? _defaultEmoji() => switch (mealType) {
        MealType.breakfast => '🍳',
        MealType.lunch => '🥗',
        MealType.dinner => '🍗',
        MealType.snack => '🍎',
      };

  Future<void> _onSavePressed(BuildContext context) async {
    HapticFeedback.selectionClick();
    if (entries.isEmpty) {
      showCupertinoToast(context, 'Add foods first before saving');
      return;
    }
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => SaveMealSheet(
        defaultName: _defaultMealName(),
        defaultEmoji: _defaultEmoji(),
        entries: entries,
      ),
    );
  }

  IconData get _icon => switch (mealType) {
        MealType.breakfast => Icons.egg_outlined,
        MealType.lunch => Icons.lunch_dining_outlined,
        MealType.dinner => Icons.dinner_dining_outlined,
        MealType.snack => Icons.cookie_outlined,
      };

  double get _totalCalories =>
      entries.fold(0, (sum, e) => sum + e.calories);

  double get _totalProtein =>
      entries.fold(0, (sum, e) => sum + e.protein);

  /// Walks [entries] in order, emitting either a [MealGroupTile] for each
  /// run of entries sharing a `mealGroupId` or a [FoodEntryTile] for solo
  /// rows. Preserves insertion order so the user sees items in the order
  /// they were logged.
  List<Widget> _renderRows() {
    final rows = <Widget>[];
    final seenGroups = <String>{};
    for (final entry in entries) {
      final gid = entry.mealGroupId;
      if (gid == null || gid.isEmpty) {
        rows.add(FoodEntryTile(
          entry: entry,
          onDelete: () => onDeleteEntry(entry.id),
          onRestore: onRestoreEntry == null
              ? null
              : (e) => onRestoreEntry!(mealType, e),
          isLocked: isLocked,
        ));
        continue;
      }
      if (seenGroups.contains(gid)) continue;
      seenGroups.add(gid);
      final members = entries.where((e) => e.mealGroupId == gid).toList();
      rows.add(MealGroupTile(
        entries: members,
        onDeleteGroup: () {
          final cb = onDeleteGroup;
          // Fall back to per-entry deletes when the parent didn't wire the
          // group callback. Keeps the widget usable in tests/dashboards
          // that haven't been updated.
          if (cb != null) {
            cb(gid);
          } else {
            for (final e in members) {
              onDeleteEntry(e.id);
            }
          }
        },
        isLocked: isLocked,
      ));
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

    return CupertinoCard(
      padding: const EdgeInsets.all(12),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: palette.accent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _icon,
                    // On-accent glyph on the accent-filled disc — accent
                    // surfaces carry the palette's onAccent tone (DESIGN.md).
                    color: palette.onAccent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    // Meal designations are commands: BREAKFAST, LUNCH...
                    mealType.label.toUpperCase(),
                    style: FieldManual.title(),
                  ),
                ),
                if (!isLocked && entries.isNotEmpty)
                  // "Save as Meal" bookmark — only when there's something to
                  // save. Toast handles the empty-entries case for safety.
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _onSavePressed(context),
                    // ≥44pt tap target; the icon stays visually small.
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.bookmark_outline,
                        size: 18,
                        color: palette.textSecondary,
                        semanticLabel: 'Save meal',
                      ),
                    ),
                  ),
                if (entries.isNotEmpty) ...[
                  // Protein subtotal — instrument readout, quiet tone.
                  Text(
                    '${_totalProtein.toInt()}G P',
                    style: FieldManual.readout(
                      fontSize: 11,
                      color: FieldManual.mutedBone,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Calorie subtotal — the section's primary number.
                  Text(
                    '${_totalCalories.toInt()} KCAL',
                    style: FieldManual.readout(fontSize: 13),
                  ),
                ] else ...[
                  Text(
                    '0 KCAL',
                    style: FieldManual.readout(
                      fontSize: 13,
                      color: FieldManual.mutedBone,
                    ),
                  ),
                ],
              ],
            ),
            if (entries.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(height: 1, color: FieldManual.hairline),
              ..._renderRows(),
              if (!isLocked && entries.length >= 2)
                // Gentle nudge — visible only when there are multiple
                // items in the section (saving a 1-item meal isn't useful).
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _onSavePressed(context),
                    // ≥44pt tap target for the save nudge row.
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 44),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bookmark_add_outlined,
                            size: 14,
                            color: palette.accent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Save this as a reusable meal',
                            style: FieldManual.body(
                              fontSize: 12,
                              color: palette.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                'Empty plate, soldier. Log it.',
                style: FieldManual.body(
                  fontSize: 13,
                  color: FieldManual.mutedBone,
                ),
              ),
            ],
            if (!isLocked) ...[
              const SizedBox(height: 8),
              Center(
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: onAddFood,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.add, size: 18, color: palette.accent),
                      const SizedBox(width: 4),
                      Text(
                        'ADD FOOD',
                        style: FieldManual.label(
                          fontSize: 11,
                          color: palette.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
    );
  }
}
