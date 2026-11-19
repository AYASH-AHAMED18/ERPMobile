import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/models/employee.dart';
import '../../calendar/domain/calendar_event.dart';
import '../../tasks/domain/task.dart';

class Notice {
  const Notice({
    required this.id,
    required this.title,
    required this.description,
    required this.postedAt,
    required this.author,
    this.isRead = false,
    this.priority = NoticePriority.normal,
    this.authorDesignation = '',
    this.authorDepartment = '',
    this.authorAvatarUrl,
    this.hasAttachment = false,
    this.attachmentName,
  });

  final String id;
  final String title;
  final String description;
  final DateTime postedAt;
  final String author;
  final bool isRead;
  final NoticePriority priority;
  final String authorDesignation;
  final String authorDepartment;
  final String? authorAvatarUrl;
  final bool hasAttachment;
  final String? attachmentName;

  String get authorSubtitle {
    final parts = [
      if (authorDesignation.trim().isNotEmpty) authorDesignation.trim(),
      if (authorDepartment.trim().isNotEmpty) authorDepartment.trim(),
    ];
    return parts.join(' • ');
  }

  Notice copyWith({bool? isRead}) => Notice(
    id: id,
    title: title,
    description: description,
    postedAt: postedAt,
    author: author,
    isRead: isRead ?? this.isRead,
    priority: priority,
    authorDesignation: authorDesignation,
    authorDepartment: authorDepartment,
    authorAvatarUrl: authorAvatarUrl,
    hasAttachment: hasAttachment,
    attachmentName: attachmentName,
  );

  factory Notice.fromJson(Map<String, dynamic> json) {
    final authorValue = json['author'] ?? json['posted_by'] ?? json['creator'];
    final authorMap = authorValue is Map
        ? authorValue.cast<String, dynamic>()
        : const <String, dynamic>{};
    final authorName = authorValue is Map
        ? (authorMap['name'] ?? authorMap['full_name'] ?? 'Admin').toString()
        : (authorValue ?? 'Admin').toString();
    final attachment = json['attachment'];
    final attachmentMap = attachment is Map
        ? attachment.cast<String, dynamic>()
        : const <String, dynamic>{};
    return Notice(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? json['body'] ?? '').toString(),
      postedAt:
          DateTime.tryParse(
            (json['posted_at'] ?? json['created_at'] ?? '').toString(),
          ) ??
          DateTime.now(),
      author: authorName,
      isRead: json['is_read'] == true,
      priority: NoticePriority.fromValue(json['priority']),
      authorDesignation:
          (authorMap['designation'] ??
                  authorMap['position'] ??
                  json['author_designation'] ??
                  '')
              .toString(),
      authorDepartment:
          (authorMap['department'] ?? json['author_department'] ?? '')
              .toString(),
      authorAvatarUrl:
          (authorMap['avatar_url'] ??
                  authorMap['avatarUrl'] ??
                  json['author_avatar_url'])
              ?.toString(),
      hasAttachment:
          json['has_attachment'] == true ||
          attachment != null ||
          json['attachment_name'] != null,
      attachmentName:
          (attachmentMap['name'] ?? json['attachment_name'] ?? attachment)
              ?.toString(),
    );
  }

  Map<String, dynamic> toCreateJson() => {
    'title': title,
    'description': description,
    'priority': priority.name,
  };
}

enum NoticePriority {
  normal,
  important,
  urgent;

  static NoticePriority fromValue(dynamic value) {
    return NoticePriority.values.firstWhere(
      (priority) => priority.name == value?.toString().toLowerCase(),
      orElse: () => NoticePriority.normal,
    );
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.type = NotificationType.info,
  });

  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final NotificationType type;

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    title: title,
    message: message,
    createdAt: createdAt,
    isRead: isRead ?? this.isRead,
    type: type,
  );

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: (json['id'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        message: (json['message'] ?? '').toString(),
        createdAt:
            DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.now(),
        isRead: json['is_read'] == true,
        type: NotificationType.values.firstWhere(
          (type) => type.name == json['type'],
          orElse: () => NotificationType.info,
        ),
      );
}

enum NotificationType {
  info(AppColors.info),
  success(AppColors.success),
  warning(AppColors.warning),
  error(AppColors.error);

  const NotificationType(this.color);
  final Color color;
}

class EmployeeStatusSummary {
  const EmployeeStatusSummary({
    required this.atWork,
    required this.onLeave,
    required this.employees,
  });

  final int atWork;
  final int onLeave;
  final List<Employee> employees;

  int get total => employees.length;

  List<Employee> get workingEmployees => employees
      .where((employee) => employee.workStatus == EmployeeWorkStatus.atWork)
      .toList();
}

class DashboardSnapshot {
  const DashboardSnapshot({
    required this.notices,
    required this.notifications,
    required this.employeeStatus,
    required this.taskStats,
    required this.teamProgress,
    required this.events,
    this.unreadNoticeCount = 0,
  });

  final List<Notice> notices;
  final List<AppNotification> notifications;
  final EmployeeStatusSummary employeeStatus;
  final TaskStats taskStats;
  final List<TeamProgress> teamProgress;
  final List<CalendarEvent> events;
  final int unreadNoticeCount;

  int get unreadNotifications =>
      notifications.where((notification) => !notification.isRead).length;
}
