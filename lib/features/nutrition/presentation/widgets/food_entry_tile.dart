import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/field_manual.dart';
import '../../../../core/widgets/cupertino_helpers.dart';
import '../../../../models/food_entry.dart';

class FoodEntryTile extends StatelessWidget {
  const FoodEntryTile({
    super.key,
    required this.entry,
    required this.onDelete,
    this.onRestore,
    this.isLocked = false,
  });

  final FoodEntry entry;
  final VoidCallback onDelete;

  /// If non-null, an "Undo" action is offered for 5 seconds after swipe-delete.
  /// Tapping Undo invokes this callback with the deleted entry's data so the
  /// parent can re-insert it.
  final void Function(FoodEntry entry)? onRestore;

  /// When true, disables swipe-to-delete.
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    final tile = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // User content — never uppercased.
                  entry.name,
                  style: FieldManual.title().copyWith(fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  children: [
                    _MacroTag(label: 'P', grams: entry.protein),
                    _MacroTag(label: 'C', grams: entry.carbs),
                    _MacroTag(label: 'F', grams: entry.fat),
                    if (entry.servingSize != null)
                      _ServingTag(
                        size: entry.servingSize!,
                        unit: entry.servingUnit ?? 'g',
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${entry.calories.toInt()}',
            style: FieldManual.readout(fontSize: 15),
          ),
          Text(
            ' KCAL',
            style: FieldManual.readout(
              fontSize: 10,
              color: FieldManual.mutedBone,
            ),
          ),
        ],
      ),
    );

    if (isLocked) return tile;

    // Swipe is the only visual delete affordance — expose it to assistive
    // tech as a custom semantic action too.
    return Semantics(
      customSemanticsActions: {
        const CustomSemanticsAction(label: 'Delete'): onDelete,
      },
      child: _SwipeTile(
        entry: entry,
        onDelete: onDelete,
        onRestore: onRestore,
        child: tile,
      ),
    );
  }
}

/// Macro chips retire their old macro-tint colours: data readouts are bone
/// on field surfaces. Legacy macro tints survive only as small icon accents
/// elsewhere, pending a future decision.
class _MacroTag extends StatelessWidget {
  const _MacroTag({
    required this.label,
    required this.grams,
  });

  final String label;
  final double grams;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: FieldManual.fieldRaised,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label ${grams.toInt()}G',
        style: FieldManual.readout(
          fontSize: 10,
          color: FieldManual.mutedBone,
        ),
      ),
    );
  }
}

class _ServingTag extends StatelessWidget {
  const _ServingTag({required this.size, required this.unit});

  final double size;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: FieldManual.fieldRaised,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '${size.toInt()}${unit.toUpperCase()}',
        style: FieldManual.readout(
          fontSize: 10,
          color: FieldManual.mutedBone,
        ),
      ),
    );
  }
}

// ─── Swipe-to-delete wrapper ────────────────────────────────────────────────

class _SwipeTile extends StatefulWidget {
  const _SwipeTile({
    required this.entry,
    required this.onDelete,
    required this.child,
    this.onRestore,
  });

  final FoodEntry entry;
  final VoidCallback onDelete;
  final void Function(FoodEntry entry)? onRestore;
  final Widget child;

  @override
  State<_SwipeTile> createState() => _SwipeTileState();
}

class _SwipeTileState extends State<_SwipeTile> {
  double _dragExtent = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = constraints.maxWidth;
        final fraction = tileWidth > 0 ? (_dragExtent / tileWidth).abs() : 0.0;
        final showRed = fraction >= 0.2;

        return Dismissible(
          key: ValueKey(widget.entry.id),
          direction: DismissDirection.endToStart,
          dismissThresholds: const {DismissDirection.endToStart: 0.3},
          onUpdate: (details) {
            setState(() => _dragExtent = details.progress * tileWidth);
          },
          confirmDismiss: (_) async {
            if (_dragExtent.abs() < 40) return false;
            HapticFeedback.mediumImpact();
            final restore = widget.onRestore;
            // Snapshot the entry data BEFORE deletion so we can restore it.
            final snapshot = restore != null ? _cloneEntry(widget.entry) : null;
            widget.onDelete();
            if (context.mounted) {
              if (snapshot != null && restore != null) {
                showCupertinoUndoToast(
                  context,
                  'Removed ${widget.entry.name}',
                  onUndo: () => restore(snapshot),
                );
              } else {
                showCupertinoToast(context, 'Removed ${widget.entry.name}');
              }
            }
            return false;
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            color: showRed
                ? AppColors.of(context).destructive.withValues(alpha: 0.9)
                : FieldManual.fieldRaised,
            child: Icon(
              // On the red fill the glyph is ink — the AA-safe alert red is
              // light (bone would read 2.53:1, ink 5.33:1). On the neutral
              // field-raised fill it stays mutedBone.
              Icons.delete,
              color: showRed ? FieldManual.ink : FieldManual.mutedBone,
            ),
          ),
          child: widget.child,
        );
      },
    );
  }

  /// Detached copy of an entry's user-visible fields. The clone is not
  /// attached to Isar, so deleting the original does not invalidate this
  /// data — it can be used to re-insert via [addFoodEntry].
  static FoodEntry _cloneEntry(FoodEntry e) {
    return FoodEntry()
      ..name = e.name
      ..calories = e.calories
      ..protein = e.protein
      ..carbs = e.carbs
      ..fat = e.fat
      ..servingSize = e.servingSize
      ..servingUnit = e.servingUnit
      ..vitaminDMcg = e.vitaminDMcg
      ..ironMg = e.ironMg
      ..calciumMg = e.calciumMg
      ..vitaminCMg = e.vitaminCMg
      ..magnesiumMg = e.magnesiumMg
      ..sodiumMg = e.sodiumMg
      ..potassiumMg = e.potassiumMg
      ..zincMg = e.zincMg
      ..vitaminB12Mcg = e.vitaminB12Mcg
      ..folateMcg = e.folateMcg
      ..fibre = e.fibre
      ..sugar = e.sugar
      ..mealGroupId = e.mealGroupId
      ..mealGroupName = e.mealGroupName
      ..mealGroupEmoji = e.mealGroupEmoji;
  }
}
