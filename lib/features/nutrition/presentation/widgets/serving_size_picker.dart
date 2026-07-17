import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/nutrient_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/field_manual.dart';
import '../../../../core/utils/unit_converter.dart';
import '../../../../providers/unit_system_provider.dart';
import '../../domain/food_search_result.dart';

enum ServingMode { serving, container, weight }

/// Output of the picker. The caller uses this to scale [FoodSearchResult]
/// nutrition values. Always expressed in grams under the hood so existing
/// `food.caloriesFor(grams)` helpers continue to work unchanged.
class ServingSelection {
  const ServingSelection({
    required this.totalGrams,
    required this.label,
    required this.mode,
  });

  /// Effective grams consumed — feeds into the per-100g scaling helpers.
  final double totalGrams;

  /// Human-readable summary used as the stored `servingUnit` on FoodEntry,
  /// e.g. "1.5 bowl", "1/2 container", "200g".
  final String label;

  final ServingMode mode;
}

/// Three-mode serving picker.
///
/// • **Serving** — quantity stepper (0.25, 0.5, … 3) over the food's natural
///   unit (bowl, piece, slice). Default. Always available.
/// • **Container** — for packaged foods. Pick a fraction of the container
///   (1/4 … full). Only shown when the food declares
///   [FoodSearchResult.servingsPerContainer] (we approximate via the
///   `servingDescription` field today; the picker hides the tab otherwise).
/// • **Weight** — direct gram/oz entry for precision. Respects the user's
///   unit preference. Always available.
class ServingSizePicker extends ConsumerStatefulWidget {
  const ServingSizePicker({
    super.key,
    required this.food,
    required this.onChanged,
    this.initialMode = ServingMode.serving,
    this.initialGrams,
  });

  final FoodSearchResult food;
  final ValueChanged<ServingSelection> onChanged;
  final ServingMode initialMode;

  /// Optional starting weight — defaults to one serving's worth of grams.
  final double? initialGrams;

  @override
  ConsumerState<ServingSizePicker> createState() =>
      _ServingSizePickerState();
}

class _ServingSizePickerState extends ConsumerState<ServingSizePicker> {
  late ServingMode _mode;
  // Serving mode state
  double _servingQty = 1.0;
  late TextEditingController _servingManualController;
  // Container mode state
  double _containerFraction = 1.0;
  // Weight mode state
  late TextEditingController _weightController;
  bool _weightInOunces = false;
  // One-shot guard so the imperial auto-flip doesn't run on every rebuild
  // (the old code would fight the user if they manually picked grams while
  // on an imperial profile).
  bool _appliedImperialDefault = false;

