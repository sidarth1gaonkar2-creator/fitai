import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/field_manual.dart';
import '../../../../models/enums.dart';
import '../../../../models/supplement.dart';
import '../../../../providers/supplement_providers.dart';
import '../../../../services/supplement_api_service.dart';

class AddSupplementSheet extends ConsumerStatefulWidget {
  const AddSupplementSheet({super.key});

  @override
  ConsumerState<AddSupplementSheet> createState() => _AddSupplementSheetState();
}

class _AddSupplementSheetState extends ConsumerState<AddSupplementSheet> {
  bool _isCustom = false;
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _unitController = TextEditingController(text: 'mg');
  SupplementTiming _timing = SupplementTiming.morning;

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _addFromApi(ApiSupplement api) async {
    // Parse dose string to extract number and unit
    final doseMatch = RegExp(r'([\d.,-]+)\s*(.*)').firstMatch(api.dose);
    final dosage = doseMatch?.group(1)?.replaceAll(',', '.') ?? api.dose;
    final unit = doseMatch?.group(2)?.trim() ?? 'mg';

    final supplement = Supplement()
      ..name = api.name
      ..dosage = dosage.isNotEmpty ? dosage : api.dose
      ..unit = unit.isNotEmpty ? unit : 'mg'
      ..timing = _timingFromString(api.timing)
      ..isActive = true;
    await addSupplement(ref, supplement);
    if (mounted) Navigator.pop(context);
  }

  SupplementTiming _timingFromString(String timing) {
    final lower = timing.toLowerCase();
    if (lower.contains('uyku') || lower.contains('bed') || lower.contains('gece')) {
      return SupplementTiming.beforeBed;
    }
    if (lower.contains('öğün') || lower.contains('meal') || lower.contains('yemek')) {
      return SupplementTiming.withMeal;
    }
    if (lower.contains('spor öncesi') || lower.contains('pre')) {
      return SupplementTiming.morning;
    }
    if (lower.contains('akşam') || lower.contains('evening')) {
      return SupplementTiming.evening;
    }
    return SupplementTiming.morning;
  }

  Future<void> _addCustom() async {
    final name = _nameController.text.trim();
    final dosage = _dosageController.text.trim();
    final unit = _unitController.text.trim();
    if (name.isEmpty || dosage.isEmpty) return;

    final supplement = Supplement()
      ..name = name
      ..dosage = dosage
      ..unit = unit.isNotEmpty ? unit : 'mg'
      ..timing = _timing
      ..isActive = true;
    await addSupplement(ref, supplement);
    if (mounted) Navigator.pop(context);
  }

