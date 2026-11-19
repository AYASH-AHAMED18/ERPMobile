import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_sizes.dart';
import '../../../../core/models/employee.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../../core/widgets/employee_avatar.dart';
import '../../../../core/widgets/status_badge.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.employee,
    required this.unreadNotifications,
    required this.isDark,
    required this.onOpenMenu,
    required this.onScanQr,
    required this.onNotifications,
    required this.onToggleTheme,
    required this.onProfile,
  });

  final Employee? employee;
  final int unreadNotifications;
  final bool isDark;
  final VoidCallback onOpenMenu;
  final VoidCallback onScanQr;
  final VoidCallback onNotifications;
  final VoidCallback onToggleTheme;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 370;
        final avatarSize = compact
            ? AppSizes.profileAvatarCompact
            : AppSizes.profileAvatar;
        final iconColor = context.isDark
            ? AppColors.darkSecondaryText
            : AppColors.slate600;

        return Container(
          height: AppSizes.appBarHeight,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            color: context.surface,
            border: Border(bottom: BorderSide(color: context.line)),
            boxShadow: AppShadows.soft,
          ),
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Tooltip(
                    message: 'Open app menu',
                    child: InkWell(
                      onTap: onOpenMenu,
                      borderRadius: BorderRadius.circular(AppRadii.xs),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: BrandLogo(size: 28, plain: true),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(width: 1, height: AppSizes.headerDividerHeight, color: context.line),
              const SizedBox(width: AppSpacing.sm),
              _HeaderAction(
                icon: Icons.qr_code_scanner_rounded,
                label: 'Scan QR code',
                color: iconColor,
                size: compact
                    ? AppSizes.headerAction - 2
                    : AppSizes.headerAction,
                onTap: onScanQr,
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _HeaderAction(
                    icon: Icons.notifications_none_rounded,
                    label: 'Notifications',
                    color: iconColor,
                    size: compact
                        ? AppSizes.headerAction - 2
                        : AppSizes.headerAction,
                    onTap: onNotifications,
                  ),
                  if (unreadNotifications > 0)
                    Positioned(
                      right: -3,
                      top: -4,
                      child: CountBadge(
                        count: unreadNotifications,
                        color: AppColors.notificationBadge,
                        cap: 9,
                        height: 18,
                        fontSize: 9,
                      ),
                    ),
                ],
              ),
              _HeaderAction(
                icon: isDark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                label: isDark ? 'Switch to light mode' : 'Switch to dark mode',
                color: iconColor,
                size: compact
                    ? AppSizes.headerAction - 2
                    : AppSizes.headerAction,
                onTap: onToggleTheme,
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(width: 1, height: AppSizes.headerDividerHeight, color: context.line),
              const SizedBox(width: AppSpacing.sm),
              Tooltip(
                message: 'Open employee profile',
                child: InkWell(
                  onTap: onProfile,
                  customBorder: const CircleBorder(),
                  child: EmployeeAvatar(
                    name: employee?.name ?? 'Employee',
                    imageUrl: employee?.avatarUrl,
                    size: avatarSize,
                    borderColor: AppColors.primary.withValues(alpha: 0.28),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.size,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkResponse(
        onTap: onTap,
        radius: size / 2,
        containedInkWell: true,
        highlightShape: BoxShape.circle,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: size * 0.58, color: color),
        ),
      ),
    );
  }
}
