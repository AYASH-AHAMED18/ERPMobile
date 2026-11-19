import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart' as dates;
import '../../../attendance/domain/attendance.dart';
import '../../../calendar/domain/calendar_event.dart';

class DashboardCalendarCard extends StatefulWidget {
  const DashboardCalendarCard({
    super.key,
    required this.events,
    required this.onViewFull,
    this.onEventTap,
    this.todayAttendance,
  });

  final List<CalendarEvent> events;
  final VoidCallback onViewFull;
  final ValueChanged<CalendarEvent>? onEventTap;
  final AttendanceRecord? todayAttendance;

  @override
  State<DashboardCalendarCard> createState() => _DashboardCalendarCardState();
}

class _DashboardCalendarCardState extends State<DashboardCalendarCard> {
  late DateTime _focusedMonth;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    _selectedDay = dates.AppDate.dateOnly(now);
  }

  List<CalendarEvent> _eventsFor(DateTime day) {
    final events = widget.events
        .where((event) => dates.AppDate.isSameDay(event.date, day))
        .toList();
    events.sort((a, b) {
      final aTime = a.startTime ?? '';
      final bTime = b.startTime ?? '';
      return aTime.compareTo(bTime);
    });
    return events;
  }

  void _moveMonth(int delta) {
    final target = DateTime(_focusedMonth.year, _focusedMonth.month + delta);
    final now = DateTime.now();
    setState(() {
      _focusedMonth = target;
      _selectedDay = target.year == now.year && target.month == now.month
          ? dates.AppDate.dateOnly(now)
          : DateTime(target.year, target.month, 1);
    });
  }

  void _goToday() {
    final now = dates.AppDate.dateOnly(DateTime.now());
    setState(() {
      _focusedMonth = DateTime(now.year, now.month);
      _selectedDay = now;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dayEvents = _eventsFor(_selectedDay);
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final leading = firstDay.weekday - DateTime.monday;
    final gridStart = firstDay.subtract(Duration(days: leading));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Calendar',
          style: TextStyle(
            fontSize: 20,
            height: 1.2,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            _MonthButton(label: 'Prev', onTap: () => _moveMonth(-1)),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                DateFormat('MMMM yyyy').format(_focusedMonth),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            _MonthButton(label: 'Next', onTap: () => _moveMonth(1)),
            const SizedBox(width: AppSpacing.xs),
            _MonthButton(label: 'Today', onTap: _goToday),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(AppRadii.xl),
            border: Border.all(color: context.line),
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.sm,
                  horizontal: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: context.canvas,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Row(
                  children: const [
                    _WeekdayLabel('M'),
                    _WeekdayLabel('T'),
                    _WeekdayLabel('W'),
                    _WeekdayLabel('T'),
                    _WeekdayLabel('F'),
                    _WeekdayLabel('S'),
                    _WeekdayLabel('S'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 42,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 0.78,
                ),
                itemBuilder: (context, index) {
                  final day = gridStart.add(Duration(days: index));
                  final outside = day.month != _focusedMonth.month;
                  return _CalendarDayCell(
                    day: day,
                    outside: outside,
                    selected: dates.AppDate.isSameDay(day, _selectedDay),
                    today: dates.AppDate.isSameDay(day, DateTime.now()),
                    events: _eventsFor(day),
                    onTap: () => setState(
                      () => _selectedDay = dates.AppDate.dateOnly(day),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          DateFormat('EEE, MMM d').format(_selectedDay),
          style: TextStyle(
            fontSize: 20,
            height: 1.2,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${dayEvents.length} event${dayEvents.length == 1 ? '' : 's'}',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: context.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (dayEvents.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xl,
            ),
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: context.line),
            ),
            child: Text(
              'No events scheduled for this day.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: context.textSecondary,
              ),
            ),
          )
        else
          ...dayEvents.map(
            (event) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _CalendarEventTile(
                event: event,
                onTap: widget.onEventTap == null
                    ? null
                    : () => widget.onEventTap!(event),
              ),
            ),
          ),
      ],
    );
  }
}

class _MonthButton extends StatelessWidget {
  const _MonthButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: context.textSecondary,
        side: BorderSide(color: context.line),
        minimumSize: const Size(0, 38),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: context.textSecondary,
        ),
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.day,
    required this.outside,
    required this.selected,
    required this.today,
    required this.events,
    required this.onTap,
  });

  final DateTime day;
  final bool outside;
  final bool selected;
  final bool today;
  final List<CalendarEvent> events;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final circleSize = math.min(40.0, constraints.maxWidth - 4);
        final dotColors = <Color>{};
        for (final event in events) {
          dotColors.add(_dotColor(event.type));
          if (dotColors.length == 3) break;
        }

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          child: Container(
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: outside
                  ? context.canvas.withValues(alpha: context.isDark ? 0.4 : 0.8)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: circleSize,
                  height: circleSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: today
                        ? AppColors.primary
                        : selected
                        ? AppColors.primaryLight
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: today || selected
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: today
                          ? AppColors.white
                          : outside
                          ? context.textSecondary.withValues(alpha: 0.45)
                          : selected
                          ? AppColors.primary
                          : context.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                SizedBox(
                  height: 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final color in dotColors.take(3))
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: outside
                                ? color.withValues(alpha: 0.35)
                                : color,
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _dotColor(CalendarEventType type) {
    switch (type) {
      case CalendarEventType.workingDay:
        return AppColors.calendarWorking;
      case CalendarEventType.holiday:
        return AppColors.calendarBrand;
      case CalendarEventType.leave:
        return AppColors.calendarLeave;
      case CalendarEventType.projectDeadline:
        return AppColors.calendarProject;
      case CalendarEventType.company:
        return AppColors.calendarCompany;
      case CalendarEventType.personal:
      case CalendarEventType.meeting:
        return AppColors.calendarMeeting;
    }
  }
}

class _CalendarEventTile extends StatelessWidget {
  const _CalendarEventTile({required this.event, this.onTap});

  final CalendarEvent event;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = _dotColor(event.type);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: context.line),
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppRadii.xs),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                event.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 20,
                  height: 1.25,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                _subtitle(event),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: context.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle(CalendarEvent event) {
    final time = event.startTime == null
        ? event.type.label
        : '${event.type.label} · ${event.startTime}'
              '${event.endTime == null ? '' : ' – ${event.endTime}'}';
    return time;
  }

  Color _dotColor(CalendarEventType type) {
    switch (type) {
      case CalendarEventType.workingDay:
        return AppColors.calendarWorking;
      case CalendarEventType.holiday:
        return AppColors.calendarBrand;
      case CalendarEventType.leave:
        return AppColors.calendarLeave;
      case CalendarEventType.projectDeadline:
        return AppColors.calendarProject;
      case CalendarEventType.company:
        return AppColors.calendarCompany;
      case CalendarEventType.personal:
      case CalendarEventType.meeting:
        return AppColors.calendarMeeting;
    }
  }
}
