import 'package:flutter/material.dart';
import '../../domain/active_workout_state.dart';

class SetRow extends StatefulWidget {
  const SetRow({
    super.key,
    required this.set,
    required this.setNumber,
    required this.onUpdate,
    required this.onComplete,
    required this.onRemove,
  });

  final ActiveSet set;
  final int setNumber;
  final void Function({int? reps, double? weight}) onUpdate;
  final VoidCallback onComplete;
  final VoidCallback onRemove;

  @override
  State<SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<SetRow> {
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
              child: TextField(
                controller: _repsController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: '0',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  isDense: true,
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
              child: TextField(
                controller: _weightController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: '0',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  isDense: true,
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
