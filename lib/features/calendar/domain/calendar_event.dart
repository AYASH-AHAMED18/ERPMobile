import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

enum CalendarEventType {
  workingDay('Working day', AppColors.success, Icons.work_outline_rounded),
  holiday('Holiday', AppColors.error, Icons.celebration_outlined),
  leave('Leave', AppColors.warning, Icons.beach_access_outlined),
  projectDeadline('Project deadline', AppColors.primary, Icons.flag_outlined),
  company('Company event', AppColors.info, Icons.apartment_rounded),
  personal('Personal event', AppColors.review, Icons.person_outline_rounded),
  meeting('Meeting', AppColors.review, Icons.groups_outlined);

  const CalendarEventType(this.label, this.color, this.icon);
  final String label;
  final Color color;
  final IconData icon;
}

class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.type,
    this.description = '',
    this.startTime,
    this.endTime,
    this.location,
    this.createdByMe = false,
  });

  final String id;
  final String title;
  final DateTime date;
  final CalendarEventType type;
  final String description;
  final String? startTime;
  final String? endTime;
  final String? location;
  final bool createdByMe;

  factory CalendarEvent.fromJson(Map<String, dynamic> json) => CalendarEvent(
    id: (json['id'] ?? '').toString(),
    title: (json['title'] ?? '').toString(),
    date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
    type: CalendarEventType.values.firstWhere(
      (type) => type.name == json['type'],
      orElse: () => CalendarEventType.company,
    ),
    description: (json['description'] ?? '').toString(),
    startTime: json['start_time']?.toString(),
    endTime: json['end_time']?.toString(),
    location: json['location']?.toString(),
    createdByMe: json['created_by_me'] == true,
  );
}
