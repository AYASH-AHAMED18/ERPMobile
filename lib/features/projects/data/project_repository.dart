import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../tasks/data/task_repository.dart';
import '../../tasks/domain/task.dart';
import '../domain/project.dart';

abstract class ProjectRepository {
  Future<List<Project>> fetchProjects({ProjectStatus? status, String? search});
}

class TaskBasedProjectRepository implements ProjectRepository {
  TaskBasedProjectRepository(this._taskRepository);

  final TaskRepository _taskRepository;

  @override
  Future<List<Project>> fetchProjects({
    ProjectStatus? status,
    String? search,
  }) async {
    final tasks = await _taskRepository.fetchTasks();
    final grouped = <String, List<TaskItem>>{};
    for (final task in tasks) {
      grouped.putIfAbsent(task.projectName, () => []).add(task);
    }
    final hasOwnershipFlags = tasks.any((task) => task.assignedToMe);
    var names = grouped.keys.toList()..sort();
    if (hasOwnershipFlags) {
      names = names
          .where((name) => grouped[name]!.any((task) => task.assignedToMe))
          .toList();
    }
    final projects = <Project>[];
    for (var index = 0; index < names.length; index++) {
      final name = names[index];
      final projectTasks = grouped[name]!;
      String? explicitId;
      for (final task in projectTasks) {
        if (task.projectId != null && task.projectId!.isNotEmpty) {
          explicitId = task.projectId;
          break;
        }
      }
      projects.add(
        Project.fromTasks(
          id: explicitId ?? _slug(name),
          code:
              explicitId?.toUpperCase() ??
              'PRJ-${(index + 1).toString().padLeft(3, '0')}',
          tasks: projectTasks,
        ),
      );
    }
    var filtered = projects;
    if (status != null) {
      filtered = filtered.where((project) => project.status == status).toList();
    }
    if (search != null && search.trim().isNotEmpty) {
      final query = search.toLowerCase();
      filtered = filtered
          .where(
            (project) =>
                project.name.toLowerCase().contains(query) ||
                project.code.toLowerCase().contains(query) ||
                project.manager.toLowerCase().contains(query),
          )
          .toList();
    }
    filtered.sort((a, b) {
      if (a.status != b.status) {
        return _statusRank(a.status).compareTo(_statusRank(b.status));
      }
      return a.deadline.compareTo(b.deadline);
    });
    return filtered;
  }

  static int _statusRank(ProjectStatus status) => switch (status) {
    ProjectStatus.active => 0,
    ProjectStatus.onHold => 1,
    ProjectStatus.completed => 2,
    ProjectStatus.cancelled => 3,
  };

  static String _slug(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return TaskBasedProjectRepository(ref.watch(taskRepositoryProvider));
});
