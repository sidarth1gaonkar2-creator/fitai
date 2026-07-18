import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/field_manual.dart';

/// Field Manual segmented control shared by the Progress feature: field
/// ground, hairline border, sharp 4px geometry, the active segment filled
/// with the live accent carrying on-accent mono type. Mirrors the idiom of
/// the nutrition tab toggle / workouts pill bar.
///
/// Presentation only — same tap surface and callback shape as the stock
/// segmented controls it replaces.
class FmSegmented<T> extends StatelessWidget {
  const FmSegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.fontSize = 11,
  });

  /// (value, label) pairs. Labels are given in sentence case — the uppercase
  /// is visual only; the spoken label stays as provided.
  final List<(T, String)> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Container(
      // Scales with Dynamic Type; base height keeps ≥44pt targets.
      height: MediaQuery.textScalerOf(context).scale(44),
      decoration: BoxDecoration(
        color: FieldManual.field,
        border: Border.all(color: FieldManual.hairline),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          for (final (value, label) in segments)
            Expanded(
              child: Semantics(
                label: label,
                button: true,
                selected: value == selected,
                child: ExcludeSemantics(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onChanged(value);
                    },
                    child: AnimatedContainer(
                      duration: reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 200),
                      curve: Curves.easeOutQuart,
                      decoration: BoxDecoration(
                        color: value == selected
                            ? palette.accent
                            : const Color(0x00000000),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        label.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: FieldManual.label(
                          fontSize: fontSize,
                          color: value == selected
                              ? palette.onAccent
                              : FieldManual.mutedBone,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
