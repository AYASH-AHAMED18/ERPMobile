import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart' as dates;
import '../../../../core/widgets/status_badge.dart';
import '../../../calendar/domain/calendar_event.dart';

enum EventTimeStatus {
  upcoming('Upcoming', AppColors.primary),
  ongoing('Ongoing', AppColors.success),
  completed('Completed', AppColors.backlog);

  const EventTimeStatus(this.label, this.color);
  final String label;
  final Color color;
}

class TodaysEventsCard extends StatefulWidget {
  const TodaysEventsCard({
    super.key,
    required this.events,
    this.onEventTap,
    this.onViewAll,
  });

  final List<CalendarEvent> events;
  final ValueChanged<CalendarEvent>? onEventTap;
  final VoidCallback? onViewAll;

  @override
  State<TodaysEventsCard> createState() => _TodaysEventsCardState();
}

class _TodaysEventsCardState extends State<TodaysEventsCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  List<CalendarEvent> get _todayEvents {
    final now = DateTime.now();
    final items = widget.events
        .where((event) => dates.AppDate.isSameDay(event.date, now))
        .toList();
    items.sort((a, b) {
      final aStart = _startOf(a, now);
      final bStart = _startOf(b, now);
      if (aStart == null && bStart == null) return 0;
      if (aStart == null) return -1;
      if (bStart == null) return 1;
      return aStart.compareTo(bStart);
    });
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final events = _todayEvents;
    final now = DateTime.now();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.isDark ? 0.18 : 0.025,
            ),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.event_note_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Events",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      dates.AppDate.day(now),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: '${events.length} event${events.length == 1 ? '' : 's'}',
                color: events.isEmpty ? AppColors.backlog : AppColors.primary,
                compact: true,
              ),
              if (widget.onViewAll != null)
                IconButton(
                  tooltip: 'Open calendar',
                  onPressed: widget.onViewAll,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 30,
                    minHeight: 30,
                  ),
                  icon: const Icon(Icons.chevron_right_rounded, size: 18),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.07),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.free_breakfast_outlined,
                      size: 17,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No events scheduled today',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimary,
                          ),
                        ),
                        Text(
                          'You have a clear calendar. Check back later for updates.',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            ...List.generate(events.length, (index) {
              final event = events[index];
              return _TimelineEvent(
                event: event,
                status: _statusOf(event, now),
                isLast: index == events.length - 1,
                onTap: widget.onEventTap == null
                    ? null
                    : () => widget.onEventTap!(event),
              );
            }),
        ],
      ),
    );
  }

  EventTimeStatus _statusOf(CalendarEvent event, DateTime now) {
    final start = _startOf(event, now);
    if (start == null) return EventTimeStatus.upcoming;
    final end = _endOf(event, now) ?? start.add(const Duration(hours: 1));
    if (now.isBefore(start)) return EventTimeStatus.upcoming;
    if (now.isAfter(end)) return EventTimeStatus.completed;
    return EventTimeStatus.ongoing;
  }

  DateTime? _startOf(CalendarEvent event, DateTime day) =>
      _parseTime(event.startTime, day);

  DateTime? _endOf(CalendarEvent event, DateTime day) =>
      _parseTime(event.endTime, day);

  DateTime? _parseTime(String? raw, DateTime day) {
    if (raw == null || raw.trim().isEmpty) return null;
    final direct = DateTime.tryParse(raw);
    if (direct != null && raw.contains('-')) return direct;
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})(?::\d{2})?\s*(AM|PM)?$',
      caseSensitive: false,
    ).firstMatch(raw.trim());
    if (match == null) return null;
    var hour = int.tryParse(match.group(1) ?? '') ?? 0;
    final minute = int.tryParse(match.group(2) ?? '') ?? 0;
    final meridiem = match.group(3)?.toUpperCase();
    if (meridiem == 'PM' && hour < 12) hour += 12;
    if (meridiem == 'AM' && hour == 12) hour = 0;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return DateTime(day.year, day.month, day.day, hour, minute);
  }
}

class _TimelineEvent extends StatelessWidget {
  const _TimelineEvent({
    required this.event,
    required this.status,
    required this.isLast,
    this.onTap,
  });

  final CalendarEvent event;
  final EventTimeStatus status;
  final bool isLast;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final highlight = status == EventTimeStatus.ongoing;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 50,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.startTime ?? 'All day',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: highlight
                          ? AppColors.success
                          : context.textPrimary,
                    ),
                  ),
                  if (event.endTime != null)
                    Text(
                      event.endTime!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 8.5,
                        color: context.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Column(
            children: [
              Container(
                width: 9,
                height: 9,
                margin: const EdgeInsets.only(top: 3),
                decoration: BoxDecoration(
                  color: highlight ? AppColors.success : event.type.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.surface, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: (highlight ? AppColors.success : event.type.color)
                          .withValues(alpha: 0.25),
                      blurRadius: 5,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: context.line,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: highlight
                          ? AppColors.success.withValues(
                              alpha: context.isDark ? 0.12 : 0.05,
                            )
                          : context.canvas,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: highlight
                            ? AppColors.success.withValues(alpha: 0.22)
                            : context.line,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                event.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: context.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            StatusBadge(
                              label: status.label,
                              color: status.color,
                              compact: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: event.type.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                [
                                  event.type.label,
                                  if (event.location != null &&
                                      event.location!.isNotEmpty)
                                    event.location!,
                                ].join(' • '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 8.5,
                                  color: context.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
