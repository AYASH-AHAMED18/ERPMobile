import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/models/employee.dart';
import '../../tasks/domain/task.dart';

enum ProjectStatus {
  active('Active', AppColors.primary, Icons.play_circle_outline_rounded),
  onHold('On hold', AppColors.warning, Icons.pause_circle_outline_rounded),
  completed('Completed', AppColors.success, Icons.check_circle_outline_rounded),
  cancelled('Cancelled', AppColors.backlog, Icons.cancel_outlined);

  const ProjectStatus(this.label, this.color, this.icon);
  final String label;
  final Color color;
  final IconData icon;

  static ProjectStatus fromValue(dynamic value) {
    final normalized = value?.toString().toLowerCase().replaceAll('_', ' ');
    return ProjectStatus.values.firstWhere(
      (status) =>
          status.name == normalized || status.label.toLowerCase() == normalized,
      orElse: () => ProjectStatus.active,
    );
  }
}

class Project {
  const Project({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.manager,
    required this.team,
    required this.startDate,
    required this.deadline,
    required this.priority,
    required this.status,
    required this.progress,
    required this.tasks,
  });

  final String id;
  final String code;
  final String name;
  final String description;
  final String manager;
  final List<Employee> team;
  final DateTime? startDate;
  final DateTime deadline;
  final TaskPriority priority;
  final ProjectStatus status;
  final double progress;
  final List<TaskItem> tasks;

  int get totalTasks => tasks.length;
  int get completedTasks =>
      tasks.where((task) => task.status == TaskStatus.done).length;
  int get pendingTasks =>
      tasks.where((task) => task.status != TaskStatus.done).length;
  int get blockedTasks =>
      tasks.where((task) => task.status == TaskStatus.blocked).length;

  bool get isDelayed =>
      deadline.isBefore(DateTime.now()) &&
      status != ProjectStatus.completed &&
      status != ProjectStatus.cancelled;

  factory Project.fromTasks({
    required String id,
    required String code,
    required List<TaskItem> tasks,
  }) {
    final name = tasks.first.projectName;
    final teamById = <String, Employee>{};
    final managerCounts = <String, int>{};
    final createdDates = <DateTime>[];
    for (final task in tasks) {
      teamById[task.assignee.id] = task.assignee;
      final manager = task.assignedBy;
      if (manager != null && manager.trim().isNotEmpty) {
        managerCounts[manager] = (managerCounts[manager] ?? 0) + 1;
      }
      if (task.createdAt != null) createdDates.add(task.createdAt!);
    }
    final manager = managerCounts.entries.isEmpty
        ? 'Not assigned'
        : (managerCounts.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .first
              .key;
    final team = teamById.values.toList();
    final startDate = createdDates.isEmpty
        ? null
        : createdDates.reduce((a, b) => a.isBefore(b) ? a : b);
    final deadline = tasks
        .map((task) => task.dueDate)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final priority = tasks
        .map((task) => task.priority)
        .reduce((a, b) => _priorityRank(a) >= _priorityRank(b) ? a : b);
    final blocked = tasks.any((task) => task.status == TaskStatus.blocked);
    final completed = tasks.every((task) => task.status == TaskStatus.done);
    final status = completed
        ? ProjectStatus.completed
        : blocked
        ? ProjectStatus.onHold
        : ProjectStatus.active;
    final progress =
        tasks.fold<double>(0, (sum, task) => sum + _taskProgress(task)) /
        tasks.length;

    return Project(
      id: id,
      code: code,
      name: name,
      description:
          '${tasks.length} task${tasks.length == 1 ? '' : 's'} coordinated across ${team.length} team member${team.length == 1 ? '' : 's'}.',
      manager: manager,
      team: team,
      startDate: startDate,
      deadline: deadline,
      priority: priority,
      status: status,
      progress: progress.clamp(0, 1).toDouble(),
      tasks: tasks,
    );
  }

  static int _priorityRank(TaskPriority priority) => switch (priority) {
    TaskPriority.low => 0,
    TaskPriority.medium => 1,
    TaskPriority.high => 2,
    TaskPriority.urgent => 3,
  };

  static double _taskProgress(TaskItem task) {
    if (task.status == TaskStatus.done) return 1;
    if (task.progress != null) return task.progress!;
    return switch (task.status) {
      TaskStatus.backlog => 0,
      TaskStatus.todo => 0.15,
      TaskStatus.inProgress => 0.5,
      TaskStatus.review => 0.8,
      TaskStatus.done => 1,
      TaskStatus.blocked => 0.25,
    };
  }
}
