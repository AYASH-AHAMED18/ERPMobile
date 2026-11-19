import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/task_repository.dart';
import '../domain/task.dart';

class TaskBoardController extends AsyncNotifier<List<TaskItem>> {
  @override
  Future<List<TaskItem>> build() {
    return ref.watch(taskRepositoryProvider).fetchTasks();
  }

  Future<void> refresh() async {
    state = const AsyncLoading<List<TaskItem>>();
    state = await AsyncValue.guard(
      () => ref.read(taskRepositoryProvider).fetchTasks(),
    );
  }
}

class TaskDetailController extends AsyncNotifier<TaskItem> {
  TaskDetailController(this.taskId);

  final String taskId;

  @override
  Future<TaskItem> build() {
    return ref.watch(taskRepositoryProvider).fetchTask(taskId);
  }

  Future<void> updateStatus(TaskStatus status) async {
    final updated = await ref
        .read(taskRepositoryProvider)
        .updateStatus(taskId, status);
    state = AsyncData(updated);
    ref.read(taskBoardControllerProvider.notifier).refresh();
  }

  Future<void> addComment(String message) async {
    final updated = await ref
        .read(taskRepositoryProvider)
        .addComment(taskId, message);
    state = AsyncData(updated);
  }
}

final taskBoardControllerProvider =
    AsyncNotifierProvider<TaskBoardController, List<TaskItem>>(
      TaskBoardController.new,
    );

final taskDetailControllerProvider = AsyncNotifierProvider.autoDispose
    .family<TaskDetailController, TaskItem, String>(TaskDetailController.new);
