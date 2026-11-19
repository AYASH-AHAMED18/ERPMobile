import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart' as dates;
import '../../../core/widgets/app_module_scaffold.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/status_badge.dart';
import '../../leave/domain/leave.dart';
import '../../leave/presentation/leave_controller.dart';
import '../../projects/domain/project.dart';
import '../../projects/presentation/projects_controller.dart';
import '../domain/calendar_event.dart';
import 'calendar_controller.dart';

enum _CalendarView { month, week, agenda }

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  _CalendarView _view = _CalendarView.month;
  CalendarEventType? _typeFilter;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDay = now;
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  CalendarFormat get _format =>
      _view == _CalendarView.week ? CalendarFormat.week : CalendarFormat.month;

  List<CalendarEvent> _syntheticEvents(
    List<Project> projects,
    LeaveOverview? leave,
  ) {
    final items = <CalendarEvent>[];
    for (final project in projects) {
      if (project.status == ProjectStatus.completed ||
          project.status == ProjectStatus.cancelled) {
        continue;
      }
      items.add(
        CalendarEvent(
          id: 'project-${project.id}',
          title: project.name,
          date: project.deadline,
          type: CalendarEventType.projectDeadline,
          description:
              '${project.code} deadline • ${project.pendingTasks} pending task${project.pendingTasks == 1 ? '' : 's'}',
        ),
      );
    }
    if (leave != null) {
      for (final request in leave.requests) {
        if (request.status != LeaveStatus.approved) continue;
        var day = dates.AppDate.dateOnly(request.startDate);
        final end = dates.AppDate.dateOnly(request.endDate);
        while (!day.isAfter(end)) {
          items.add(
            CalendarEvent(
              id: 'leave-${request.id}-${day.toIso8601String()}',
              title: 'Your ${request.type.label.toLowerCase()}',
              date: day,
              type: CalendarEventType.leave,
              description: request.reason,
            ),
          );
          day = day.add(const Duration(days: 1));
        }
      }
    }
    return items;
  }

  List<CalendarEvent> _eventsFor(
    List<CalendarEvent> events,
    DateTime day, {
    bool applyFilter = true,
  }) {
    var items = events.where(
      (event) => dates.AppDate.isSameDay(event.date, day),
    );
    if (applyFilter && _typeFilter != null) {
      items = items.where((event) => event.type == _typeFilter);
    }
    return items.toList();
  }

  @override
  Widget build(BuildContext context) {
    final calendarAsync = ref.watch(calendarControllerProvider);
    final projects = ref.watch(projectsControllerProvider).value ?? const [];
    final leave = ref.watch(leaveControllerProvider).value;
    return ErpModuleScaffold(
      body: calendarAsync.when(
        loading: () =>
            const AppLoadingIndicator(message: 'Loading your calendar...'),
        error: (error, _) => AppErrorWidget(
          message: 'Your calendar could not be loaded.',
          onRetry: () =>
              ref.read(calendarControllerProvider.notifier).refresh(),
        ),
        data: (calendarEvents) {
          final allEvents = [
            ...calendarEvents,
            ..._syntheticEvents(projects, leave),
          ];
          return RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                ref.read(calendarControllerProvider.notifier).refresh(),
              ]);
              if (context.mounted) {
                ref.read(projectsControllerProvider.notifier).refresh();
                ref.read(leaveControllerProvider.notifier).refresh();
              }
            },
            color: AppColors.primary,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                AppPageTitle(
                  title: 'Calendar',
                  subtitle: 'Meetings, leave, holidays and project deadlines',
                  trailing: IconButton(
                    tooltip: 'Add calendar event',
                    onPressed: () => _openEventSheet(),
                    icon: const Icon(Icons.add_rounded, size: 23),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _CalendarPanel(
                    focusedDay: _focusedDay,
                    selectedDay: _selectedDay,
                    view: _view,
                    format: _format,
                    events: allEvents,
                    typeFilter: _typeFilter,
                    onViewChanged: (view) => setState(() => _view = view),
                    onDaySelected: (selectedDay, focusedDay) => setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    }),
                    onPageChanged: (day) => setState(() => _focusedDay = day),
                    onPrevious: () => _shiftFocus(-1),
                    onNext: () => _shiftFocus(1),
                    onToday: _goToToday,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: ModuleFilterRow(
                    children: [
                      AppFilterChip(
                        label: 'All events',
                        selected: _typeFilter == null,
                        onSelected: (_) => setState(() => _typeFilter = null),
                      ),
                      ...CalendarEventType.values.map(
                        (type) => AppFilterChip(
                          label: type.label,
                          color: type.color,
                          selected: _typeFilter == type,
                          onSelected: (_) => setState(
                            () =>
                                _typeFilter = _typeFilter == type ? null : type,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_view == _CalendarView.agenda) ...[
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ModuleSectionTitle(
                      title: 'Agenda',
                      subtitle: 'Next 60 days',
                    ),
                  ),
                  const SizedBox(height: 8),
                  _AgendaList(
                    events: allEvents,
                    filter: _typeFilter,
                    onTap: _showEventDetails,
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  _SelectedDaySection(
                    day: _selectedDay,
                    events: _eventsFor(allEvents, _selectedDay),
                    onTap: _showEventDetails,
                  ),
                ],
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ModuleSectionTitle(
                    title: 'Upcoming schedule',
                    subtitle: 'Your next confirmed activities',
                    trailing: TextButton(
                      onPressed: _goToToday,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 28),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                      ),
                      child: const Text(
                        'Today',
                        style: TextStyle(fontSize: 10.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _UpcomingList(
                  events: allEvents,
                  filter: _typeFilter,
                  onTap: _showEventDetails,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _shiftFocus(int direction) {
    setState(() {
      if (_view == _CalendarView.week) {
        _focusedDay = _focusedDay.add(Duration(days: 7 * direction));
      } else {
        final month = DateTime(
          _focusedDay.year,
          _focusedDay.month + direction,
          1,
        );
        _focusedDay = month;
      }
    });
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _focusedDay = now;
      _selectedDay = dates.AppDate.dateOnly(now);
    });
  }

  void _showEventDetails(CalendarEvent event) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 26),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatusBadge(label: event.type.label, color: event.type.color),
              const SizedBox(height: 12),
              Text(
                event.title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                dates.AppDate.full(event.date),
                style: TextStyle(fontSize: 11.5, color: context.textSecondary),
              ),
              if (event.startTime != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 15,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      '${event.startTime}${event.endTime == null ? '' : ' - ${event.endTime}'}',
                      style: const TextStyle(fontSize: 11.5),
                    ),
                  ],
                ),
              ],
              if (event.location != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 15,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        event.location!,
                        style: const TextStyle(fontSize: 11.5),
                      ),
                    ),
                  ],
                ),
              ],
              if (event.description.isNotEmpty) ...[
                const Divider(height: 24),
                Text(
                  event.description,
                  style: const TextStyle(fontSize: 12.5, height: 1.6),
                ),
              ],
              if (event.createdByMe) ...[
                const SizedBox(height: 12),
                const StatusBadge(
                  label: 'Created by me',
                  color: AppColors.review,
                  compact: true,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openEventSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, controller) => _CreateEventSheet(
          scrollController: controller,
          initialDate: _selectedDay,
        ),
      ),
    );
  }
}

