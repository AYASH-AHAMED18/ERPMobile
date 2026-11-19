import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_config.dart';
import '../../../core/mock/mock_database.dart';
import '../../../core/models/employee.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/response_utils.dart';
import '../../calendar/domain/calendar_event.dart';
import '../../tasks/domain/task.dart';
import '../domain/dashboard.dart';

abstract class DashboardRepository {
  Future<DashboardSnapshot> fetchDashboard();
  Future<Notice> createNotice({
    required String title,
    required String description,
    required NoticePriority priority,
  });
  Future<void> markNoticeRead(String noticeId);
  Future<void> markNotificationRead(String notificationId);
}

class MockDashboardRepository implements DashboardRepository {
  MockDashboardRepository(this._db);

  final MockDatabase _db;

  @override
  Future<DashboardSnapshot> fetchDashboard() async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    return DashboardSnapshot(
      notices: List.unmodifiable(_db.notices),
      notifications: List.unmodifiable(_db.notifications),
      employeeStatus: _db.employeeStatus,
      taskStats: _db.taskStats,
      teamProgress: List.unmodifiable(_db.teamProgress),
      events: List.unmodifiable(_db.events),
      unreadNoticeCount: _db.notices.where((notice) => !notice.isRead).length,
    );
  }

  @override
  Future<Notice> createNotice({
    required String title,
    required String description,
    required NoticePriority priority,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final author = _db.currentUser;
    final notice = Notice(
      id: 'notice-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      postedAt: DateTime.now(),
      author: author.name,
      authorDesignation: author.designation,
      authorDepartment: author.department,
      authorAvatarUrl: author.avatarUrl,
      priority: priority,
    );
    _db.notices.insert(0, notice);
    return notice;
  }

  @override
  Future<void> markNoticeRead(String noticeId) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final index = _db.notices.indexWhere((notice) => notice.id == noticeId);
    if (index != -1) {
      _db.notices[index] = _db.notices[index].copyWith(isRead: true);
    }
  }

  @override
  Future<void> markNotificationRead(String notificationId) async {
    final index = _db.notifications.indexWhere(
      (notification) => notification.id == notificationId,
    );
    if (index != -1) {
      _db.notifications[index] = _db.notifications[index].copyWith(
        isRead: true,
      );
    }
  }
}

class ApiDashboardRepository implements DashboardRepository {
  ApiDashboardRepository(this._client);

  final ApiClient _client;

  @override
  Future<DashboardSnapshot> fetchDashboard() async {
    final data = asMap(await _client.get(ApiEndpoints.dashboard));
    final notices = asList(
      data['notices'],
    ).map((item) => Notice.fromJson(mapOf(item))).toList();
    final notifications = asList(
      data['notifications'],
    ).map((item) => AppNotification.fromJson(mapOf(item))).toList();
    final employees = asList(
      data['employee_status'],
    ).map((item) => Employee.fromJson(mapOf(item))).toList();
    final atWork = employees
        .where((employee) => employee.workStatus.name == 'atWork')
        .length;
    final onLeave = employees
        .where((employee) => employee.workStatus.name == 'onLeave')
        .length;
    return DashboardSnapshot(
      notices: notices,
      notifications: notifications,
      employeeStatus: EmployeeStatusSummary(
        atWork: atWork,
        onLeave: onLeave,
        employees: employees,
      ),
      taskStats: TaskStats.fromJson(mapOf(data['task_stats'])),
      teamProgress: asList(
        data['team_progress'],
      ).map((item) => TeamProgress.fromJson(mapOf(item))).toList(),
      events: asList(
        data['events'],
      ).map((item) => CalendarEvent.fromJson(mapOf(item))).toList(),
      unreadNoticeCount: notices.where((notice) => !notice.isRead).length,
    );
  }

  @override
  Future<Notice> createNotice({
    required String title,
    required String description,
    required NoticePriority priority,
  }) async {
    final data = await _client.post(
      ApiEndpoints.notices,
      data: {
        'title': title,
        'description': description,
        'priority': priority.name,
      },
    );
    return Notice.fromJson(asMap(data));
  }

  @override
  Future<void> markNoticeRead(String noticeId) async {
    await _client.patch('${ApiEndpoints.notices}/$noticeId/read');
  }

  @override
  Future<void> markNotificationRead(String notificationId) async {
    await _client.patch('${ApiEndpoints.notifications}/$notificationId/read');
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  if (AppConfig.useMockData) {
    return MockDashboardRepository(MockDatabase.instance);
  }
  return ApiDashboardRepository(ref.watch(apiClientProvider));
});
