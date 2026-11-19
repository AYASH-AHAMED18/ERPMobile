import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/models/employee.dart';
import '../../calendar/domain/calendar_event.dart';

enum EventCategory {
  workshop('Workshop', AppColors.review, Icons.lightbulb_outline_rounded),
  meeting('Meeting', AppColors.info, Icons.groups_outlined),
  celebration('Celebration', AppColors.warning, Icons.celebration_outlined),
  townHall('Town hall', AppColors.primary, Icons.campaign_outlined),
  training('Training', AppColors.success, Icons.school_outlined),
  sports('Sports', AppColors.warning, Icons.sports_cricket_outlined),
  other('Other', AppColors.secondaryText, Icons.event_outlined);

  const EventCategory(this.label, this.color, this.icon);
  final String label;
  final Color color;
  final IconData icon;

  static EventCategory fromValue(dynamic value) {
    final normalized = value?.toString().toLowerCase().replaceAll('_', ' ');
    for (final category in EventCategory.values) {
      if (category.name.toLowerCase() == normalized ||
          category.label.toLowerCase() == normalized) {
        return category;
      }
    }
    if (normalized == 'company') return EventCategory.townHall;
    if (normalized == 'personal') return EventCategory.other;
    return EventCategory.other;
  }
}

enum EventStatus {
  upcoming('Upcoming', AppColors.primary, Icons.schedule_rounded),
  ongoing('Happening now', AppColors.success, Icons.play_circle_outline),
  completed('Completed', AppColors.backlog, Icons.check_circle_outline),
  cancelled('Cancelled', AppColors.error, Icons.cancel_outlined);

  const EventStatus(this.label, this.color, this.icon);
  final String label;
  final Color color;
  final IconData icon;

  static EventStatus fromValue(dynamic value) {
    final normalized = value?.toString().toLowerCase().replaceAll('_', ' ');
    return EventStatus.values.firstWhere(
      (status) =>
          status.name == normalized || status.label.toLowerCase() == normalized,
      orElse: () => EventStatus.upcoming,
    );
  }
}

class CompanyEvent {
  const CompanyEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.category,
    this.description = '',
    this.startTime,
    this.endTime,
    this.location,
    this.organizer,
    this.organizerDepartment,
    this.bannerUrl,
    this.status = EventStatus.upcoming,
    this.registrationEnabled = false,
    this.registered = false,
    this.participantCount = 0,
    this.participants = const [],
    this.instructions,
  });

  final String id;
  final String title;
  final DateTime date;
  final EventCategory category;
  final String description;
  final String? startTime;
  final String? endTime;
  final String? location;
  final String? organizer;
  final String? organizerDepartment;
  final String? bannerUrl;
  final EventStatus status;
  final bool registrationEnabled;
  final bool registered;
  final int participantCount;
  final List<Employee> participants;
  final String? instructions;

  bool get isPast =>
      status == EventStatus.completed ||
      date.isBefore(DateTime.now().subtract(const Duration(days: 1)));

  DateTime get startsAt {
    final time = _parseTime(startTime);
    return DateTime(date.year, date.month, date.day, time.$1, time.$2);
  }

  DateTime get endsAt {
    final time = _parseTime(endTime ?? startTime);
    return DateTime(date.year, date.month, date.day, time.$1, time.$2);
  }

  factory CompanyEvent.fromJson(Map<String, dynamic> json) {
    final date =
        DateTime.tryParse(
          (json['date'] ?? json['starts_at'] ?? json['start_date'] ?? '')
              .toString(),
        ) ??
        DateTime.now();
    return CompanyEvent(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? json['name'] ?? 'Company event').toString(),
      date: date,
      category: EventCategory.fromValue(json['category'] ?? json['type']),
      description: (json['description'] ?? '').toString(),
      startTime: (json['start_time'] ?? json['starts_at'])?.toString(),
      endTime: (json['end_time'] ?? json['ends_at'])?.toString(),
      location: (json['location'] ?? json['venue'])?.toString(),
      organizer: _nameOf(json['organizer'] ?? json['created_by']),
      organizerDepartment: (json['organizer_department'] ?? json['department'])
          ?.toString(),
      bannerUrl: (json['banner_url'] ?? json['banner'])?.toString(),
      status: EventStatus.fromValue(json['status']),
      registrationEnabled: json['registration_enabled'] == true,
      registered: json['registered'] == true,
      participantCount: (json['participant_count'] as num?)?.toInt() ?? 0,
      participants:
          (json['participants'] as List?)
              ?.map(
                (item) =>
                    Employee.fromJson((item as Map).cast<String, dynamic>()),
              )
              .toList() ??
          const [],
      instructions: json['instructions']?.toString(),
    );
  }

  factory CompanyEvent.fromCalendarEvent(CalendarEvent event) => CompanyEvent(
    id: event.id,
    title: event.title,
    date: event.date,
    category: switch (event.type) {
      CalendarEventType.company => EventCategory.townHall,
      CalendarEventType.meeting => EventCategory.meeting,
      CalendarEventType.holiday => EventCategory.celebration,
      CalendarEventType.personal => EventCategory.other,
      CalendarEventType.leave => EventCategory.other,
      CalendarEventType.workingDay => EventCategory.other,
      CalendarEventType.projectDeadline => EventCategory.other,
    },
    description: event.description,
    startTime: event.startTime,
    endTime: event.endTime,
    location: event.location,
    status:
        event.date.isBefore(DateTime.now()) &&
            !event.date.isAtSameMomentAs(DateTime.now())
        ? EventStatus.completed
        : EventStatus.upcoming,
  );

  static String? _nameOf(dynamic value) {
    if (value is Map) {
      return (value['name'] ?? value['full_name'])?.toString();
    }
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static (int, int) _parseTime(String? value) {
    if (value == null || value.isEmpty) return (9, 0);
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return (parsed.hour, parsed.minute);
    final parts = value.split(':');
    if (parts.length >= 2) {
      return (int.tryParse(parts[0]) ?? 9, int.tryParse(parts[1]) ?? 0);
    }
    return (9, 0);
  }
}
