import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/dashboard_repository.dart';
import '../domain/dashboard.dart';

class DashboardController extends AsyncNotifier<DashboardSnapshot> {
  @override
  Future<DashboardSnapshot> build() {
    return ref.watch(dashboardRepositoryProvider).fetchDashboard();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(dashboardRepositoryProvider).fetchDashboard(),
    );
  }

  Future<Notice> createNotice({
    required String title,
    required String description,
    required NoticePriority priority,
  }) async {
    final notice = await ref
        .read(dashboardRepositoryProvider)
        .createNotice(
          title: title,
          description: description,
          priority: priority,
        );
    final snapshot = state.value;
    if (snapshot != null) {
      final notices = [notice, ...snapshot.notices];
      state = AsyncData(
        DashboardSnapshot(
          notices: notices,
          notifications: snapshot.notifications,
          employeeStatus: snapshot.employeeStatus,
          taskStats: snapshot.taskStats,
          teamProgress: snapshot.teamProgress,
          events: snapshot.events,
          unreadNoticeCount: snapshot.unreadNoticeCount,
        ),
      );
    }
    return notice;
  }

  Future<void> markNoticeRead(String noticeId) async {
    await ref.read(dashboardRepositoryProvider).markNoticeRead(noticeId);
    final snapshot = state.value;
    if (snapshot == null) return;
    final notices = snapshot.notices
        .map(
          (notice) =>
              notice.id == noticeId ? notice.copyWith(isRead: true) : notice,
        )
        .toList();
    state = AsyncData(
      DashboardSnapshot(
        notices: notices,
        notifications: snapshot.notifications,
        employeeStatus: snapshot.employeeStatus,
        taskStats: snapshot.taskStats,
        teamProgress: snapshot.teamProgress,
        events: snapshot.events,
        unreadNoticeCount: notices.where((notice) => !notice.isRead).length,
      ),
    );
  }

  Future<void> markNotificationRead(String id) async {
    await ref.read(dashboardRepositoryProvider).markNotificationRead(id);
    final snapshot = state.value;
    if (snapshot == null) return;
    state = AsyncData(
      DashboardSnapshot(
        notices: snapshot.notices,
        notifications: snapshot.notifications
            .map(
              (notification) => notification.id == id
                  ? notification.copyWith(isRead: true)
                  : notification,
            )
            .toList(),
        employeeStatus: snapshot.employeeStatus,
        taskStats: snapshot.taskStats,
        teamProgress: snapshot.teamProgress,
        events: snapshot.events,
        unreadNoticeCount: snapshot.unreadNoticeCount,
      ),
    );
  }

  Future<void> markAllNotificationsRead() async {
    final snapshot = state.value;
    if (snapshot == null) return;
    for (final notification in snapshot.notifications.where(
      (item) => !item.isRead,
    )) {
      await ref
          .read(dashboardRepositoryProvider)
          .markNotificationRead(notification.id);
    }
    state = AsyncData(
      DashboardSnapshot(
        notices: snapshot.notices,
        notifications: snapshot.notifications
            .map((notification) => notification.copyWith(isRead: true))
            .toList(),
        employeeStatus: snapshot.employeeStatus,
        taskStats: snapshot.taskStats,
        teamProgress: snapshot.teamProgress,
        events: snapshot.events,
        unreadNoticeCount: snapshot.unreadNoticeCount,
      ),
    );
  }
}

final dashboardControllerProvider =
    AsyncNotifierProvider<DashboardController, DashboardSnapshot>(
      DashboardController.new,
    );
