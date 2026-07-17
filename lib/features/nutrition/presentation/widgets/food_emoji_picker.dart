import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/field_manual.dart';
import '../../../../data/food_emojis.dart';

/// Result of [FoodEmojiPicker.show]. Distinguishes the three outcomes:
///   * [FoodEmojiPickerResult.picked] — user chose `emoji`
///   * [FoodEmojiPickerResult.cleared] — user explicitly cleared (`emoji` is null)
///   * `null` return value — sheet dismissed without choosing
class FoodEmojiPickerResult {
  const FoodEmojiPickerResult._(this.emoji);
  final String? emoji;

  factory FoodEmojiPickerResult.picked(String e) =>
      FoodEmojiPickerResult._(e);
  static const FoodEmojiPickerResult cleared = FoodEmojiPickerResult._(null);
}

/// Full-catalogue emoji picker for naming a saved meal, quick-add preset,
/// or any other user-named food row.
///
/// Layout:
///   * 16-glyph quick-pick row at the top (no scrolling needed)
///   * Categorised wrap grid below: Protein / Grains / Fruits / Vegetables /
///     Dairy & Drinks / Snacks / Meals — each rendered as 8 emojis per row
///   * Currently-selected glyph has an accent ring; tapping it pops with a
///     [FoodEmojiPickerResult.cleared] result so the caller can clear the
///     selection.
///
/// Usage:
/// ```dart
/// final res = await FoodEmojiPicker.show(context, current: meal.emoji);
/// if (res != null) setState(() => meal.emoji = res.emoji);
/// ```
class FoodEmojiPicker extends StatelessWidget {
  const FoodEmojiPicker({
    super.key,
    this.selectedEmoji,
    required this.onSelected,
    this.scrollController,
  });

  final String? selectedEmoji;
  final ValueChanged<String?> onSelected;
  final ScrollController? scrollController;

  /// Returns:
  ///   * `FoodEmojiPickerResult.picked(emoji)` — user chose a glyph
  ///   * `FoodEmojiPickerResult.cleared` — user explicitly cleared
  ///   * `null` — sheet was dismissed (outside-tap, swipe-down) → no change
  static Future<FoodEmojiPickerResult?> show(
    BuildContext context, {
    String? current,
  }) {
    return showCupertinoModalPopup<FoodEmojiPickerResult?>(
      context: context,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (sheetCtx, scrollController) {
          return FoodEmojiPicker(
            selectedEmoji: current,
            scrollController: scrollController,
            onSelected: (emoji) {
              final result = emoji == null
                  ? FoodEmojiPickerResult.cleared
                  : FoodEmojiPickerResult.picked(emoji);
              Navigator.of(sheetCtx).pop(result);
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Container(
      decoration: const BoxDecoration(
        // Sheets are ink by doctrine, 12pt top radius (DESIGN.md).
        color: FieldManual.ink,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        children: [
          // Grabber
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 8),
            child: Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: FieldManual.hairlineStrong,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              children: [
                Text(
                  'PICK AN ICON',
                  style: FieldManual.title(),
                ),
                const Spacer(),
                if (selectedEmoji != null)
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      onSelected(null);
                    },
                    child: Text(
                      'CLEAR',
                      style: FieldManual.label(
                        fontSize: 11,
                        color: palette.accent,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: CustomScrollView(
              controller: scrollController,
              slivers: [
                _QuickPicksSliver(
                  selected: selectedEmoji,
                  onTap: _handleTap,
                ),
                for (final entry in FoodEmojis.categories.entries) ...[
                  _CategoryHeader(label: entry.key),
                  _EmojiGridSliver(
                    emojis: entry.value,
                    selected: selectedEmoji,
                    onTap: _handleTap,
                  ),
                ],
                const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleTap(String emoji) {
    HapticFeedback.selectionClick();
    // Tapping the already-selected glyph clears it; everything else picks.
    onSelected(emoji == selectedEmoji ? null : emoji);
  }
}

class _QuickPicksSliver extends StatelessWidget {
  const _QuickPicksSliver({required this.selected, required this.onTap});

  final String? selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'QUICK PICKS',
                style: FieldManual.label(fontSize: 10),
              ),
            ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final e in FoodEmojis.quickPicks)
                  _EmojiTile(
                    emoji: e,
                    isSelected: e == selected,
                    onTap: () => onTap(e),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
        child: Text(
          label.toUpperCase(),
          style: FieldManual.label(fontSize: 10),
        ),
      ),
    );
  }
}

class _EmojiGridSliver extends StatelessWidget {
  const _EmojiGridSliver({
    required this.emojis,
    required this.selected,
    required this.onTap,
  });

  final List<String> emojis;
  final String? selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverToBoxAdapter(
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final e in emojis)
              _EmojiTile(
                emoji: e,
                isSelected: e == selected,
                onTap: () => onTap(e),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmojiTile extends StatelessWidget {
  const _EmojiTile({
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 150),
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? palette.accent.withValues(alpha: 0.18)
              : FieldManual.fieldRaised,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? palette.accent : FieldManual.hairline,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 22)),
      ),
    );
  }
}

/// Compact preview tile + "Change" link that opens the full picker. Use this
/// in save-meal / quick-add forms instead of an inline emoji row so the
/// surface stays uncluttered.
class FoodEmojiSelector extends StatelessWidget {
  const FoodEmojiSelector({
    super.key,
    required this.emoji,
    required this.onChanged,
    this.label = 'Icon',
  });

  final String? emoji;
  final ValueChanged<String?> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        final result = await FoodEmojiPicker.show(context, current: emoji);
        // `null` = sheet dismissed (no change). `cleared` and `picked(...)`
        // both flow through onChanged so the caller can update state.
        if (result == null) return;
        onChanged(result.emoji);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          // Input-adjacent surface: raised field, hairline, sharp corners.
          color: FieldManual.fieldRaised,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: FieldManual.hairline),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                emoji ?? FoodEmojis.defaultEmoji,
                style: const TextStyle(fontSize: 22),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: FieldManual.label(fontSize: 10),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    emoji == null ? 'Tap to choose' : 'Tap to change',
                    style: FieldManual.body(
                      fontSize: 12,
                      color: FieldManual.mutedBone,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: palette.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
