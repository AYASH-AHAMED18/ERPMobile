import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

enum MeetingStatus {
  live('Live now', AppColors.error),
  upcoming('Upcoming', AppColors.info),
  completed('Completed', AppColors.backlog),
  cancelled('Cancelled', AppColors.error);

  const MeetingStatus(this.label, this.color);
  final String label;
  final Color color;
}

class Meeting {
  const Meeting({
    required this.id,
    required this.title,
    required this.host,
    required this.startsAt,
    required this.endsAt,
    required this.description,
    required this.status,
    this.meetingUrl,
    this.attendees = 0,
    this.isExternal = false,
  });

  final String id;
  final String title;
  final String host;
  final DateTime startsAt;
  final DateTime endsAt;
  final String description;
  final MeetingStatus status;
  final String? meetingUrl;
  final int attendees;
  final bool isExternal;

  factory Meeting.fromJson(Map<String, dynamic> json) => Meeting(
    id: (json['id'] ?? '').toString(),
    title: (json['title'] ?? '').toString(),
    host: (json['host'] ?? '').toString(),
    startsAt:
        DateTime.tryParse(json['starts_at']?.toString() ?? '') ??
        DateTime.now(),
    endsAt:
        DateTime.tryParse(json['ends_at']?.toString() ?? '') ??
        DateTime.now().add(const Duration(hours: 1)),
    description: (json['description'] ?? '').toString(),
    status: MeetingStatus.values.firstWhere(
      (status) => status.name == json['status'],
      orElse: () => MeetingStatus.upcoming,
    ),
    meetingUrl: json['meeting_url']?.toString(),
    attendees: (json['attendees'] as num?)?.toInt() ?? 0,
    isExternal: json['is_external'] == true,
  );
}
