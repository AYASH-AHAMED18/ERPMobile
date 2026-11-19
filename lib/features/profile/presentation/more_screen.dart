import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/widgets/app_module_scaffold.dart';
import '../../../core/widgets/employee_avatar.dart';
import '../../../core/widgets/status_badge.dart';
import '../../authentication/presentation/auth_controller.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  static const _workItems = [
    _MoreItem(
      label: 'Calendar',
      description: 'Schedule & deadlines',
      icon: Icons.calendar_month_outlined,
      color: AppColors.info,
      route: '/more/calendar',
    ),
    _MoreItem(
      label: 'Events',
      description: 'Company activities',
      icon: Icons.celebration_outlined,
      color: AppColors.warning,
      route: '/more/events',
    ),
    _MoreItem(
      label: 'My Projects',
      description: 'Projects & progress',
      icon: Icons.folder_copy_outlined,
      color: AppColors.primary,
      route: '/more/projects',
    ),
    _MoreItem(
      label: 'My Tasks',
      description: 'Tasks & status',
      icon: Icons.assignment_outlined,
      color: AppColors.review,
      route: '/more/tasks',
    ),
  ];

  static const _serviceItems = [
    _MoreItem(
      label: 'Live meetings',
      description: 'Calls & stand-ups',
      icon: Icons.videocam_outlined,
      color: AppColors.error,
      route: '/live',
    ),
    _MoreItem(
      label: 'Sharing',
      description: 'Shared documents',
      icon: Icons.folder_shared_outlined,
      color: AppColors.success,
      route: '/sharing',
    ),
    _MoreItem(
      label: 'Mailbox',
      description: 'Inbox & compose',
      icon: Icons.mail_outline_rounded,
      color: AppColors.info,
      route: '/mailbox',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employee = ref.watch(currentEmployeeProvider);
    return ErpModuleScaffold(
      body: ListView(
        padding: const EdgeInsets.only(bottom: 22),
        children: [
          const AppPageTitle(
            title: 'More',
            subtitle: 'Your workspace and account',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => context.go('/more/profile'),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.line),
                  ),
                  child: Row(
                    children: [
                      EmployeeAvatar(
                        name: employee?.name ?? 'Employee',
                        imageUrl: employee?.avatarUrl,
                        size: 50,
                        borderColor: AppColors.primary.withValues(alpha: 0.2),
                        showStatus: true,
                        isOnline:
                            employee?.workStatus.name == 'atWork' ||
                            employee?.workStatus.name == 'remote',
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              employee?.name ?? 'Employee',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '${employee?.employeeCode ?? ''} • ${employee?.designation ?? ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9.5,
                                color: context.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Wrap(
                              spacing: 5,
                              runSpacing: 4,
                              children: [
                                StatusBadge(
                                  label: employee?.department ?? 'Department',
                                  color: AppColors.info,
                                  compact: true,
                                ),
                                StatusBadge(
                                  label:
                                      employee?.workStatus.label ?? 'At work',
                                  color: AppColors.success,
                                  compact: true,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: context.textSecondary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 700 ? 4 : 2;
                final spacing = 9.0;
                final width =
                    (constraints.maxWidth - spacing * (columns - 1)) / columns;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: _workItems
                      .map(
                        (item) => SizedBox(
                          width: width,
                          child: _MoreTile(
                            item: item,
                            onTap: () => context.go(item.route),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _MenuCard(
              children: [
                _MenuTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Employee Profile',
                  subtitle: 'View your employment information',
                  onTap: () => context.go('/more/profile'),
                ),
                _MenuTile(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  subtitle: 'Appearance, security and preferences',
                  onTap: () => context.push('/settings'),
                ),
                _MenuTile(
                  icon: Icons.help_outline_rounded,
                  title: 'Help & Support',
                  subtitle: 'FAQs and contact options',
                  onTap: () => context.go('/more/help'),
                ),
                _MenuTile(
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  subtitle: 'End your current session securely',
                  color: AppColors.error,
                  onTap: () => _confirmLogout(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ModuleSectionTitle(
              title: 'Other services',
              subtitle: 'More tools connected to the ERP',
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _MenuCard(
              children: _serviceItems
                  .map(
                    (item) => _MenuTile(
                      icon: item.icon,
                      title: item.label,
                      subtitle: item.description,
                      color: item.color,
                      onTap: () => context.push(item.route),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '${AppConfig.appName} Staff ERP • v${AppConfig.appVersion}',
              style: TextStyle(fontSize: 9, color: context.textSecondary),
            ),
          ),
          if (AppConfig.useMockData)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'Demo data mode',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.info.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
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
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 18),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({required this.item, required this.onTap});

  final _MoreItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(item.icon, size: 17, color: item.color),
              ),
              const SizedBox(height: 9),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                item.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 8.5, color: context.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) const Divider(height: 1, indent: 48),
          ],
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.primary;
    return ListTile(
      dense: true,
      onTap: onTap,
      leading: Icon(icon, size: 19, color: accent),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color ?? context.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 9.5, color: context.textSecondary),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 18,
        color: context.textSecondary,
      ),
    );
  }
}

class _MoreItem {
  const _MoreItem({
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    required this.route,
  });

  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final String route;
}
