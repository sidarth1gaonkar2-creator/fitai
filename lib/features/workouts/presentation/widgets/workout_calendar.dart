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

    // Each cell: 48dp height + 2dp spacing (meets 48dp tap target minimum)
    const cellHeight = 48.0;
    const cellSpacing = 2.0;
    final gridHeight = rowCount * cellHeight + (rowCount - 1) * cellSpacing;

    final palette = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.border),
      ),
      // 10pt side padding keeps each of the 7 day cells ≥44pt wide on
      // 375pt-class devices.
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Month header — a mono designation, like a log book page.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _previousMonth,
                icon: Icon(Icons.chevron_left, color: palette.text),
                tooltip: 'Previous month',
              ),
              Text(
                '${monthName.toUpperCase()} $year',
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontVariations: const [FontVariation('wght', 700)],
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 1,
                  color: palette.text,
                ),
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: Icon(Icons.chevron_right, color: palette.text),
                tooltip: 'Next month',
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Day-of-week rails — tertiary structure, not accent.
          Row(
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontVariations: const [
                              FontVariation('wght', 700)
                            ],
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: palette.textTertiary,
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

                // Selected day: accent fill with ink numerals (readable on
                // brass and every pack accent). Today, unselected: hairline
                // ring, no fill — marked but quiet.
                Color? bgColor;
                Border? ring;
                if (isSelected) {
                  bgColor = palette.accent;
                } else if (isToday) {
                  ring = Border.all(color: palette.accent, width: 1.5);
                }

                final textColor = isSelected
                    ? const Color(0xFF1A1C1A)
                    : palette.text;

                final dateLabel = '${_monthName(date.month)} $day, '
                    '${date.year}'
                    '${hasWorkout ? ", workout logged" : ""}'
                    '${isSelected ? ", selected" : ""}'
                    '${isToday ? ", today" : ""}';
                return Semantics(
                  label: dateLabel,
                  button: true,
                  selected: isSelected,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      widget.onDateSelected(isSelected ? null : date);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: bgColor,
                        border: ring,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$day',
                            // Calendar numerals are readouts — mono, tabular.
                            style: TextStyle(
                              fontFamily: 'JetBrainsMono',
                              fontVariations: [
                                FontVariation(
                                    'wght',
                                    (isToday || isSelected) ? 700 : 500),
                              ],
                              fontWeight: (isToday || isSelected)
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: textColor,
                              fontSize: 13,
                            ),
                          ),
                          if (hasWorkout && !isSelected) ...[
                            const SizedBox(height: 2),
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: palette.accent,
                              ),
                            ),
                          ],
                        ],
                      ),
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
