import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/field_manual.dart';
import '../../../../core/widgets/cupertino_helpers.dart';
import '../../../../models/food_entry.dart';
import '../../../../providers/saved_meal_providers.dart';
import 'food_emoji_picker.dart';

/// Bottom sheet shown when the user taps "Save as Meal" on a populated meal
/// section. Pre-fills the name with `weekday + meal type` (e.g. "Monday
/// Breakfast") and offers a small emoji picker. On save it inserts a
/// [SavedMeal] + items into Isar and dismisses.
class SaveMealSheet extends ConsumerStatefulWidget {
  const SaveMealSheet({
    super.key,
    required this.defaultName,
    required this.entries,
    this.defaultEmoji,
  });

  /// e.g. "Monday Breakfast" — used as the initial value of the name field.
  /// Format is `\<weekday\> \<meal type\>`.
  final String defaultName;

  /// FoodEntries currently in the meal section the user is saving from.
  final List<FoodEntry> entries;

  final String? defaultEmoji;

  @override
  ConsumerState<SaveMealSheet> createState() => _SaveMealSheetState();
}

class _SaveMealSheetState extends ConsumerState<SaveMealSheet> {
  late final TextEditingController _nameController;
  late String? _emoji;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.defaultName);
    _emoji = widget.defaultEmoji;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showCupertinoToast(context, 'Give your meal a name first');
      return;
    }
    setState(() => _saving = true);
    final items =
        widget.entries.map(savedMealItemFromFoodEntry).toList();
    try {
      await saveMeal(
        ref,
        name: name,
        emoji: _emoji,
        items: items,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    showCupertinoToast(context, 'Meal saved');
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

    final totalCal = widget.entries.fold<double>(0, (s, e) => s + e.calories);
    final totalPro = widget.entries.fold<double>(0, (s, e) => s + e.protein);
    final totalCarb = widget.entries.fold<double>(0, (s, e) => s + e.carbs);
    final totalFat = widget.entries.fold<double>(0, (s, e) => s + e.fat);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: FieldManual.ink,
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: FieldManual.hairlineStrong,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'SAVE MEAL',
                textAlign: TextAlign.center,
                style: FieldManual.title(),
              ),
              const SizedBox(height: 16),
              CupertinoTextField(
                controller: _nameController,
                placeholder: 'Meal name',
                autofocus: true,
                style: FieldManual.body(fontSize: 16),
                placeholderStyle: FieldManual.body(
                  fontSize: 16,
                  color: FieldManual.mutedBone,
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: FieldManual.fieldRaised,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: FieldManual.hairline),
                ),
              ),
              const SizedBox(height: 12),
              FoodEmojiSelector(
                emoji: _emoji,
                onChanged: (e) => setState(() => _emoji = e),
              ),
              const SizedBox(height: 16),
              // Items preview
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: FieldManual.field,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: FieldManual.hairline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final e in widget.entries) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              e.name,
                              style: FieldManual.body(fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${e.calories.toInt()} KCAL',
                            style: FieldManual.readout(
                              fontSize: 12,
                              color: FieldManual.mutedBone,
                            ),
                          ),
                        ],
                      ),
                      if (e != widget.entries.last) const SizedBox(height: 4),
                    ],
                    const SizedBox(height: 10),
                    Container(
                      height: 1,
                      color: FieldManual.hairline,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'TOTAL',
                            style: FieldManual.label(fontSize: 10),
                          ),
                        ),
                        Text(
                          '${totalCal.toInt()} KCAL',
                          style: FieldManual.readout(fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'P ${totalPro.toInt()}G · C ${totalCarb.toInt()}G · F ${totalFat.toInt()}G',
                      style: FieldManual.readout(
                        fontSize: 11,
                        color: FieldManual.mutedBone,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: palette.accent,
                  borderRadius: BorderRadius.circular(4),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? CupertinoActivityIndicator(
                          color: palette.onAccent)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bookmark_outline,
                                color: palette.onAccent, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'SAVE MEAL',
                              style: FieldManual.label(
                                color: palette.onAccent,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