  void _showDetails(ApiSupplement api) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => _SupplementDetailSheet(
        supplement: api,
        onAdd: () => _addFromApi(api),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(supplementCatalogProvider);

    final palette = AppColors.of(context);
    return Container(
      decoration: const BoxDecoration(
        // Sheets are ink by doctrine, 12pt top radius (DESIGN.md).
        color: FieldManual.ink,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: FieldManual.hairlineStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Toggle
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'ADD SUPPLEMENT',
                      style: FieldManual.title(),
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => setState(() => _isCustom = !_isCustom),
                    child: Text(
                      _isCustom ? 'LIBRARY' : 'CUSTOM',
                      style: FieldManual.label(
                        fontSize: 11,
                        color: palette.accent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_isCustom) ...[
                // Custom supplement form
                CupertinoTextField(
                  controller: _nameController,
                  placeholder: 'Supplement Name',
                  style: FieldManual.body(),
                  placeholderStyle:
                      FieldManual.body(color: FieldManual.mutedBone),
                  decoration: BoxDecoration(
                    color: FieldManual.fieldRaised,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: FieldManual.hairline),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: CupertinoTextField(
                        controller: _dosageController,
                        placeholder: 'Dose',
                        keyboardType: TextInputType.number,
                        // Numeric entry reads as an instrument value.
                        style: FieldManual.readout(fontSize: 15),
                        placeholderStyle:
                            FieldManual.body(color: FieldManual.mutedBone),
                        decoration: BoxDecoration(
                          color: FieldManual.fieldRaised,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: FieldManual.hairline),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CupertinoTextField(
                        controller: _unitController,
                        placeholder: 'Unit',
                        style: FieldManual.body(),
                        placeholderStyle:
                            FieldManual.body(color: FieldManual.mutedBone),
                        decoration: BoxDecoration(
                          color: FieldManual.fieldRaised,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: FieldManual.hairline),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoSlidingSegmentedControl<SupplementTiming>(
                    groupValue: _timing,
                    backgroundColor: FieldManual.fieldRaised,
                    thumbColor: palette.accent,
                    children: {
                      for (final t in SupplementTiming.values)
                        t: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            t.label.toUpperCase(),
                            // Accent thumb carries the on-accent ink; resting
                            // segments stay muted bone on the raised field.
                            style: FieldManual.label(
                              fontSize: 11,
                              color: t == _timing
                                  ? palette.onAccent
                                  : FieldManual.mutedBone,
                            ),
                          ),
                        ),
                    },
                    onValueChanged: (v) {
                      if (v != null) setState(() => _timing = v);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    color: palette.accent,
                    borderRadius: BorderRadius.circular(4),
                    onPressed: _addCustom,
                    child: Text(
                      'ADD',
                      style: FieldManual.title(color: palette.onAccent),
                    ),
                  ),
                ),
              ] else ...[
                // API-powered library list
                SizedBox(
                  height: 420,
                  child: catalogAsync.when(
                    data: (items) => ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final api = items[index];
                        return _ApiSupplementCard(
                          supplement: api,
                          onTap: () => _showDetails(api),
                          onAdd: () {
                            HapticFeedback.selectionClick();
                            _addFromApi(api);
                          },
                        );
                      },
                    ),
                    loading: () => const Center(
                      child: CupertinoActivityIndicator(),
                    ),
                    error: (_, _) => Center(
                      child: Text(
                        'Failed to load supplements.',
                        style: FieldManual.body(
                          fontSize: 14,
                          color: FieldManual.mutedBone,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── API Supplement Card ────────────────────────────────────────────────────

class _ApiSupplementCard extends StatelessWidget {
  const _ApiSupplementCard({
    required this.supplement,
    required this.onTap,
    required this.onAdd,
  });

  final ApiSupplement supplement;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final ratingColor = _ratingColor(supplement.rating, palette);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: FieldManual.field,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: FieldManual.hairline),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rating badge — evidence-grade tiers keep their colour as a
            // small scanning aid (like nutrient icons).
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: ratingColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: Text(
                '${supplement.rating}',
                style: FieldManual.readout(
                  fontSize: 13,
                  color: ratingColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    // Catalog content — never uppercased.
                    supplement.name,
                    style: FieldManual.title().copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  // Category tag
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: palette.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          supplement.category.toUpperCase(),
                          style: FieldManual.label(
                            fontSize: 11,
                            color: palette.accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          supplement.dose,
                          style: FieldManual.readout(
                            fontSize: 10,
                            color: FieldManual.mutedBone,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (supplement.benefitsSummary.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      supplement.benefitsSummary,
                      style: FieldManual.body(
                        fontSize: 12,
                        color: FieldManual.mutedBone,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Add button
            Semantics(
              button: true,
              label: 'Add supplement',
              child: GestureDetector(
                onTap: onAdd,
                behavior: HitTestBehavior.opaque,
                // ≥44pt tap target; the icon stays visually small.
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  alignment: Alignment.center,
                  child: Icon(CupertinoIcons.add_circled,
                      color: palette.accent, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _ratingColor(int rating, Palette palette) {
    if (rating >= 5) return palette.success;
    if (rating >= 4) return palette.accent;
    if (rating >= 3) return palette.warning;
    return palette.textSecondary;
  }
}

// ─── Supplement Detail Sheet ────────────────────────────────────────────────

class _SupplementDetailSheet extends StatelessWidget {
  const _SupplementDetailSheet({
    required this.supplement,
    required this.onAdd,
  });

  final ApiSupplement supplement;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      decoration: const BoxDecoration(
        // Sheets are ink by doctrine, 12pt top radius (DESIGN.md).
        color: FieldManual.ink,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: FieldManual.hairlineStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            // Catalog content — never uppercased.
                            supplement.name,
                            style: FieldManual.headline(),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: palette.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            supplement.category.toUpperCase(),
                            style: FieldManual.label(
                              fontSize: 10,
                              color: palette.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      // Dose stamp — mono designation carrying the numbers.
                      'DOSE: ${supplement.dose}  ·  TIMING: ${supplement.timing}'
                          .toUpperCase(),
                      style: FieldManual.label(fontSize: 10),
                    ),
                    const SizedBox(height: 20),

                    // Benefits
                    if (supplement.benefits.isNotEmpty) ...[
                      _DetailSection(
                        title: 'Benefits',
                        items: supplement.benefits,
                        icon: CupertinoIcons.checkmark_shield,
                        color: palette.success,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Who should use
                    if (supplement.whoShouldUse.isNotEmpty) ...[
                      _DetailSection(
                        title: 'Who Should Use',
                        items: supplement.whoShouldUse,
                        icon: CupertinoIcons.person_2,
                        color: palette.accent,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Suggestions / Side Effects
                    if (supplement.suggestions.isNotEmpty) ...[
                      _DetailSection(
                        title: 'Tips & Notes',
                        items: supplement.suggestions,
                        icon: CupertinoIcons.lightbulb,
                        color: palette.warning,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Add button
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        color: palette.accent,
                        borderRadius: BorderRadius.circular(4),
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(context);
                          onAdd();
                        },
                        child: Text(
                          'ADD TO MY SUPPLEMENTS',
                          style: FieldManual.title(color: palette.onAccent)
                              .copyWith(fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.items,
    required this.icon,
    required this.color,
  });

  final String title;
  final List<String> items;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Section colour survives on the small icon as a scanning aid;
            // the header itself is a muted mono designation.
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              title.toUpperCase(),
              style: FieldManual.label(fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: FieldManual.mutedBone,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: FieldManual.body(
                        fontSize: 13,
                        color: FieldManual.mutedBone,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
