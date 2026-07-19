import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/field_manual.dart';
import '../../../../core/utils/logger.dart';
import '../../../../models/enums.dart';
import '../../../../providers/supplement_providers.dart';

/// Daily supplements as a Field Manual checklist panel. Dashboard-only.
class SupplementChecklistCard extends ConsumerWidget {
  const SupplementChecklistCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppColors.of(context);
    final checklistAsync = ref.watch(supplementChecklistProvider);

    return checklistAsync.when(
      data: (items) {
        // Empty state — always show the card, teaching the feature.
        if (items.isEmpty) {
          return _panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('SUPPLEMENTS', style: FieldManual.label(fontSize: 11)),
                const SizedBox(height: 10),
                Text(
                  'Add supplements to track your daily intake.',
                  style: FieldManual.body(
                    color: FieldManual.mutedBone,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Semantics(
                  button: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.push('/supplements');
                    },
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 44),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: palette.accent.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        '+ ADD SUPPLEMENTS',
                        style: FieldManual.label(
                          color: palette.accent,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Active checklist.
        final takenCount = items.where((i) => i.taken).length;
        final complete = takenCount == items.length;

        return _panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'SUPPLEMENTS',
                      style: FieldManual.label(fontSize: 11),
                    ),
                  ),
                  Text(
                    '$takenCount/${items.length}',
                    style: FieldManual.readout(
                      fontSize: 13,
                      color: complete
                          ? palette.accent
                          : FieldManual.mutedBone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...items.map((item) => Semantics(
                    button: true,
                    checked: item.taken,
                    label: item.supplement.name,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        toggleSupplementTaken(
                            ref, item.supplement.id, !item.taken);
                      },
                      behavior: HitTestBehavior.opaque,
                      // ≥44pt tap target per row; the state is spoken via
                      // the Semantics above, so the visual text is excluded
                      // to avoid double-reading.
                      child: ExcludeSemantics(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 44),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration:
                                    MediaQuery.disableAnimationsOf(context)
                                        ? Duration.zero
                                        : const Duration(milliseconds: 200),
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: item.taken ? palette.accent : null,
                                  borderRadius: BorderRadius.circular(4),
                                  border: item.taken
                                      ? null
                                      : Border.all(
                                          color: FieldManual.hairlineStrong,
                                          width: 1.5,
                                        ),
                                ),
                                child: item.taken
                                    ? Icon(
                                        CupertinoIcons.checkmark,
                                        size: 13,
                                        color: palette.onAccent,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.supplement.name,
                                  style: FieldManual.body(
                                    fontSize: 14,
                                    color: item.taken
                                        ? FieldManual.mutedBone
                                        : FieldManual.bone,
                                  ).copyWith(
                                    decoration: item.taken
                                        ? TextDecoration.lineThrough
                                        : null,
                                    decorationColor: FieldManual.mutedBone,
                                  ),
                                ),
                              ),
                              Text(
                                '${item.supplement.dosage} ${item.supplement.unit}'
                                    .toUpperCase(),
                                style: FieldManual.label(fontSize: 8),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                item.supplement.timing.label.toUpperCase(),
                                style: FieldManual.label(
                                  color: FieldManual.mutedBone,
                                  fontSize: 8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )),
            ],
          ),
        );
      },
      loading: () => Container(
        height: 100,
        decoration: BoxDecoration(
          color: FieldManual.field,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: FieldManual.hairline),
        ),
      ),
      error: (e, st) {
        AppLogger.error(
          'Supplement checklist load failed',
          error: e,
          stack: st,
        );
        return _panel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.exclamationmark_circle,
                size: 24,
                color: FieldManual.alert,
              ),
              const SizedBox(height: 8),
              Text(
                'Could not load supplements.',
                style: FieldManual.body(fontSize: 14),
              ),
              const SizedBox(height: 10),
              CupertinoButton(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                color: FieldManual.fieldRaised,
                borderRadius: BorderRadius.circular(4),
                onPressed: () => ref.invalidate(supplementChecklistProvider),
                child: Text('RETRY', style: FieldManual.title()),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _panel({required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: FieldManual.field,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: FieldManual.hairline),
        ),
        child: child,
      );
}
