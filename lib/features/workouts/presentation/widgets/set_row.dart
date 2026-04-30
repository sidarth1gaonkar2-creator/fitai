import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show IconButton, Icons, Theme, VisualDensity;
import 'package:flutter/services.dart';
import '../../domain/active_workout_state.dart';

class SetRow extends StatefulWidget {
  const SetRow({
    super.key,
    required this.set,
    required this.setNumber,
    required this.onUpdate,
    required this.onComplete,
    required this.onRemove,
    this.previousReps,
    this.previousWeight,
    this.onCopyFromPrevious,
  });

  final ActiveSet set;
  final int setNumber;
  final void Function({int? reps, double? weight}) onUpdate;
  final VoidCallback onComplete;
  final VoidCallback onRemove;
  final int? previousReps;
  final double? previousWeight;

  /// If non-null, a copy icon is shown next to the weight field; tapping it
  /// copies the prior set's reps + weight into this row.
  final VoidCallback? onCopyFromPrevious;

  @override
  State<SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<SetRow> {
  static String _formatWeight(double w) =>
      w == w.roundToDouble() ? w.toInt().toString() : w.toString();
  late final TextEditingController _repsController;
  late final TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    _repsController = TextEditingController(
      text: widget.set.reps > 0 ? widget.set.reps.toString() : '',
    );
    _weightController = TextEditingController(
      text: widget.set.weight > 0 ? _formatWeight(widget.set.weight) : '',
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
    // Weight: only rewrite controller text if parsing the current text
    // would give a *different* value than the state. This preserves in-progress
    // typing like "1" or "1." that parses to 1.0 but would otherwise be
    // rewritten to "1.0" mid-keystroke and inject a stray decimal point.
    if (widget.set.weight != oldWidget.set.weight) {
      final currentParsed = double.tryParse(_weightController.text);
      if (currentParsed != widget.set.weight) {
        _weightController.text = widget.set.weight > 0
            ? _formatWeight(widget.set.weight)
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
                placeholder: widget.previousWeight != null
                    ? _formatWeight(widget.previousWeight!)
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
                  final weight = double.tryParse(value);
                  if (weight != null) widget.onUpdate(weight: weight);
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
                  )
                : IconButton(
                    onPressed: widget.onComplete,
                    icon: Icon(Icons.check_circle_outline,
                        color: colorScheme.onSurfaceVariant, size: 22),
                    visualDensity: VisualDensity.compact,
                  ),
          ),
        ],
      ),
    );
  }
}
