import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
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
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                  color: palette.text.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Toggle
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Add Supplement',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: palette.text,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => setState(() => _isCustom = !_isCustom),
                    child: Text(
                      _isCustom ? 'Library' : 'Custom',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
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
                  style: TextStyle(color: palette.text),
                  placeholderStyle: TextStyle(
                      color: palette.textSecondary),
                  decoration: BoxDecoration(
                    color: palette.background,
                    borderRadius: BorderRadius.circular(10),
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
                        style: TextStyle(color: palette.text),
                        placeholderStyle: TextStyle(
                            color: palette.textSecondary),
                        decoration: BoxDecoration(
                          color: palette.background,
                          borderRadius: BorderRadius.circular(10),
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
                        style: TextStyle(color: palette.text),
                        placeholderStyle: TextStyle(
                            color: palette.textSecondary),
                        decoration: BoxDecoration(
                          color: palette.background,
                          borderRadius: BorderRadius.circular(10),
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
                    backgroundColor: palette.background,
                    thumbColor: palette.accent,
                    children: {
                      for (final t in SupplementTiming.values)
                        t: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(t.label,
                              style: const TextStyle(
                                  fontFamily: 'Poppins', fontSize: 10)),
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
                    borderRadius: BorderRadius.circular(12),
                    onPressed: _addCustom,
                    child: const Text(
                      'Add',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
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
                        style: TextStyle(
                          fontFamily: 'LeagueSpartan',
                          fontSize: 14,
                          color: palette.textSecondary,
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
          color: palette.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rating badge
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: ratingColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                '${supplement.rating}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
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
                    supplement.name,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: palette.text,
                    ),
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
                          supplement.category,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: palette.accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          supplement.dose,
                          style: TextStyle(
                            fontFamily: 'LeagueSpartan',
                            fontSize: 11,
                            color: palette.textSecondary,
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
                      style: TextStyle(
                        fontFamily: 'LeagueSpartan',
                        fontSize: 12,
                        color: palette.textSecondary,
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
                child: Padding(
                  padding: const EdgeInsets.all(4),
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
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                  color: palette.text.withValues(alpha: 0.2),
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
                            supplement.name,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                              color: palette.text,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: palette.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            supplement.category,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: palette.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Dose: ${supplement.dose}  ·  Timing: ${supplement.timing}',
                      style: TextStyle(
                        fontFamily: 'LeagueSpartan',
                        fontSize: 13,
                        color: palette.textSecondary,
                      ),
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
                        borderRadius: BorderRadius.circular(12),
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(context);
                          onAdd();
                        },
                        child: const Text(
                          'Add to My Supplements',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
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
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: color,
              ),
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
                      decoration: BoxDecoration(
                        color: AppColors.of(context).textSecondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontFamily: 'LeagueSpartan',
                        fontSize: 13,
                        color: AppColors.of(context).textSecondary,
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
