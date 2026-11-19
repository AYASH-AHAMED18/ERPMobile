import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/models/employee.dart';

enum TaskStatus {
  backlog('Backlog', AppColors.backlog),
  todo('To Do', AppColors.backlog),
  inProgress('In Progress', AppColors.primary),
  review('Under Review', AppColors.info),
  done('Completed', AppColors.success),
  blocked('Blocked', AppColors.error);

  const TaskStatus(this.label, this.color);
  final String label;
  final Color color;

  static TaskStatus fromValue(dynamic value) {
    final normalized = value?.toString().toLowerCase().replaceAll('_', ' ');
    switch (normalized) {
      case 'backlog':
        return TaskStatus.backlog;
      case 'todo':
      case 'to do':
        return TaskStatus.todo;
      case 'inprogress':
      case 'in progress':
        return TaskStatus.inProgress;
      case 'review':
      case 'under review':
        return TaskStatus.review;
      case 'done':
      case 'complete':
      case 'completed':
        return TaskStatus.done;
      case 'blocked':
        return TaskStatus.blocked;
    }
    return TaskStatus.values.firstWhere(
      (status) =>
          status.label.toLowerCase() == normalized || status.name == normalized,
      orElse: () => TaskStatus.todo,
    );
  }
}

enum TaskPriority {
  low('Low', AppColors.info),
  medium('Medium', AppColors.warning),
  high('High', AppColors.error),
  urgent('Urgent', AppColors.error);

  const TaskPriority(this.label, this.color);
  final String label;
  final Color color;

  static TaskPriority fromValue(dynamic value) {
    return TaskPriority.values.firstWhere(
      (priority) => priority.name == value?.toString().toLowerCase(),
      orElse: () => TaskPriority.medium,
    );
  }
}

class TaskAttachment {
  const TaskAttachment({
    required this.name,
    required this.url,
    this.size = 'Unknown',
  });

  final String name;
  final String url;
  final String size;

  factory TaskAttachment.fromJson(Map<String, dynamic> json) => TaskAttachment(
    name: (json['name'] ?? 'Attachment').toString(),
    url: (json['url'] ?? '').toString(),
    size: (json['size'] ?? 'Unknown').toString(),
  );
}

