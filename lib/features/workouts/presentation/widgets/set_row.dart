import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show IconButton, Icons, Theme, VisualDensity;
import 'package:flutter/services.dart';
import '../../../../core/utils/unit_converter.dart';
import '../../domain/active_workout_state.dart';

class SetRow extends StatefulWidget {
  const SetRow({
    super.key,
    required this.set,
    required this.setNumber,
    required this.onUpdate,
    required this.onComplete,
    required this.onRemove,
    required this.units,
    this.previousReps,
    this.previousWeight,
    this.onCopyFromPrevious,
  });

  final ActiveSet set;
  final int setNumber;

  /// `weight` passed up via [onUpdate] is ALWAYS in kg — SetRow handles the
  /// imperial display ↔ metric storage conversion internally so the rest of
  /// the app can treat weight values as canonical kilograms.
  final void Function({int? reps, double? weight}) onUpdate;
  final VoidCallback onComplete;
  final VoidCallback onRemove;

  /// User's preferred unit system. SetRow converts kg ↔ lbs based on this so
  /// the displayed number matches what the user typed.
  final UnitSystem units;

  final int? previousReps;

  /// Stored in kg. Converted for display + comparison locally.
  final double? previousWeight;

  /// If non-null, a copy icon is shown next to the weight field; tapping it
  /// copies the prior set's reps + weight into this row.
  final VoidCallback? onCopyFromPrevious;

  @override
  State<SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<SetRow> {
  static String _formatWeight(double w) {
    final s = w.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  /// Imperial users see and edit lbs; metric users see and edit kg. The
  /// canonical [ActiveSet.weight] is ALWAYS kg, so we convert here on
  /// display and convert back when emitting changes to onUpdate.
  double _displayWeight(double kg) =>
      UnitConverter.kgToDisplayWeight(kg, widget.units);

  /// Inverse of [_displayWeight] — what to store given a user-typed value.
  double _inputToKg(double displayValue) =>
      UnitConverter.displayWeightToKg(displayValue, widget.units);

  late final TextEditingController _repsController;
  late final TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    _repsController = TextEditingController(
      text: widget.set.reps > 0 ? widget.set.reps.toString() : '',
    );
    _weightController = TextEditingController(
      text: widget.set.weight > 0
          ? _formatWeight(_displayWeight(widget.set.weight))
          : '',
    );
  }

  @override
  void didUpdateWidget(SetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reps: only rewrite controller text if the parsed value changed.
    if (widget.set.reps != oldWidget.set.reps) {
      final currentParsed = int.tryParse(_repsController.text);
      if (currentParsed != widget.set.reps) {
        _repsController.text =
            widget.set.reps > 0 ? widget.set.reps.toString() : '';
      }
    }
    // Weight: only rewrite the controller when the parsed input (in kg)
    // genuinely differs from state. Compare in kg so a "205 lbs" in the
    // field that round-trips to itself doesn't get rewritten mid-typing.
    final unitsChanged = widget.units != oldWidget.units;
    if (widget.set.weight != oldWidget.set.weight || unitsChanged) {
      final currentTextDisplay =
          double.tryParse(_weightController.text);
      final currentAsKg = currentTextDisplay == null
          ? null
          : _inputToKg(currentTextDisplay);
      if (unitsChanged || currentAsKg != widget.set.weight) {
        _weightController.text = widget.set.weight > 0
            ? _formatWeight(_displayWeight(widget.set.weight))
            : '';
      }
    }
  }

  @override
  void dispose() {
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '${widget.setNumber}',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 40,
              child: CupertinoTextField(
                controller: _repsController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium,
                placeholder: widget.previousReps?.toString() ?? '0',
                placeholderStyle: textTheme.bodyMedium?.copyWith(
                  color: widget.previousReps != null
                      ? colorScheme.onSurfaceVariant.withValues(alpha: 0.6)
                      : CupertinoColors.placeholderText,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                onChanged: (value) {
                  final reps = int.tryParse(value);
                  if (reps != null) widget.onUpdate(reps: reps);
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 40,
              child: CupertinoTextField(
                controller: _weightController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium,
                // previousWeight is kg → convert to user's display unit.
                placeholder: widget.previousWeight != null
                    ? _formatWeight(_displayWeight(widget.previousWeight!))
                    : '0',
                placeholderStyle: textTheme.bodyMedium?.copyWith(
                  color: widget.previousWeight != null
                      ? colorScheme.onSurfaceVariant.withValues(alpha: 0.6)
                      : CupertinoColors.placeholderText,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                onChanged: (value) {
                  // User typed in their PREFERRED unit (lbs or kg). Always
                  // emit kg upward — the storage layer treats every weight
                  // as kilograms.
                  final typed = double.tryParse(value);
                  if (typed != null) {
                    widget.onUpdate(weight: _inputToKg(typed));
                  }
                },
              ),
            ),
          ),
          if (widget.onCopyFromPrevious != null)
            SizedBox(
              width: 32,
              child: IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  widget.onCopyFromPrevious!();
                },
                icon: Icon(
                  Icons.content_copy,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                visualDensity: VisualDensity.compact,
                tooltip: 'Copy from previous set',
              ),
            ),
          SizedBox(
            width: 48,
            child: widget.set.isCompleted
                ? IconButton(
                    onPressed: widget.onComplete,
                    icon: Icon(Icons.check_circle,
                        color: colorScheme.primary, size: 22),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Mark set incomplete',
                  )
                : IconButton(
                    onPressed: widget.onComplete,
                    icon: Icon(Icons.check_circle_outline,
                        color: colorScheme.onSurfaceVariant, size: 22),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Mark set complete',
                  ),
          ),
        ],
      ),
    );
  }
}
