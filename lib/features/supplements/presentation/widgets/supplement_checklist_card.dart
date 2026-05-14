import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../models/enums.dart';
import '../../../../providers/supplement_providers.dart';

class SupplementChecklistCard extends ConsumerWidget {
  const SupplementChecklistCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checklistAsync = ref.watch(supplementChecklistProvider);

    final palette = AppColors.of(context);
    return checklistAsync.when(
      data: (items) {
        // Empty state — always show the card
        if (items.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(CupertinoIcons.capsule,
                        color: palette.accent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Supplements',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: palette.text,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Add supplements to track your daily intake',
                  style: TextStyle(
                    fontFamily: 'LeagueSpartan',
                    fontSize: 13,
                    color: palette.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    color: palette.accent,
                    borderRadius: BorderRadius.circular(10),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      context.push('/supplements');
                    },
                    child: const Text(
                      '+ Add Supplements',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Active checklist
        final takenCount = items.where((i) => i.taken).length;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(CupertinoIcons.capsule,
                      color: palette.accent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Supplements',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: palette.text,
                      ),
                    ),
                  ),
                  Text(
                    '$takenCount/${items.length}',
                    style: TextStyle(
                      fontFamily: 'LeagueSpartan',
                      fontSize: 13,
                      color: takenCount == items.length
                          ? palette.success
                          : palette.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        toggleSupplementTaken(
                            ref, item.supplement.id, !item.taken);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: item.taken
                                  ? palette.accent
                                  : palette.surface,
                              borderRadius: BorderRadius.circular(6),
                              border: item.taken
                                  ? null
                                  : Border.all(
                                      color: palette.accent, width: 1.5),
                            ),
                            child: item.taken
                                ? const Icon(CupertinoIcons.checkmark,
                                    size: 14, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.supplement.name,
                              style: TextStyle(
                                fontFamily: 'LeagueSpartan',
                                fontSize: 14,
                                color: item.taken
                                    ? palette.textSecondary
                                    : palette.text,
                                decoration: item.taken
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          Text(
                            '${item.supplement.dosage} ${item.supplement.unit}',
                            style: TextStyle(
                              fontFamily: 'LeagueSpartan',
                              fontSize: 12,
                              color: palette.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item.supplement.timing.label,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: palette.accent.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
            ],
          ),
        );
      },
      loading: () => const ShimmerBox(
          width: double.infinity, height: 100, borderRadius: 16),
      error: (e, st) {
        AppLogger.error(
          'Supplement checklist load failed',
          error: e,
          stack: st,
        );
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.exclamationmark_circle,
                  size: 28, color: palette.destructive),
              const SizedBox(height: 8),
              Text(
                'Could not load supplements',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: palette.text,
                ),
              ),
              const SizedBox(height: 8),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
                color: palette.accent,
                borderRadius: BorderRadius.circular(8),
                onPressed: () => ref.invalidate(supplementChecklistProvider),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
