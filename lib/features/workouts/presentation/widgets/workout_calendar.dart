import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class WorkoutCalendar extends StatefulWidget {
  const WorkoutCalendar({
    super.key,
    required this.workoutDates,
    required this.selectedDate,
    required this.onDateSelected,
  });

  final Set<DateTime> workoutDates;
  final DateTime? selectedDate;
  final ValueChanged<DateTime?> onDateSelected;

  @override
  State<WorkoutCalendar> createState() => _WorkoutCalendarState();
}

class _WorkoutCalendarState extends State<WorkoutCalendar> {
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    _displayedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  void _previousMonth() {
    setState(() {
      _displayedMonth =
          DateTime(_displayedMonth.year, _displayedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth =
          DateTime(_displayedMonth.year, _displayedMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);

    // Build the grid of days
    final firstOfMonth =
        DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final daysInMonth =
        DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    // Monday = 1, shift so Monday is column 0
    final startWeekday = (firstOfMonth.weekday - 1) % 7;
    final totalCells = startWeekday + daysInMonth;
    // Calculate rows needed so we can give the grid a fixed height
    final rowCount = (totalCells / 7).ceil();

    final monthName = _monthName(_displayedMonth.month);
    final year = _displayedMonth.year;

    // Each cell: 36dp height + 2dp spacing
    const cellHeight = 36.0;
    const cellSpacing = 2.0;
    final gridHeight = rowCount * cellHeight + (rowCount - 1) * cellSpacing;

    final palette = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Month header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _previousMonth,
                icon: Icon(Icons.chevron_left, color: palette.accent),
                visualDensity: VisualDensity.compact,
              ),
              Text(
                '$monthName $year',
                style: textTheme.titleSmall?.copyWith(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: palette.text,
                ),
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: Icon(Icons.chevron_right, color: palette.accent),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Day-of-week headers
          Row(
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: textTheme.bodySmall?.copyWith(
                            color: palette.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 6),
          // Day cells — fixed height to prevent overflow
          SizedBox(
            height: gridHeight,
            child: GridView.builder(
              shrinkWrap: false,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisExtent: cellHeight,
                mainAxisSpacing: cellSpacing,
                crossAxisSpacing: cellSpacing,
              ),
              itemCount: totalCells,
              itemBuilder: (context, index) {
                if (index < startWeekday) return const SizedBox.shrink();

                final day = index - startWeekday + 1;
                final date = DateTime(
                    _displayedMonth.year, _displayedMonth.month, day);
                final isToday = date == todayNorm;
                final isSelected = widget.selectedDate != null &&
                    date == widget.selectedDate;
                final hasWorkout = widget.workoutDates.contains(date);

                Color? bgColor;
                if (isSelected) {
                  bgColor = palette.accent;
                } else if (isToday) {
                  bgColor = palette.accent;
                }

                Color textColor;
                if (isSelected || isToday) {
                  textColor = palette.text;
                } else {
                  textColor = palette.text;
                }

                return GestureDetector(
                  onTap: () {
                    widget.onDateSelected(isSelected ? null : date);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$day',
                          style: textTheme.bodySmall?.copyWith(
                            fontWeight:
                                (isToday || isSelected) ? FontWeight.bold : FontWeight.normal,
                            color: textColor,
                            fontSize: 11,
                          ),
                        ),
                        if (hasWorkout && !isSelected && !isToday)
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: palette.accent,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return names[month - 1];
  }
}
