import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../models/enums.dart';
import '../../../providers/supplement_providers.dart';
import 'widgets/add_supplement_sheet.dart';
import 'widgets/supplement_consistency_card.dart';

class SupplementsScreen extends ConsumerWidget {
  const SupplementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supplementsAsync = ref.watch(allSupplementsProvider);

    final palette = AppColors.of(context);
    return CupertinoPageScaffold(
      backgroundColor: palette.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Supplements'),
        backgroundColor: palette.background.withValues(alpha: 0.8),
        border: null,
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            showCupertinoModalPopup(
              context: context,
              builder: (_) => const AddSupplementSheet(),
            );
          },
          child: const Icon(CupertinoIcons.add, size: 22),
        ),
      ),
      child: SafeArea(
        child: supplementsAsync.when(
          data: (supplements) {
            if (supplements.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.capsule,
                        size: 64,
                        color: palette.accent.withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    Text(
                      'No supplements yet',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                        color: palette.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap + to add from the library',
                      style: TextStyle(
                        fontFamily: 'LeagueSpartan',
                        fontSize: 14,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            final active =
                supplements.where((s) => s.isActive).toList();
            final inactive =
                supplements.where((s) => !s.isActive).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 30-day consistency
                  if (active.isNotEmpty) ...[
                    Text(
                      '30-Day Consistency',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: palette.text,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...active.map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: SupplementConsistencyCard(
                            supplementId: s.id,
                            name: s.name,
                          ),
                        )),
                    const SizedBox(height: 20),
                  ],

                  // Active supplements
                  Text(
                    'Active',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: palette.text,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (active.isEmpty)
                    Text(
                      'No active supplements',
                      style: TextStyle(
                        fontFamily: 'LeagueSpartan',
                        fontSize: 14,
                        color: palette.textSecondary,
                      ),
                    )
                  else
                    ...active.map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _SupplementTile(
                            name: s.name,
                            dosage: '${s.dosage} ${s.unit}',
                            timing: s.timing.label,
                            isActive: true,
                            onToggle: () {
                              HapticFeedback.mediumImpact();
                              deactivateSupplement(ref, s.id);
                            },
                            onDelete: () {
                              HapticFeedback.heavyImpact();
                              deleteSupplement(ref, s.id);
                            },
                          ),
                        )),

                  // Inactive supplements
                  if (inactive.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Inactive',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: palette.text,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...inactive.map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _SupplementTile(
                            name: s.name,
                            dosage: '${s.dosage} ${s.unit}',
                            timing: s.timing.label,
                            isActive: false,
                            onToggle: () {
                              HapticFeedback.mediumImpact();
                              reactivateSupplement(ref, s.id);
                            },
                            onDelete: () {
                              HapticFeedback.heavyImpact();
                              deleteSupplement(ref, s.id);
                            },
                          ),
                        )),
                  ],
                ],
              ),
            );
          },
          loading: () => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: List.generate(
                5,
                (_) => const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: ShimmerBox(
                      width: double.infinity, height: 60, borderRadius: 12),
                ),
              ),
            ),
          ),
          error: (_, _) => Center(
            child: Text(
              'Failed to load supplements.',
              style: TextStyle(color: palette.text),
            ),
          ),
        ),
      ),
    );
  }
}

class _SupplementTile extends StatelessWidget {
  const _SupplementTile({
    required this.name,
    required this.dosage,
    required this.timing,
    required this.isActive,
    required this.onToggle,
    required this.onDelete,
  });

  final String name;
  final String dosage;
  final String timing;
  final bool isActive;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: isActive
                        ? palette.text
                        : palette.text.withValues(alpha: 0.4),
                  ),
                ),
                Text(
                  '$dosage · $timing',
                  style: TextStyle(
                    fontFamily: 'LeagueSpartan',
                    fontSize: 12,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.all(6),
            onPressed: onToggle,
            child: Icon(
              isActive
                  ? CupertinoIcons.pause_circle
                  : CupertinoIcons.play_circle,
              color: isActive ? palette.warning : palette.success,
              size: 22,
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.all(6),
            onPressed: onDelete,
            child: Icon(
              CupertinoIcons.trash,
              color: palette.destructive,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