  static const _quickQuantities = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 3.0];
  static const _containerFractions = [0.25, 1 / 3, 0.5, 2 / 3, 0.75, 1.0];

  /// Some foods report 0 grams per serving (e.g. drinks logged by volume) —
  /// fall back to 100 g so the picker doesn't divide by zero.
  double get _gramsPerServing {
    final reported = widget.food.defaultServingSize;
    return reported > 0 ? reported : 100.0;
  }

  /// The label to show in Serving mode. USDA + Spoonacular foods are usually
  /// normalised to grams, which makes the raw `servingUnit` field ('g') look
  /// identical to Weight mode — so we collapse 'g' / empty to "serving"
  /// and surface the gram weight separately as a subtitle. Restaurant-tagged
  /// foods (which set servingUnit explicitly) keep their natural unit
  /// ("bowl", "piece", "slice").
  String get _servingUnitLabel {
    final raw = widget.food.servingUnit.trim().toLowerCase();
    if (raw.isEmpty || raw == 'g' || raw == 'grams' || raw == 'gram') {
      return 'serving';
    }
    return widget.food.servingUnit;
  }

  /// Heuristic: if the serving description includes "container" or the
  /// description mentions a count × unit pattern (e.g. "5 × 30 g"), allow
  /// container mode. The Spoonacular parser uses that format for
  /// multi-serving products. Otherwise the tab is hidden.
  bool get _hasContainerData {
    final desc = widget.food.servingDescription?.toLowerCase() ?? '';
    return desc.contains('×') || desc.contains('x ') || desc.contains('container');
  }

  /// Approximate servings-per-container, parsed from the description if
  /// possible. Defaults to 1 (the food itself = the container).
  double get _servingsPerContainer {
    final desc = widget.food.servingDescription ?? '';
    final match = RegExp(r'(\d+(?:\.\d+)?)\s*[×x]').firstMatch(desc);
    if (match != null) {
      final n = double.tryParse(match.group(1) ?? '');
      if (n != null && n > 0) return n;
    }
    return 1.0;
  }

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    if (!_hasContainerData && _mode == ServingMode.container) {
      _mode = ServingMode.serving;
    }
    final initialG = widget.initialGrams ?? _gramsPerServing;
    _weightController =
        TextEditingController(text: initialG.toStringAsFixed(0));
    _servingManualController =
        TextEditingController(text: _formatQty(_servingQty));
    // Defer the first emit so listeners can use the picker's initial values
    // synchronously on the same frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => _emit());
  }

  @override
  void dispose() {
    _weightController.dispose();
    _servingManualController.dispose();
    super.dispose();
  }

  void _emit() {
    final selection = _currentSelection();
    widget.onChanged(selection);
  }

  ServingSelection _currentSelection() {
    final unit = _servingUnitLabel;
    switch (_mode) {
      case ServingMode.serving:
        final grams = _servingQty * _gramsPerServing;
        final qtyLabel = _formatQty(_servingQty);
        final plural = _servingQty == 1 ? unit : '${unit}s';
        return ServingSelection(
          totalGrams: grams,
          label: '$qtyLabel $plural',
          mode: _mode,
        );
      case ServingMode.container:
        final servings = _containerFraction * _servingsPerContainer;
        final grams = servings * _gramsPerServing;
        final label = _containerFraction >= 1
            ? 'Full container'
            : '${_formatFraction(_containerFraction)} container';
        return ServingSelection(
          totalGrams: grams,
          label: label,
          mode: _mode,
        );
      case ServingMode.weight:
        final raw =
            double.tryParse(_weightController.text.replaceAll(',', '.')) ?? 0;
        final grams = _weightInOunces ? raw * 28.3495 : raw;
        final label = _weightInOunces
            ? '${raw.toStringAsFixed(1)} oz'
            : '${raw.toStringAsFixed(0)} g';
        return ServingSelection(
          totalGrams: grams,
          label: label,
          mode: _mode,
        );
    }
  }

  String _formatQty(double q) {
    if (q == q.roundToDouble()) return q.toInt().toString();
    return q.toString();
  }

  String _formatFraction(double f) {
    // Match the picker's preset values back to nice strings.
    if ((f - 0.25).abs() < 0.01) return '1/4';
    if ((f - 1 / 3).abs() < 0.01) return '1/3';
    if ((f - 0.5).abs() < 0.01) return '1/2';
    if ((f - 2 / 3).abs() < 0.01) return '2/3';
    if ((f - 0.75).abs() < 0.01) return '3/4';
    return f.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final unitSystem = ref.watch(unitSystemProvider);
    // One-shot: on first build for imperial users, flip the Weight-mode
    // unit to oz so the displayed number is a sensible portion. Guarded by
    // _appliedImperialDefault so the user can manually switch back to grams
    // without us flipping them back to oz on every rebuild.
    if (unitSystem == UnitSystem.imperial &&
        !_weightInOunces &&
        !_appliedImperialDefault) {
      _appliedImperialDefault = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _weightInOunces = true;
          final raw =
              double.tryParse(_weightController.text.replaceAll(',', '.')) ?? 0;
          if (raw > 0) {
            _weightController.text = (raw / 28.3495).toStringAsFixed(1);
          }
        });
        _emit();
      });
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Mode segmented control
        _ModeSegmented(
          mode: _mode,
          showContainer: _hasContainerData,
          onChanged: (m) {
            HapticFeedback.selectionClick();
            setState(() => _mode = m);
            _emit();
          },
          palette: palette,
        ),
        const SizedBox(height: 16),
        _buildBody(palette),
      ],
    );
  }

  Widget _buildBody(Palette palette) {
    switch (_mode) {
      case ServingMode.serving:
        final grams = _servingQty * _gramsPerServing;
        // Build a subtitle like "1 serving · 100 g" so the user can see the
        // gram weight even when working in abstract "serving" units.
        final subtitle = widget.food.servingDescription ??
            '${grams.toStringAsFixed(0)} g';
        return _ServingModeBody(
          quantity: _servingQty,
          unit: _servingUnitLabel,
          servingDescription: subtitle,
          quickValues: _quickQuantities,
          manualController: _servingManualController,
          onQuantityChanged: (q) {
            setState(() {
              _servingQty = q;
              _servingManualController.text = _formatQty(q);
            });
            _emit();
          },
          onManualTextChanged: (text) {
            final parsed =
                double.tryParse(text.replaceAll(',', '.')) ?? 0;
            if (parsed <= 0) return;
            setState(() => _servingQty = parsed);
            _emit();
          },
        );
      case ServingMode.container:
        return _ContainerModeBody(
          fraction: _containerFraction,
          servingsPerContainer: _servingsPerContainer,
          fractions: _containerFractions,
          onFractionChanged: (f) {
            setState(() => _containerFraction = f);
            _emit();
          },
        );
      case ServingMode.weight:
        return _WeightModeBody(
          controller: _weightController,
          inOunces: _weightInOunces,
          onToggleUnit: () {
            // Convert the currently-displayed number rather than emitting
            // a meaningless flip (e.g. 200g shouldn't become 200oz).
            final raw =
                double.tryParse(_weightController.text.replaceAll(',', '.')) ??
                    0;
            final converted = _weightInOunces ? raw * 28.3495 : raw / 28.3495;
            setState(() {
              _weightInOunces = !_weightInOunces;
              _weightController.text = _weightInOunces
                  ? converted.toStringAsFixed(1)
                  : converted.toStringAsFixed(0);
            });
            _emit();
          },
          onTextChanged: (_) => _emit(),
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────
// Subwidgets
// ─────────────────────────────────────────────────────────────────────

class _ModeSegmented extends StatelessWidget {
  const _ModeSegmented({
    required this.mode,
    required this.showContainer,
    required this.onChanged,
    required this.palette,
  });

  final ServingMode mode;
  final bool showContainer;
  final ValueChanged<ServingMode> onChanged;
  final Palette palette;

  @override
  Widget build(BuildContext context) {
    final tabs = <(ServingMode, String)>[
      (ServingMode.serving, 'SERVING'),
      if (showContainer) (ServingMode.container, 'CONTAINER'),
      (ServingMode.weight, 'WEIGHT'),
    ];
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 180);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: FieldManual.field,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: FieldManual.hairline),
      ),
      child: Row(
        children: tabs
            .map((t) => Expanded(
                  child: Semantics(
                    button: true,
                    selected: mode == t.$1,
                    child: GestureDetector(
                      onTap: () => onChanged(t.$1),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: duration,
                        constraints: const BoxConstraints(minHeight: 44),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: mode == t.$1 ? palette.accent : null,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          t.$2,
                          style: FieldManual.label(
                            fontSize: 10,
                            color: mode == t.$1
                                ? palette.onAccent
                                : FieldManual.mutedBone,
                          ),
                        ),
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _ServingModeBody extends StatelessWidget {
  const _ServingModeBody({
    required this.quantity,
    required this.unit,
    required this.servingDescription,
    required this.quickValues,
    required this.manualController,
    required this.onQuantityChanged,
    required this.onManualTextChanged,
  });

  final double quantity;
  final String unit;
  final String? servingDescription;
  final List<double> quickValues;
  final TextEditingController manualController;
  final ValueChanged<double> onQuantityChanged;
  final ValueChanged<String> onManualTextChanged;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StepperButton(
              icon: CupertinoIcons.minus,
              semanticLabel: 'Decrease quantity',
              onTap: () {
                final next = (quantity - 0.25).clamp(0.25, 99.0);
                onQuantityChanged(next);
              },
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 110,
              child: Column(
                children: [
                  Text(
                    quantity == quantity.roundToDouble()
                        ? quantity.toInt().toString()
                        : quantity.toStringAsFixed(2)
                            .replaceAll(RegExp(r'0+$'), '')
                            .replaceAll(RegExp(r'\.$'), ''),
                    style: FieldManual.readout(fontSize: 36),
                  ),
                  Text(
                    quantity == 1 ? unit : '${unit}s',
                    style: FieldManual.body(
                      fontSize: 13,
                      color: FieldManual.mutedBone,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            _StepperButton(
              icon: CupertinoIcons.plus,
              semanticLabel: 'Increase quantity',
              onTap: () {
                final next = (quantity + 0.25).clamp(0.25, 99.0);
                onQuantityChanged(next);
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Manual numeric input — falls back to the steppers if the user
        // doesn't want to type.
        _FmFocusRing(
          builder: (context, focused) => CupertinoTextField(
            controller: manualController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            decoration: BoxDecoration(
              color: FieldManual.fieldRaised,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: focused ? palette.accent : FieldManual.hairline,
              ),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            style: FieldManual.readout(fontSize: 16),
            onChanged: onManualTextChanged,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: quickValues
              .map((q) => _QuickChip(
                    label: q == q.roundToDouble()
                        ? q.toInt().toString()
                        : q.toString(),
                    isActive: (quantity - q).abs() < 0.001,
                    onTap: () => onQuantityChanged(q),
                  ))
              .toList(),
        ),
        if (servingDescription != null) ...[
          const SizedBox(height: 12),
          Text(
            servingDescription!,
            textAlign: TextAlign.center,
            style: FieldManual.body(
              fontSize: 12,
              color: FieldManual.mutedBone,
            ),
          ),
        ],
      ],
    );
  }
}

class _ContainerModeBody extends StatelessWidget {
  const _ContainerModeBody({
    required this.fraction,
    required this.servingsPerContainer,
    required this.fractions,
    required this.onFractionChanged,
  });

  final double fraction;
  final double servingsPerContainer;
  final List<double> fractions;
  final ValueChanged<double> onFractionChanged;

  String _label(double f) {
    if ((f - 0.25).abs() < 0.01) return '1/4';
    if ((f - 1 / 3).abs() < 0.01) return '1/3';
    if ((f - 0.5).abs() < 0.01) return '1/2';
    if ((f - 2 / 3).abs() < 0.01) return '2/3';
    if ((f - 0.75).abs() < 0.01) return '3/4';
    return 'Full';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // The count is an instrument value — mono readout inside the sentence.
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Container has ',
                style: FieldManual.body(
                  fontSize: 13,
                  color: FieldManual.mutedBone,
                ),
              ),
              TextSpan(
                text: servingsPerContainer.toStringAsFixed(
                    servingsPerContainer ==
                            servingsPerContainer.roundToDouble()
                        ? 0
                        : 1),
                style: FieldManual.readout(
                  fontSize: 13,
                  color: FieldManual.mutedBone,
                ),
              ),
              TextSpan(
                text: ' servings',
                style: FieldManual.body(
                  fontSize: 13,
                  color: FieldManual.mutedBone,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: fractions
              .map((f) => _QuickChip(
                    label: _label(f),
                    isActive: (fraction - f).abs() < 0.01,
                    onTap: () => onFractionChanged(f),
                    minWidth: 64,
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _WeightModeBody extends StatelessWidget {
  const _WeightModeBody({
    required this.controller,
    required this.inOunces,
    required this.onToggleUnit,
    required this.onTextChanged,
  });

  final TextEditingController controller;
  final bool inOunces;
  final VoidCallback onToggleUnit;
  final ValueChanged<String> onTextChanged;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: _FmFocusRing(
            builder: (context, focused) => CupertinoTextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              placeholder: '0',
              decoration: BoxDecoration(
                color: FieldManual.fieldRaised,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: focused ? palette.accent : FieldManual.hairline,
                ),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              style: FieldManual.readout(fontSize: 22),
              onChanged: onTextChanged,
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onToggleUnit,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: palette.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: palette.accent.withValues(alpha: 0.4)),
            ),
            child: Text(
              inOunces ? 'OZ ⇄ G' : 'G ⇄ OZ',
              style: FieldManual.label(
                fontSize: 11,
                color: palette.accent,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: FieldManual.fieldRaised,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: FieldManual.hairline),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 20, color: FieldManual.bone),
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.minWidth = 44,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        constraints: BoxConstraints(minWidth: minWidth, minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? palette.accent : FieldManual.fieldRaised,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isActive ? palette.accent : FieldManual.hairline,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: FieldManual.readout(
            fontSize: 13,
            color: isActive ? palette.onAccent : FieldManual.bone,
          ),
        ),
      ),
    );
  }
}

/// Compact, read-only nutrition preview meant to live directly under the
/// picker. Updates with the picker's emitted [ServingSelection] — the
/// caller passes the calculated cal/protein/carbs/fat.
class LiveNutritionPreview extends StatelessWidget {
  const LiveNutritionPreview({
    super.key,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FieldManual.field,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: FieldManual.hairline),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                calories.toStringAsFixed(0),
                style: FieldManual.readout(fontSize: 32),
              ),
              const SizedBox(width: 4),
              Text('KCAL', style: FieldManual.label(fontSize: 10)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Small NutrientIcons dots stay — they aid scanning across the
              // row; the values themselves are bone mono readouts.
              _Macro(
                label: 'P',
                value: protein,
                color: NutrientIcons.proteinColor,
              ),
              _Macro(
                label: 'C',
                value: carbs,
                color: NutrientIcons.carbsColor,
              ),
              _Macro(
                label: 'F',
                value: fat,
                color: NutrientIcons.fatColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Macro extends StatelessWidget {
  const _Macro({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(label, style: FieldManual.label(fontSize: 10)),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '${value.toStringAsFixed(1)}G',
          style: FieldManual.readout(fontSize: 15),
        ),
      ],
    );
  }
}

/// Tracks whether a descendant text field holds focus so the builder can
/// paint the Field Manual accent focus border. Presentation only — the
/// wrapper node is unfocusable and skipped in traversal, so keyboard and
/// tap behavior are untouched.
class _FmFocusRing extends StatefulWidget {
  const _FmFocusRing({required this.builder});

  final Widget Function(BuildContext context, bool focused) builder;

  @override
  State<_FmFocusRing> createState() => _FmFocusRingState();
}

class _FmFocusRingState extends State<_FmFocusRing> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (focused) => setState(() => _focused = focused),
      child: widget.builder(context, _focused),
    );
  }
}
