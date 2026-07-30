import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/field_manual.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/animated_count.dart';
import '../../../../core/widgets/meter_bar.dart';
import '../../../../providers/supplement_providers.dart';

class SupplementConsistencyCard extends ConsumerWidget {
  const SupplementConsistencyCard({super.key, required this.supplementId, required this.name});

  final int supplementId;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consistencyAsync = ref.watch(supplementConsistencyProvider(supplementId));

    final palette = AppColors.of(context);
    return consistencyAsync.when(
      data: (pct) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      // User content — never uppercased.
                      name,
                      style: FieldManual.title().copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    // Progress bar — bone fill on a hairline track. The
                    // traffic-light tiers retire; the readout carries the
                    // number (DESIGN.md bar idiom).
                    MeterBar(
                      fraction: pct.clamp(0.0, 1.0).toDouble(),
                      fill: FieldManual.bone.withValues(alpha: 0.85),
                      height: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AnimatedCount(
                value: pct * 100,
                builder: (context, animated) => Text(
                  '${animated.round()}%',
                  style: FieldManual.readout(fontSize: 15),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, st) {
        AppLogger.error(
          'Supplement consistency load failed (id=$supplementId)',
          error: e,
          stack: st,
        );
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            children: [
              Icon(CupertinoIcons.exclamationmark_circle,
                  size: 16, color: palette.destructive),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Unable to load $name consistency',
                  style: FieldManual.body(
                    fontSize: 12,
                    color: FieldManual.mutedBone,
                  ),
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                onPressed: () =>
                    ref.invalidate(supplementConsistencyProvider(supplementId)),
                child: Text(
                  'RETRY',
                  style: FieldManual.label(
                    fontSize: 10,
                    color: palette.accent,
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
