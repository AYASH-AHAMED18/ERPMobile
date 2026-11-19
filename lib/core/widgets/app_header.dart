import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../models/employee.dart';
import 'brand_logo.dart';
import 'employee_avatar.dart';
import 'status_badge.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({
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
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: context.surface,
        border: Border(bottom: BorderSide(color: context.line)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.isDark ? 0.22 : 0.035,
            ),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
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
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
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
          _HeaderAction(
            icon: Icons.qr_code_scanner_rounded,
            label: 'Scan QR code',
            onTap: onScanQr,
          ),
          const SizedBox(width: 2),
          Stack(
            clipBehavior: Clip.none,
            children: [
              _HeaderAction(
                icon: Icons.notifications_none_rounded,
                label: 'Notifications',
                onTap: onNotifications,
              ),
              if (unreadNotifications > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: CountBadge(
                    count: unreadNotifications,
                    cap: 9,
                    height: 17,
                    fontSize: 9,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 2),
          _HeaderAction(
            icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            label: isDark ? 'Switch to light mode' : 'Switch to dark mode',
            onTap: onToggleTheme,
          ),
          const SizedBox(width: 6),
          Container(width: 1, height: 22, color: context.line),
          const SizedBox(width: 6),
          Tooltip(
            message: 'Open employee profile',
            child: InkWell(
              onTap: onProfile,
              customBorder: const CircleBorder(),
              child: EmployeeAvatar(
                name: employee?.name ?? 'Employee',
                imageUrl: employee?.avatarUrl,
                size: 32,
                borderColor: AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkResponse(
        onTap: onTap,
        radius: 20,
        containedInkWell: true,
        highlightShape: BoxShape.circle,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 21, color: context.textPrimary),
        ),
      ),
    );
  }
}
