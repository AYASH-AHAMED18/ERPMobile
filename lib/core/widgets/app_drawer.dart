import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../features/authentication/presentation/auth_controller.dart';
import 'brand_logo.dart';
import 'employee_avatar.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  static const _items = [
    _DrawerItem(
      'Dashboard',
      Icons.space_dashboard_outlined,
      '/dashboard',
      useShell: true,
    ),
    _DrawerItem('Calendar', Icons.calendar_month_outlined, '/more/calendar'),
    _DrawerItem('Events', Icons.celebration_outlined, '/more/events'),
    _DrawerItem('My projects', Icons.folder_copy_outlined, '/more/projects'),
    _DrawerItem('My tasks', Icons.assignment_outlined, '/more/tasks'),
    _DrawerItem(
      'Chat',
      Icons.chat_bubble_outline_rounded,
      '/chat',
      useShell: true,
    ),
    _DrawerItem('Live meetings', Icons.videocam_outlined, '/live'),
    _DrawerItem('Leave', Icons.beach_access_outlined, '/leave', useShell: true),
    _DrawerItem(
      'My summary',
      Icons.insights_outlined,
      '/summary',
      useShell: true,
    ),
    _DrawerItem('Sharing', Icons.folder_shared_outlined, '/sharing'),
    _DrawerItem('Mailbox', Icons.mail_outline_rounded, '/mailbox'),
    _DrawerItem('Settings', Icons.settings_outlined, '/settings'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employee = ref.watch(currentEmployeeProvider);
    return Drawer(
      backgroundColor: context.surface,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BrandLogo(size: 34),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      EmployeeAvatar(
                        name: employee?.name ?? 'Employee',
                        imageUrl: employee?.avatarUrl,
                        size: 42,
                        borderColor: Colors.white,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              employee?.name ?? 'Employee',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${employee?.employeeCode ?? ''} • ${employee?.designation ?? ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                children: _items
                    .map(
                      (item) => ListTile(
                        dense: true,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        leading: Icon(
                          item.icon,
                          size: 19,
                          color: context.textSecondary,
                        ),
                        title: Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: context.textPrimary,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          if (item.useShell) {
                            context.go(item.route);
                          } else {
                            context.push(item.route);
                          }
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(10),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                leading: const Icon(
                  Icons.logout_rounded,
                  size: 19,
                  color: AppColors.error,
                ),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Logout?'),
                      content: const Text(
                        'You will need to sign in again to access the ERP.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await ref.read(authControllerProvider.notifier).logout();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem {
  const _DrawerItem(this.label, this.icon, this.route, {this.useShell = false});

  final String label;
  final IconData icon;
  final String route;
  final bool useShell;
}
