import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_config.dart';
import '../../../core/mock/mock_database.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/response_utils.dart';
import '../domain/task.dart';

abstract class TaskRepository {
  Future<List<TaskItem>> fetchTasks({
    String? assignedTo,
    TaskStatus? status,
    String? search,
  });

  Future<TaskItem> fetchTask(String id);
  Future<TaskItem> updateStatus(String id, TaskStatus status);
  Future<TaskItem> addComment(String id, String message);
}

class MockTaskRepository implements TaskRepository {
  MockTaskRepository(this._db);

  final MockDatabase _db;

  @override
  Future<List<TaskItem>> fetchTasks({
    String? assignedTo,
    TaskStatus? status,
    String? search,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 550));
    var items = List<TaskItem>.from(_db.tasks);
    if (assignedTo == 'me') {
      items = items.where((task) => task.assignedToMe).toList();
    } else if (assignedTo != null && assignedTo.isNotEmpty) {
      items = items.where((task) => task.assignee.id == assignedTo).toList();
    }
    if (status != null) {
      items = items.where((task) => task.status == status).toList();
    }
    if (search != null && search.trim().isNotEmpty) {
      final query = search.toLowerCase();
      items = items
          .where(
            (task) =>
                task.title.toLowerCase().contains(query) ||
                task.projectName.toLowerCase().contains(query) ||
                task.assignee.name.toLowerCase().contains(query),
          )
          .toList();
    }
    return items;
  }

  @override
  Future<TaskItem> fetchTask(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return _db.tasks.firstWhere((task) => task.id == id);
  }

  @override
  Future<TaskItem> updateStatus(String id, TaskStatus status) async {
    await Future<void>.delayed(const Duration(milliseconds: 550));
    final index = _db.tasks.indexWhere((task) => task.id == id);
    if (index == -1) throw StateError('Task not found');
    final task = _db.tasks[index].copyWith(
      status: status,
      activity: [
        TaskActivity(
          id: 'activity-${DateTime.now().millisecondsSinceEpoch}',
          message: 'changed status to ${status.label}',
          actor: _db.currentUser.name,
          createdAt: DateTime.now(),
        ),
        ..._db.tasks[index].activity,
      ],
    );
    _db.tasks[index] = task;
    return task;
  }

  @override
  Future<TaskItem> addComment(String id, String message) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final index = _db.tasks.indexWhere((task) => task.id == id);
    if (index == -1) throw StateError('Task not found');
    final task = _db.tasks[index];
    final updated = task.copyWith(
      comments: [
        ...task.comments,
        TaskComment(
          id: 'comment-${DateTime.now().millisecondsSinceEpoch}',
          author: _db.currentUser,
          message: message,
          createdAt: DateTime.now(),
        ),
      ],
    );
    _db.tasks[index] = updated;
    return updated;
  }
}

class ApiTaskRepository implements TaskRepository {
  ApiTaskRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<TaskItem>> fetchTasks({
    String? assignedTo,
    TaskStatus? status,
    String? search,
  }) async {
    final data = await _client.get(
      ApiEndpoints.tasks,
      query: {
        'assigned_to': ?assignedTo,
        'status': ?status?.name,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return asList(data).map((item) => TaskItem.fromJson(mapOf(item))).toList();
  }

  @override
  Future<TaskItem> fetchTask(String id) async {
    final data = await _client.get(ApiEndpoints.task(id));
    return TaskItem.fromJson(asMap(data));
  }

  @override
  Future<TaskItem> updateStatus(String id, TaskStatus status) async {
    final data = await _client.patch(
      ApiEndpoints.task(id),
      data: {'status': status.name},
    );
    return TaskItem.fromJson(asMap(data));
  }

  @override
  Future<TaskItem> addComment(String id, String message) async {
    final data = await _client.post(
      ApiEndpoints.taskComments(id),
      data: {'message': message},
    );
    return TaskItem.fromJson(asMap(data));
  }
}

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  if (AppConfig.useMockData) {
    return MockTaskRepository(MockDatabase.instance);
  }
  return ApiTaskRepository(ref.watch(apiClientProvider));
});
