import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, Theme;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
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
    final textTheme = Theme.of(context).textTheme;

    final totalCal = widget.entries.fold<double>(0, (s, e) => s + e.calories);
    final totalPro = widget.entries.fold<double>(0, (s, e) => s + e.protein);
    final totalCarb = widget.entries.fold<double>(0, (s, e) => s + e.carbs);
    final totalFat = widget.entries.fold<double>(0, (s, e) => s + e.fat);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
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
                    color: palette.textSecondary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Save Meal',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: palette.text,
                ),
              ),
              const SizedBox(height: 16),
              CupertinoTextField(
                controller: _nameController,
                placeholder: 'Meal name',
                autofocus: true,
                style: TextStyle(color: palette.text, fontSize: 16),
                placeholderStyle: TextStyle(color: palette.textSecondary),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: palette.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
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
                  color: palette.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
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
                              style: textTheme.bodyMedium
                                  ?.copyWith(color: palette.text),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${e.calories.toInt()} kcal',
                            style: textTheme.bodySmall
                                ?.copyWith(color: palette.textSecondary),
                          ),
                        ],
                      ),
                      if (e != widget.entries.last) const SizedBox(height: 4),
                    ],
                    const SizedBox(height: 10),
                    Container(
                      height: 1,
                      color: palette.border,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Total',
                            style: textTheme.bodyMedium?.copyWith(
                              color: palette.text,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${totalCal.toInt()} kcal',
                          style: textTheme.bodyMedium?.copyWith(
                            color: palette.text,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'P ${totalPro.toInt()}g · C ${totalCarb.toInt()}g · F ${totalFat.toInt()}g',
                      style: textTheme.bodySmall
                          ?.copyWith(color: palette.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: palette.accent,
                  borderRadius: BorderRadius.circular(12),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const CupertinoActivityIndicator(
                          color: CupertinoColors.white)
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bookmark_outline,
                                color: CupertinoColors.white, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Save Meal',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                color: CupertinoColors.white,
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
