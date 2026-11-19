import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/models/employee.dart';
import '../../../core/utils/date_utils.dart' as dates;
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_module_scaffold.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/employee_avatar.dart';
import '../../../core/widgets/status_badge.dart';
import '../../authentication/presentation/auth_controller.dart';

class EmployeeProfileScreen extends ConsumerWidget {
  const EmployeeProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employee = ref.watch(currentEmployeeProvider);
    if (employee == null) {
      return const ErpModuleScaffold(
        body: AppEmptyState(
          title: 'Profile unavailable',
          message: 'Sign in again to view your employee profile.',
          icon: Icons.person_off_outlined,
        ),
      );
    }
    return ErpModuleScaffold(
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          AppPageTitle(
            title: 'Employee Profile',
            subtitle: 'Your employment and contact information',
            onBack: () => context.pop(),
            trailing: IconButton(
              tooltip: 'Edit profile',
              onPressed: () => context.push('/settings'),
              icon: const Icon(Icons.edit_outlined, size: 20),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _ProfileHero(employee: employee),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  const _SectionTitle(
                    icon: Icons.badge_outlined,
                    title: 'Employment information',
                  ),
                  _InfoTile(
                    icon: Icons.badge_outlined,
                    label: 'Employee ID',
                    value: employee.employeeCode,
                  ),
                  _InfoTile(
                    icon: Icons.apartment_rounded,
                    label: 'Department',
                    value: employee.department,
                  ),
                  _InfoTile(
                    icon: Icons.work_outline_rounded,
                    label: 'Designation',
                    value: employee.designation,
                  ),
                  _InfoTile(
                    icon: Icons.verified_user_outlined,
                    label: 'Role',
                    value: employee.role,
                  ),
                  _InfoTile(
                    icon: Icons.calendar_today_outlined,
                    label: 'Joined',
                    value: employee.joinedAt == null
                        ? 'Not available'
                        : dates.AppDate.shortDate(employee.joinedAt!),
                  ),
                  _InfoTile(
                    icon: Icons.location_on_outlined,
                    label: 'Location',
                    value: employee.location ?? 'Not set',
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  const _SectionTitle(
                    icon: Icons.contact_mail_outlined,
                    title: 'Contact details',
                  ),
                  _ContactTile(
                    icon: Icons.mail_outline_rounded,
                    label: 'Email',
                    value: employee.email,
                    onTap: employee.email.isEmpty
                        ? null
                        : () => _open(
                            Uri(scheme: 'mailto', path: employee.email),
                          ),
                  ),
                  _ContactTile(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: employee.phone,
                    onTap: employee.phone.isEmpty
                        ? null
                        : () => _open(Uri(scheme: 'tel', path: employee.phone)),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.18),
                ),
              ),
              child: const Text(
                'Name, department, designation and email are managed by HR. You can update your phone and location from Settings.',
                style: TextStyle(fontSize: 10, height: 1.45),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _open(Uri uri) async {
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return;
    }
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.employee});

  final Employee employee;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          EmployeeAvatar(
            name: employee.name,
            imageUrl: employee.avatarUrl,
            size: 62,
            borderColor: Colors.white,
            backgroundColor: Colors.white,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employee.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  employee.designation,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 5,
                  runSpacing: 4,
                  children: [
                    StatusBadge(
                      label: employee.department,
                      color: Colors.white,
                      compact: true,
                    ),
                    StatusBadge(
                      label: employee.workStatus.label,
                      color: employee.workStatus == EmployeeWorkStatus.atWork
                          ? AppColors.success
                          : AppColors.warning,
                      compact: true,
                      filled: employee.workStatus == EmployeeWorkStatus.atWork,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 5),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 7),
          Text(
            title,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: context.textSecondary),
          const SizedBox(width: 9),
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: TextStyle(fontSize: 10, color: context.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      onTap: onTap,
      leading: Icon(icon, size: 18, color: AppColors.primary),
      title: Text(
        label,
        style: TextStyle(fontSize: 10, color: context.textSecondary),
      ),
      subtitle: Text(
        value.isEmpty ? 'Not available' : value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: context.textPrimary,
        ),
      ),
      trailing: onTap == null
          ? null
          : Icon(
              Icons.open_in_new_rounded,
              size: 15,
              color: context.textSecondary,
            ),
    );
  }
}