class TaskComment {
  const TaskComment({
    required this.id,
    required this.author,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final Employee author;
  final String message;
  final DateTime createdAt;

  factory TaskComment.fromJson(Map<String, dynamic> json) => TaskComment(
    id: (json['id'] ?? '').toString(),
    author: Employee.fromJson(
      (json['author'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
    message: (json['message'] ?? '').toString(),
    createdAt:
        DateTime.tryParse(json['created_at']?.toString() ?? '') ??
        DateTime.now(),
  );
}

class TaskActivity {
  const TaskActivity({
    required this.id,
    required this.message,
    required this.actor,
    required this.createdAt,
  });

  final String id;
  final String message;
  final String actor;
  final DateTime createdAt;
}

class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.projectName,
    required this.assignee,
    this.projectId,
    required this.dueDate,
    this.createdAt,
    this.comments = const [],
    this.attachments = const [],
    this.activity = const [],
    this.tags = const [],
    this.assignedToMe = false,
    this.assignedBy,
    this.progress,
  });

  final String id;
  final String title;
  final String description;
  final TaskStatus status;
  final TaskPriority priority;
  final String projectName;
  final String? projectId;
  final Employee assignee;
  final DateTime dueDate;
  final DateTime? createdAt;
  final List<TaskComment> comments;
  final List<TaskAttachment> attachments;
  final List<TaskActivity> activity;
  final List<String> tags;
  final bool assignedToMe;
  final String? assignedBy;
  final double? progress;

  bool get isOverdue =>
      dueDate.isBefore(DateTime.now()) && status != TaskStatus.done;

  TaskItem copyWith({
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    Employee? assignee,
    DateTime? dueDate,
    List<TaskComment>? comments,
    List<TaskAttachment>? attachments,
    List<TaskActivity>? activity,
    List<String>? tags,
    String? assignedBy,
    double? progress,
  }) {
    return TaskItem(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      projectName: projectName,
      projectId: projectId,
      assignee: assignee ?? this.assignee,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt,
      comments: comments ?? this.comments,
      attachments: attachments ?? this.attachments,
      activity: activity ?? this.activity,
      tags: tags ?? this.tags,
      assignedToMe: assignedToMe,
      assignedBy: assignedBy ?? this.assignedBy,
      progress: progress ?? this.progress,
    );
  }

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? 'Untitled task').toString(),
      description: (json['description'] ?? '').toString(),
      status: TaskStatus.fromValue(json['status']),
      priority: TaskPriority.fromValue(json['priority']),
      projectName: (json['project'] ?? json['project_name'] ?? 'General')
          .toString(),
      projectId: (json['project_id'] ?? json['projectId'])?.toString(),
      assignee: Employee.fromJson(
        (json['assignee'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      dueDate:
          DateTime.tryParse(json['due_date']?.toString() ?? '') ??
          DateTime.now().add(const Duration(days: 3)),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      comments:
          (json['comments'] as List?)
              ?.map(
                (item) =>
                    TaskComment.fromJson((item as Map).cast<String, dynamic>()),
              )
              .toList() ??
          const [],
      attachments:
          (json['attachments'] as List?)
              ?.map(
                (item) => TaskAttachment.fromJson(
                  (item as Map).cast<String, dynamic>(),
                ),
              )
              .toList() ??
          const [],
      tags:
          (json['tags'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      assignedToMe: json['assigned_to_me'] == true,
      assignedBy: _nameOf(json['assigned_by'] ?? json['created_by']),
      progress: _progressOf(json['progress']),
    );
  }
}

String? _nameOf(dynamic value) {
  if (value is Map) {
    final name = value['name'] ?? value['full_name'];
    return name?.toString();
  }
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

double? _progressOf(dynamic value) {
  final number = value is num ? value.toDouble() : double.tryParse('$value');
  if (number == null) return null;
  final normalized = number > 1 ? number / 100 : number;
  return normalized.clamp(0, 1).toDouble();
}

class TaskStats {
  const TaskStats({
    required this.backlog,
    required this.todo,
    required this.inProgress,
    required this.review,
    required this.done,
    this.blocked = 0,
  });

  final int backlog;
  final int todo;
  final int inProgress;
  final int review;
  final int done;
  final int blocked;

  int get total => backlog + todo + inProgress + review + done + blocked;

  double ratio(TaskStatus status) {
    if (total == 0) return 0;
    return count(status) / total;
  }

  int count(TaskStatus status) {
    switch (status) {
      case TaskStatus.backlog:
        return backlog;
      case TaskStatus.todo:
        return todo;
      case TaskStatus.inProgress:
        return inProgress;
      case TaskStatus.review:
        return review;
      case TaskStatus.done:
        return done;
      case TaskStatus.blocked:
        return blocked;
    }
  }

  factory TaskStats.fromJson(Map<String, dynamic> json) => TaskStats(
    backlog: (json['backlog'] as num?)?.toInt() ?? 0,
    todo: (json['todo'] as num?)?.toInt() ?? 0,
    inProgress: (json['in_progress'] as num?)?.toInt() ?? 0,
    review: (json['review'] as num?)?.toInt() ?? 0,
    done: (json['done'] as num?)?.toInt() ?? 0,
    blocked: (json['blocked'] as num?)?.toInt() ?? 0,
  );
}

class TeamProgress {
  const TeamProgress({
    required this.name,
    required this.totalTasks,
    required this.completed,
    required this.inProgress,
    this.color = AppColors.info,
  });

  final String name;
  final int totalTasks;
  final int completed;
  final int inProgress;
  final Color color;

  int get pending => (totalTasks - completed - inProgress).clamp(0, totalTasks);
  double get progress => totalTasks == 0 ? 0 : completed / totalTasks;

  factory TeamProgress.fromJson(Map<String, dynamic> json) => TeamProgress(
    name: (json['name'] ?? 'Team').toString(),
    totalTasks: (json['total'] as num?)?.toInt() ?? 0,
    completed: (json['completed'] as num?)?.toInt() ?? 0,
    inProgress: (json['in_progress'] as num?)?.toInt() ?? 0,
  );
}
