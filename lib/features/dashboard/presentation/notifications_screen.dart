import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart' as dates;
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_states.dart';
import '../domain/dashboard.dart';
import 'dashboard_controller.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardControllerProvider);

    return Scaffold(
      backgroundColor: context.canvas,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notifications'),
            Text(
              '${dashboard.value?.unreadNotifications ?? 0} unread',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w400,
                color: context.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: (dashboard.value?.unreadNotifications ?? 0) == 0
                ? null
                : () => ref
                      .read(dashboardControllerProvider.notifier)
                      .markAllNotificationsRead(),
            child: const Text(
              'Mark all read',
              style: TextStyle(fontSize: 11.5),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: dashboard.when(
        loading: () =>
            const AppLoadingIndicator(message: 'Loading your notifications...'),
        error: (error, _) => AppErrorWidget(
          message: 'Notifications could not be loaded.',
          onRetry: () =>
              ref.read(dashboardControllerProvider.notifier).refresh(),
        ),
        data: (snapshot) {
          final notifications = [...snapshot.notifications]
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          if (notifications.isEmpty) {
            return const AppEmptyState(
              title: 'No notifications yet',
              message: 'Attendance, task and notice updates will appear here.',
              icon: Icons.notifications_none_rounded,
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(dashboardControllerProvider.notifier).refresh(),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _NotificationTile(
                  notification: notification,
                  onTap: () => _open(context, ref, notification),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) async {
    if (!notification.isRead) {
      await ref
          .read(dashboardControllerProvider.notifier)
          .markNotificationRead(notification.id);
    }
    if (!context.mounted) return;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _NotificationIcon(notification: notification, size: 42),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        dates.AppDate.relativeTime(notification.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              notification.message,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.55,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      color: notification.isRead
          ? context.surface
          : AppColors.primary.withValues(alpha: context.isDark ? 0.14 : 0.035),
      borderColor: notification.isRead
          ? context.line
          : AppColors.primary.withValues(alpha: 0.2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NotificationIcon(notification: notification),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: notification.isRead
                              ? FontWeight.w600
                              : FontWeight.w800,
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                    if (!notification.isRead) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  notification.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.35,
                    color: context.textSecondary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  dates.AppDate.relativeTime(notification.createdAt),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: context.textSecondary.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon({required this.notification, this.size = 38});

  final AppNotification notification;
  final double size;

  @override
  Widget build(BuildContext context) {
    final icon = switch (notification.type) {
      NotificationType.info => Icons.info_outline_rounded,
      NotificationType.success => Icons.task_alt_rounded,
      NotificationType.warning => Icons.warning_amber_rounded,
      NotificationType.error => Icons.error_outline_rounded,
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: notification.type.color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, size: size * 0.5, color: notification.type.color),
    );
  }
}