class _CalendarPanel extends StatelessWidget {
  const _CalendarPanel({
    required this.focusedDay,
    required this.selectedDay,
    required this.view,
    required this.format,
    required this.events,
    required this.typeFilter,
    required this.onViewChanged,
    required this.onDaySelected,
    required this.onPageChanged,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  final DateTime focusedDay;
  final DateTime selectedDay;
  final _CalendarView view;
  final CalendarFormat format;
  final List<CalendarEvent> events;
  final CalendarEventType? typeFilter;
  final ValueChanged<_CalendarView> onViewChanged;
  final void Function(DateTime selectedDay, DateTime focusedDay) onDaySelected;
  final ValueChanged<DateTime> onPageChanged;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;

  List<CalendarEvent> _eventsFor(DateTime day) {
    return events
        .where(
          (event) =>
              dates.AppDate.isSameDay(event.date, day) &&
              (typeFilter == null || event.type == typeFilter),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                IconButton(
                  tooltip: view == _CalendarView.week
                      ? 'Previous week'
                      : 'Previous month',
                  onPressed: onPrevious,
                  icon: const Icon(Icons.chevron_left_rounded, size: 22),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(34, 34),
                    padding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        dates.AppDate.monthYear(focusedDay),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (view == _CalendarView.agenda)
                        Text(
                          'Agenda view',
                          style: TextStyle(
                            fontSize: 9,
                            color: context.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: view == _CalendarView.week
                      ? 'Next week'
                      : 'Next month',
                  onPressed: onNext,
                  icon: const Icon(Icons.chevron_right_rounded, size: 22),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(34, 34),
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(width: 2),
                TextButton(
                  onPressed: onToday,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 30),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Today', style: TextStyle(fontSize: 10.5)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: _CalendarViewToggle(view: view, onChanged: onViewChanged),
          ),
          if (view != _CalendarView.agenda) ...[
            const SizedBox(height: 4),
            TableCalendar<CalendarEvent>(
              firstDay: DateTime.utc(2023, 1, 1),
              lastDay: DateTime.utc(2028, 12, 31),
              focusedDay: focusedDay,
              selectedDayPredicate: (day) =>
                  dates.AppDate.isSameDay(day, selectedDay),
              calendarFormat: format,
              availableCalendarFormats: const {
                CalendarFormat.month: 'Month',
                CalendarFormat.week: 'Week',
              },
              startingDayOfWeek: StartingDayOfWeek.monday,
              rowHeight: view == _CalendarView.month ? 40 : 46,
              daysOfWeekHeight: 26,
              eventLoader: _eventsFor,
              onDaySelected: onDaySelected,
              onPageChanged: onPageChanged,
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                headerPadding: const EdgeInsets.symmetric(vertical: 0),
                titleTextStyle: const TextStyle(fontSize: 0),
                leftChevronVisible: false,
                rightChevronVisible: false,
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: context.textSecondary,
                ),
                weekendStyle: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: context.textSecondary,
                ),
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                cellMargin: const EdgeInsets.all(2),
                defaultTextStyle: TextStyle(
                  fontSize: 11.5,
                  color: context.textPrimary,
                ),
                weekendTextStyle: TextStyle(
                  fontSize: 11.5,
                  color: context.textPrimary,
                ),
                todayDecoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                todayTextStyle: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
                selectedDecoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              calendarBuilders: CalendarBuilders<CalendarEvent>(
                markerBuilder: (context, day, dayEvents) {
                  if (dayEvents.isEmpty) return null;
                  final colors = <Color>{};
                  for (final event in dayEvents) {
                    colors.add(event.type.color);
                    if (colors.length == 3) break;
                  }
                  return Positioned(
                    left: 0,
                    right: 0,
                    bottom: 3,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: colors
                          .map(
                            (color) => Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CalendarViewToggle extends StatelessWidget {
  const _CalendarViewToggle({required this.view, required this.onChanged});

  final _CalendarView view;
  final ValueChanged<_CalendarView> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = [
      (_CalendarView.month, 'Month'),
      (_CalendarView.week, 'Week'),
      (_CalendarView.agenda, 'Agenda'),
    ];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.canvas,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.line),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: InkWell(
                onTap: () => onChanged(option.$1),
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: view == option.$1
                        ? AppColors.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    option.$2,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: view == option.$1
                          ? Colors.white
                          : context.textSecondary,
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

class _SelectedDaySection extends StatelessWidget {
  const _SelectedDaySection({
    required this.day,
    required this.events,
    required this.onTap,
  });

  final DateTime day;
  final List<CalendarEvent> events;
  final ValueChanged<CalendarEvent> onTap;

  @override
  Widget build(BuildContext context) {
    final workingDay = day.weekday <= DateTime.friday;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                dates.AppDate.day(day),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(width: 7),
              StatusBadge(
                label: workingDay ? 'Working day' : 'Weekend',
                color: workingDay ? AppColors.success : AppColors.backlog,
                compact: true,
              ),
              const Spacer(),
              Text(
                '${events.length} event${events.length == 1 ? '' : 's'}',
                style: TextStyle(fontSize: 10.5, color: context.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (events.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.line),
              ),
              child: AppEmptyState(
                title: 'Nothing scheduled',
                message: workingDay
                    ? 'This is a working day with no events or leave.'
                    : 'Enjoy the weekend. No events on this day.',
                icon: Icons.event_note_outlined,
                compact: true,
              ),
            )
          else
            ...events.map(
              (event) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _CalendarEventCard(
                  event: event,
                  onTap: () => onTap(event),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AgendaList extends StatelessWidget {
  const _AgendaList({
    required this.events,
    required this.filter,
    required this.onTap,
  });

  final List<CalendarEvent> events;
  final CalendarEventType? filter;
  final ValueChanged<CalendarEvent> onTap;

  @override
  Widget build(BuildContext context) {
    final now = dates.AppDate.dateOnly(DateTime.now());
    final end = now.add(const Duration(days: 60));
    var items =
        events
            .where(
              (event) =>
                  !dates.AppDate.dateOnly(event.date).isBefore(now) &&
                  !dates.AppDate.dateOnly(event.date).isAfter(end) &&
                  (filter == null || event.type == filter),
            )
            .toList()
          ..sort((a, b) {
            final byDate = a.date.compareTo(b.date);
            if (byDate != 0) return byDate;
            return (a.startTime ?? '').compareTo(b.startTime ?? '');
          });
    if (items.isEmpty) {
      return const AppEmptyState(
        title: 'Your agenda is clear',
        message: 'No scheduled activities in the next 60 days.',
        icon: Icons.event_note_outlined,
        compact: true,
      );
    }
    final groups = <String, List<CalendarEvent>>{};
    for (final event in items) {
      final key = dates.AppDate.full(event.date);
      groups.putIfAbsent(key, () => []).add(event);
    }
    return Column(
      children: groups.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${entry.value.length}',
                    style: TextStyle(
                      fontSize: 9.5,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ...entry.value.map(
                (event) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _CalendarEventCard(
                    event: event,
                    onTap: () => onTap(event),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _UpcomingList extends StatelessWidget {
  const _UpcomingList({
    required this.events,
    required this.filter,
    required this.onTap,
  });

  final List<CalendarEvent> events;
  final CalendarEventType? filter;
  final ValueChanged<CalendarEvent> onTap;

  @override
  Widget build(BuildContext context) {
    final today = dates.AppDate.dateOnly(DateTime.now());
    final upcoming =
        events
            .where(
              (event) =>
                  !dates.AppDate.dateOnly(event.date).isBefore(today) &&
                  (filter == null || event.type == filter),
            )
            .toList()
          ..sort((a, b) {
            final byDate = a.date.compareTo(b.date);
            if (byDate != 0) return byDate;
            return (a.startTime ?? '').compareTo(b.startTime ?? '');
          });
    if (upcoming.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.line),
          ),
          child: const AppEmptyState(
            title: 'No upcoming activities',
            message: 'New events and deadlines will appear here.',
            icon: Icons.event_note_outlined,
            compact: true,
          ),
        ),
      );
    }
    return Column(
      children: upcoming
          .take(5)
          .map(
            (event) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: _CalendarEventCard(
                event: event,
                onTap: () => onTap(event),
                showDate: true,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _CalendarEventCard extends StatelessWidget {
  const _CalendarEventCard({
    required this.event,
    required this.onTap,
    this.showDate = false,
  });

  final CalendarEvent event;
  final VoidCallback onTap;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.line),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: event.type.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(event.type.icon, size: 18, color: event.type.color),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (showDate) dates.AppDate.shortDate(event.date),
                        event.type.label,
                        if (event.startTime != null) event.startTime!,
                        if (event.location != null) event.location!,
                      ].join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9.5,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (event.type == CalendarEventType.projectDeadline)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.flag_rounded,
                    size: 15,
                    color: AppColors.primary,
                  ),
                ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: context.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateEventSheet extends ConsumerStatefulWidget {
  const _CreateEventSheet({
    required this.scrollController,
    required this.initialDate,
  });

  final ScrollController scrollController;
  final DateTime initialDate;

  @override
  ConsumerState<_CreateEventSheet> createState() => _CreateEventSheetState();
}

class _CreateEventSheetState extends ConsumerState<_CreateEventSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  CalendarEventType _type = CalendarEventType.personal;
  late DateTime _date;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _submitting = false;

  static final _creatableTypes = CalendarEventType.values
      .where((type) => type != CalendarEventType.projectDeadline)
      .toList();

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime({required bool start}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start
          ? (_startTime ?? const TimeOfDay(hour: 9, minute: 0))
          : (_endTime ?? const TimeOfDay(hour: 10, minute: 0)),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final value = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    return dates.AppDate.time(value);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      final event = CalendarEvent(
        id: 'event-${DateTime.now().millisecondsSinceEpoch}',
        title: _titleController.text.trim(),
        date: _date,
        type: _type,
        description: _descriptionController.text.trim(),
        startTime: _startTime == null ? null : _formatTime(_startTime!),
        endTime: _endTime == null ? null : _formatTime(_endTime!),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        createdByMe: true,
      );
      await ref.read(calendarControllerProvider.notifier).create(event);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      showAppSnackBarWith(
        messenger,
        'Event added to calendar.',
        isSuccess: true,
      );
    } catch (_) {
      if (!mounted) return;
      showAppSnackBar(context, 'Event could not be created.', isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 26),
        children: [
          Row(
            children: [
              const Text(
                'New calendar event',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              StatusBadge(
                label: _type.label,
                color: _type.color,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                AppTextField(
                  controller: _titleController,
                  label: 'Event title',
                  hint: 'e.g. Sprint planning',
                  prefixIcon: Icons.title_rounded,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please enter an event title'
                      : null,
                ),
                const SizedBox(height: 14),
                AppDropdownField<CalendarEventType>(
                  label: 'Event type',
                  value: _type,
                  icon: Icons.category_outlined,
                  items: _creatableTypes
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _type = value);
                  },
                ),
                const SizedBox(height: 14),
                _FieldTile(
                  label: 'Date',
                  value: dates.AppDate.full(_date),
                  icon: Icons.calendar_today_outlined,
                  onTap: _pickDate,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _FieldTile(
                        label: 'Start time',
                        value: _startTime == null
                            ? 'Optional'
                            : _formatTime(_startTime!),
                        icon: Icons.schedule_rounded,
                        onTap: () => _pickTime(start: true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _FieldTile(
                        label: 'End time',
                        value: _endTime == null
                            ? 'Optional'
                            : _formatTime(_endTime!),
                        icon: Icons.schedule_outlined,
                        onTap: () => _pickTime(start: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _locationController,
                  label: 'Location (optional)',
                  hint: 'Meeting room, Google Meet, etc.',
                  prefixIcon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  hint: 'Add details about this event',
                  prefixIcon: Icons.notes_outlined,
                  maxLines: 4,
                  minLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 18),
                AppPrimaryButton(
                  label: 'Create event',
                  icon: Icons.event_available_rounded,
                  loading: _submitting,
                  onPressed: _submitting ? null : _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldTile extends StatelessWidget {
  const _FieldTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: 7),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.line),
              color: context.surface,
            ),
            child: Row(
              children: [
                Icon(icon, size: 15, color: AppColors.primary),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: context.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
