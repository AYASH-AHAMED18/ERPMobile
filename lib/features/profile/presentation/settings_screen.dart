import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/theme_controller.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/models/employee.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/employee_avatar.dart';
import '../../../core/widgets/status_badge.dart';
import '../../authentication/presentation/auth_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _loadingNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final enabled = await ref
        .read(sessionStorageProvider)
        .readNotificationsEnabled();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = enabled;
      _loadingNotifications = false;
    });
  }

  Future<void> _setNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    await ref.read(sessionStorageProvider).saveNotificationsEnabled(value);
    if (!mounted) return;
    showAppSnackBar(
      context,
      value ? 'Notifications enabled.' : 'Notifications muted.',
      isSuccess: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final employee = ref.watch(currentEmployeeProvider);
    final themeMode =
        ref.watch(themeControllerProvider).value ?? ThemeMode.light;

    return Scaffold(
      backgroundColor: context.canvas,
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: employee == null
          ? const AppEmptyState(
              title: 'Profile unavailable',
              message: 'Sign in again to view your employee profile.',
              icon: Icons.person_off_outlined,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 22),
              children: [
                _ProfileHeader(
                  employee: employee,
                  onEdit: () => _openEditProfile(employee),
                ),
                const SizedBox(height: 12),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _SettingsSectionTitle(
                        icon: Icons.badge_outlined,
                        title: 'Employee information',
                      ),
                      _InfoTile(
                        icon: Icons.badge_outlined,
                        label: 'Employee ID',
                        value: employee.employeeCode,
                      ),
                      _InfoTile(
                        icon: Icons.mail_outline_rounded,
                        label: 'Email',
                        value: employee.email,
                      ),
                      _InfoTile(
                        icon: Icons.phone_outlined,
                        label: 'Phone',
                        value: employee.phone,
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
                        icon: Icons.location_on_outlined,
                        label: 'Location',
                        value: employee.location ?? 'Not set',
                      ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _SettingsSectionTitle(
                        icon: Icons.palette_outlined,
                        title: 'Appearance',
                      ),
                      _ThemeSelector(
                        mode: themeMode,
                        onChanged: (mode) => ref
                            .read(themeControllerProvider.notifier)
                            .setMode(mode),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: _notificationsEnabled,
                        onChanged: _loadingNotifications
                            ? null
                            : _setNotifications,
                        activeThumbColor: AppColors.primary,
                        title: const Text(
                          'Push notifications',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Attendance, tasks and notice alerts',
                          style: TextStyle(
                            fontSize: 10,
                            color: context.textSecondary,
                          ),
                        ),
                        secondary: Icon(
                          _notificationsEnabled
                              ? Icons.notifications_active_outlined
                              : Icons.notifications_off_outlined,
                          size: 19,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _SettingsSectionTitle(
                        icon: Icons.security_outlined,
                        title: 'Security',
                      ),
                      ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.lock_outline_rounded,
                          size: 19,
                          color: context.textSecondary,
                        ),
                        title: const Text(
                          'Change password',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Update your account password',
                          style: TextStyle(
                            fontSize: 10,
                            color: context.textSecondary,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          size: 19,
                          color: context.textSecondary,
                        ),
                        onTap: _openChangePassword,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.info_outline_rounded,
                          size: 19,
                          color: context.textSecondary,
                        ),
                        title: Text(
                          'About SpeedCode ERP',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          'Version ${AppConfig.appVersion} • ${AppConfig.useMockData ? 'Demo data' : 'Live API'}',
                          style: TextStyle(
                            fontSize: 10,
                            color: context.textSecondary,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          size: 19,
                          color: context.textSecondary,
                        ),
                        onTap: () => _showAbout(context),
                      ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                AppPrimaryButton(
                  label: 'Logout',
                  icon: Icons.logout_rounded,
                  destructive: true,
                  onPressed: () => _confirmLogout(context),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'SpeedCode Labs (Pvt) Ltd • Internal use only',
                    style: TextStyle(fontSize: 9, color: context.textSecondary),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
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

  void _showAbout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('SpeedCode Labs ERP'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Staff mobile application',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 10),
            Text(
              'Version: ${AppConfig.appVersion}\n'
              'Mode: ${AppConfig.useMockData ? 'Demo data (mock repositories)' : 'Production API'}\n'
              'API: ${AppConfig.useMockData ? 'Not connected' : AppConfig.apiBaseUrl}',
              style: TextStyle(
                fontSize: 11,
                height: 1.6,
                color: context.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Built for Android with Flutter, Riverpod and Material 3.',
              style: TextStyle(fontSize: 10.5, color: context.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _openEditProfile(Employee employee) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: _EditProfileSheet(employee: employee),
      ),
    );
  }

  void _openChangePassword() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: const _ChangePasswordSheet(),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.employee, required this.onEdit});

  final Employee employee;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              EmployeeAvatar(
                name: employee.name,
                imageUrl: employee.avatarUrl,
                size: 54,
                borderColor: AppColors.primary.withValues(alpha: 0.2),
                showStatus: true,
                isOnline: employee.workStatus == EmployeeWorkStatus.atWork,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${employee.employeeCode} • ${employee.role}',
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
                          label: employee.department,
                          color: AppColors.info,
                          compact: true,
                        ),
                        StatusBadge(
                          label: employee.workStatus.label,
                          color:
                              employee.workStatus == EmployeeWorkStatus.atWork
                              ? AppColors.success
                              : AppColors.warning,
                          compact: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 15),
              label: const Text(
                'Edit permitted details',
                style: TextStyle(fontSize: 11.5),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Name, department and designation changes are managed by HR.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 8.5, color: context.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _SettingsSectionTitle extends StatelessWidget {
  const _SettingsSectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
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
            width: 84,
            child: Text(
              label,
              style: TextStyle(fontSize: 10.5, color: context.textSecondary),
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

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.mode, required this.onChanged});

  final ThemeMode mode;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = [
      (ThemeMode.light, 'Light', Icons.light_mode_outlined),
      (ThemeMode.dark, 'Dark', Icons.dark_mode_outlined),
      (ThemeMode.system, 'System', Icons.brightness_auto_outlined),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      child: Row(
        children: options.map((option) {
          final active = mode == option.$1;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: InkWell(
                onTap: () => onChanged(option.$1),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : context.canvas,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: active
                          ? AppColors.primary.withValues(alpha: 0.5)
                          : context.line,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        option.$3,
                        size: 18,
                        color: active
                            ? AppColors.primary
                            : context.textSecondary,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        option.$2,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: active
                              ? AppColors.primary
                              : context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet({required this.employee});

  final Employee employee;

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _locationController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.employee.name);
    _phoneController = TextEditingController(text: widget.employee.phone);
    _locationController = TextEditingController(
      text: widget.employee.location ?? '',
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .updateProfile(
            widget.employee.copyWith(
              name: _firstNameController.text.trim(),
              phone: _phoneController.text.trim(),
              location: _locationController.text.trim(),
            ),
          );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      showAppSnackBarWith(messenger, 'Profile updated.', isSuccess: true);
    } catch (_) {
      if (!mounted) return;
      showAppSnackBar(context, 'Profile could not be updated.', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit profile',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Only permitted fields can be changed from the mobile app.',
                style: TextStyle(fontSize: 10.5, color: context.textSecondary),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _firstNameController,
                label: 'Full name',
                prefixIcon: Icons.person_outline_rounded,
                textCapitalization: TextCapitalization.words,
                validator: (value) => value == null || value.trim().length < 3
                    ? 'Please enter your full name'
                    : null,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _phoneController,
                label: 'Phone number',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) => value == null || value.trim().length < 7
                    ? 'Please enter a valid phone number'
                    : null,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _locationController,
                label: 'Location',
                prefixIcon: Icons.location_on_outlined,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 10),
              _ReadOnlyField(label: 'Email', value: widget.employee.email),
              const SizedBox(height: 8),
              _ReadOnlyField(
                label: 'Department',
                value: widget.employee.department,
              ),
              const SizedBox(height: 8),
              _ReadOnlyField(
                label: 'Designation',
                value: widget.employee.designation,
              ),
              const SizedBox(height: 18),
              AppPrimaryButton(
                label: 'Save changes',
                icon: Icons.check_rounded,
                loading: _saving,
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: context.canvas,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.line),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 14,
            color: context.textSecondary,
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(fontSize: 10.5, color: context.textSecondary),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: context.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangePasswordSheet extends ConsumerStatefulWidget {
  const _ChangePasswordSheet();

  @override
  ConsumerState<_ChangePasswordSheet> createState() =>
      _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;
  bool _saving = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .changePassword(
            currentPassword: _currentController.text,
            newPassword: _newController.text,
          );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      showAppSnackBarWith(
        messenger,
        'Password changed successfully.',
        isSuccess: true,
      );
    } catch (error) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Change password',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: _obscure ? 'Show passwords' : 'Hide passwords',
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 19,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              AppTextField(
                controller: _currentController,
                label: 'Current password',
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: _obscure,
                validator: (value) => value == null || value.isEmpty
                    ? 'Enter your current password'
                    : null,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _newController,
                label: 'New password',
                prefixIcon: Icons.lock_reset_rounded,
                obscureText: _obscure,
                validator: (value) {
                  if (value == null || value.length < 8) {
                    return 'Use at least 8 characters';
                  }
                  if (value == _currentController.text) {
                    return 'New password must be different';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _confirmController,
                label: 'Confirm new password',
                prefixIcon: Icons.verified_user_outlined,
                obscureText: _obscure,
                validator: (value) => value != _newController.text
                    ? 'Passwords do not match'
                    : null,
              ),
              const SizedBox(height: 18),
              AppPrimaryButton(
                label: 'Update password',
                icon: Icons.lock_reset_rounded,
                loading: _saving,
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
