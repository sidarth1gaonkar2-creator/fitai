import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/field_manual.dart';

/// Field Manual selectable option card: field surface with a hairline border;
/// selection is marked by the live accent (border + tint fill + check), never
/// colour alone — the check icon and semantics carry the state too.
///
/// Presentation only: same constructor, same single-tap behaviour, and the
/// title/subtitle strings are rendered verbatim (widget tests find them).
class SelectableCard extends StatelessWidget {
  const SelectableCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      selected: isSelected,
      child: AnimatedContainer(
        duration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected
              ? palette.accent.withValues(alpha: 0.18)
              : palette.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? palette.accent : palette.border,
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(8),
          splashColor: palette.text.withValues(alpha: 0.08),
          highlightColor: palette.text.withValues(alpha: 0.04),
          child: Padding(
            // 40pt icon + 14pt vertical padding keeps the row ≥ 44pt tall.
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: palette.surfaceElevated,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color:
                        isSelected ? palette.accent : palette.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: FieldManual.title(color: palette.text),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: FieldManual.body(
                            fontSize: 13,
                            color: palette.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: palette.accent,
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
