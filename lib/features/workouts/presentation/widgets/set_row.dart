import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show IconButton, Icons, Theme, VisualDensity;
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
  });

  final ActiveSet set;
  final int setNumber;
  final void Function({int? reps, double? weight}) onUpdate;
  final VoidCallback onComplete;
  final VoidCallback onRemove;
  final int? previousReps;
  final double? previousWeight;

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
      text: widget.set.weight > 0 ? widget.set.weight.toString() : '',
    );
  }

  @override
  void didUpdateWidget(SetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update controllers if the underlying data changed externally
    if (widget.set.reps != oldWidget.set.reps) {
      final newText = widget.set.reps > 0 ? widget.set.reps.toString() : '';
      if (_repsController.text != newText) _repsController.text = newText;
    }
    if (widget.set.weight != oldWidget.set.weight) {
      final newText =
          widget.set.weight > 0 ? widget.set.weight.toString() : '';
      if (_weightController.text != newText) _weightController.text = newText;
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
