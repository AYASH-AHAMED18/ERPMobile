import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_sizes.dart';
import '../../../app/theme/theme_controller.dart';
import '../../../core/models/employee.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/app_states.dart';
import '../../attendance/presentation/attendance_controller.dart';
import '../../authentication/presentation/auth_controller.dart';
import '../../chat/presentation/chat_controllers.dart';
import '../domain/dashboard.dart';
import 'dashboard_controller.dart';
import 'widgets/at_work_card.dart';
import 'widgets/attendance_card.dart';
import 'widgets/dashboard_calendar_card.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/notice_board_card.dart';
import 'widgets/on_leave_card.dart';
import 'widgets/project_task_status_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardControllerProvider);
    final employee = ref.watch(currentEmployeeProvider);
    final themeMode =
        ref.watch(themeControllerProvider).value ?? ThemeMode.light;
    final unread = dashboard.value?.unreadNotifications ?? 0;

    return Scaffold(
      backgroundColor: context.canvas,
      drawer: const AppDrawer(),
      body: Builder(
        builder: (scaffoldContext) => SafeArea(
          bottom: false,
          child: Column(
            children: [
              DashboardHeader(
                employee: employee,
                unreadNotifications: unread,
                isDark: themeMode == ThemeMode.dark,
                onOpenMenu: () => Scaffold.of(scaffoldContext).openDrawer(),
                onScanQr: () => context.push('/scanner'),
                onNotifications: () => context.push('/notifications'),
                onToggleTheme: () =>
                    ref.read(themeControllerProvider.notifier).toggle(),
                onProfile: () => context.go('/more/profile'),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await Future.wait([
                      ref.read(dashboardControllerProvider.notifier).refresh(),
                      ref.read(attendanceControllerProvider.notifier).refresh(),
                      ref
                          .read(conversationsControllerProvider.notifier)
                          .refresh(),
                    ]);
                  },
                  color: AppColors.primary,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screen,
                      AppSpacing.lg,
                      AppSpacing.screen,
                      AppSpacing.xxl,
                    ),
                    children: [
                      AttendanceCard(
                        employee:
                            employee ??
                            const Employee(
                              id: '',
                              employeeCode: '',
                              name: 'Employee',
                              email: '',
                              phone: '',
                              department: '',
                              designation: '',
                            ),
                        onViewHistory: () => context.go('/summary'),
                      ),
                      const SizedBox(height: AppSpacing.cardGap),
                      dashboard.when(
                        loading: () => const _DashboardLoadingSection(),
                        error: (error, _) => _DashboardErrorSection(
                          onRetry: () => ref
                              .read(dashboardControllerProvider.notifier)
                              .refresh(),
                        ),
                        data: (snapshot) => _DashboardSections(
                          snapshot: snapshot,
                          canPost: employee?.canPostNotices ?? false,
                          onReadNotice: (notice) =>
                              _openNotice(context, ref, notice),
                          onViewAllNotices: () => showAllNoticesSheet(
                            context,
                            notices: snapshot.notices,
                            onNoticeTap: (notice) =>
                                _openNotice(context, ref, notice),
                          ),
                          onOpenCalendar: () => context.go('/more/calendar'),
                          onOpenLeave: () => context.go('/leave'),
                          onOpenBoard: () => context.go('/more/tasks'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openNotice(BuildContext context, WidgetRef ref, Notice notice) {
    if (!notice.isRead) {
      ref.read(dashboardControllerProvider.notifier).markNoticeRead(notice.id);
    }
    showNoticeDetails(context, notice);
  }
}

class _DashboardSections extends StatelessWidget {
  const _DashboardSections({
    required this.snapshot,
    required this.canPost,
    required this.onReadNotice,
    required this.onViewAllNotices,
    required this.onOpenCalendar,
    required this.onOpenLeave,
    required this.onOpenBoard,
  });

  final DashboardSnapshot snapshot;
  final bool canPost;
  final ValueChanged<Notice> onReadNotice;
  final VoidCallback onViewAllNotices;
  final VoidCallback onOpenCalendar;
  final VoidCallback onOpenLeave;
  final VoidCallback onOpenBoard;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NoticeBoardCard(
          notices: snapshot.notices,
          unreadCount: snapshot.unreadNoticeCount,
          canPost: canPost,
          onReadMore: onReadNotice,
          onViewAll: onViewAllNotices,
        ),
        const SizedBox(height: AppSpacing.cardGap),
        DashboardCalendarCard(
          events: snapshot.events,
          onViewFull: onOpenCalendar,
          onEventTap: (_) => onOpenCalendar(),
        ),
        const SizedBox(height: AppSpacing.cardGap),
        AtWorkCard(status: snapshot.employeeStatus),
        const SizedBox(height: AppSpacing.cardGap),
        OnLeaveCard(status: snapshot.employeeStatus, onOpen: onOpenLeave),
        const SizedBox(height: AppSpacing.cardGap),
        ProjectTaskStatusCard(
          stats: snapshot.taskStats,
          projects: snapshot.teamProgress,
          onOpenBoard: onOpenBoard,
        ),
      ],
    );
  }
}

class _DashboardLoadingSection extends StatelessWidget {
  const _DashboardLoadingSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _DashboardLoadingCard(height: AppSizes.loadingNotice, message: 'Loading notices...'),
        SizedBox(height: AppSpacing.cardGap),
        _DashboardLoadingCard(height: AppSizes.loadingDashboard, message: 'Loading dashboard...'),
        SizedBox(height: AppSpacing.cardGap),
        _DashboardLoadingCard(height: AppSizes.loadingTeams, message: 'Loading teams...'),
      ],
    );
  }
}

class _DashboardLoadingCard extends StatelessWidget {
  const _DashboardLoadingCard({required this.height, required this.message});

  final double height;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(AppRadii.xxl),
        border: Border.all(color: context.line),
        boxShadow: AppShadows.soft,
      ),
      child: AppLoadingIndicator(message: message),
    );
  }
}

class _DashboardErrorSection extends StatelessWidget {
  const _DashboardErrorSection({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(AppRadii.xxl),
        border: Border.all(color: context.line),
        boxShadow: AppShadows.soft,
      ),
      child: AppErrorWidget(
        message: 'Dashboard information could not be loaded.',
        compact: true,
        onRetry: onRetry,
      ),
    );
  }
}
