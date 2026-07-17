import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/field_manual.dart';
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
      backgroundColor: FieldManual.ink,
      navigationBar: CupertinoNavigationBar(
        middle: Text('SUPPLEMENTS', style: FieldManual.title()),
        backgroundColor: FieldManual.ink.withValues(alpha: 0.82),
        border: const Border(
          bottom: BorderSide(color: FieldManual.hairline),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            showCupertinoModalPopup(
              context: context,
              builder: (_) => const AddSupplementSheet(),
            );
          },
          child: const Icon(CupertinoIcons.add,
              size: 22,
              color: FieldManual.bone,
              semanticLabel: 'Add supplement'),
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
                      'NO SUPPLEMENTS YET',
                      style: FieldManual.title(),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap + to add from the library',
                      style: FieldManual.body(
                        fontSize: 14,
                        color: FieldManual.mutedBone,
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
                      '30-DAY CONSISTENCY',
                      style: FieldManual.title(),
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
                    'ACTIVE',
                    style: FieldManual.title(),
                  ),
                  const SizedBox(height: 10),
                  if (active.isEmpty)
                    Text(
                      'No active supplements',
                      style: FieldManual.body(
                        fontSize: 14,
                        color: FieldManual.mutedBone,
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
                      'INACTIVE',
                      style: FieldManual.title(),
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
                      width: double.infinity, height: 60, borderRadius: 8),
                ),
              ),
            ),
          ),
          error: (_, _) => Center(
            child: Text(
              'Failed to load supplements.',
              style: FieldManual.body(),
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

  /// Deleting is irreversible (removes the supplement and its history), so
  /// a one-tap trash press asks first. Confirm calls the same [onDelete].
  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text('Delete $name?'),
        content: const Text('This removes it and its history.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    if (confirmed == true) onDelete();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  // User content — never uppercased. Inactive rows stay
                  // ≥4.5:1 (mutedBone at full alpha); the strikethrough
                  // carries the paused state, not a faded colour.
                  name,
                  style: FieldManual.title(
                    color: isActive
                        ? FieldManual.bone
                        : FieldManual.mutedBone,
                  ).copyWith(
                    fontSize: 15,
                    decoration:
                        isActive ? null : TextDecoration.lineThrough,
                    decorationColor: FieldManual.mutedBone,
                  ),
                ),
                Text(
                  // Dosage stamp — mono designation carrying the number.
                  '$dosage · $timing'.toUpperCase(),
                  style: FieldManual.label(fontSize: 10),
                ),
              ],
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.all(6),
            minimumSize: const Size(44, 44),
            onPressed: onToggle,
            child: Icon(
              isActive
                  ? CupertinoIcons.pause_circle
                  : CupertinoIcons.play_circle,
              // One accent voice for interactive controls — the icon shape
              // (pause vs play) carries the state, not a colour code.
              color: palette.accent,
              size: 22,
              semanticLabel:
                  isActive ? 'Pause supplement' : 'Resume supplement',
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.all(6),
            minimumSize: const Size(44, 44),
            onPressed: () => _confirmDelete(context),
            child: Icon(
              CupertinoIcons.trash,
              color: palette.destructive,
              size: 20,
              semanticLabel: 'Delete supplement',
            ),
          ),
        ],
      ),
    );
  }
}
