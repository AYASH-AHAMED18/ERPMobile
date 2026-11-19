import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.tonal = false,
    this.destructive = false,
    this.expanded = true,
    this.height = 46,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final bool tonal;
  final bool destructive;
  final bool expanded;
  final double height;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = destructive
        ? AppColors.error
        : tonal
        ? AppColors.primary.withValues(alpha: 0.09)
        : AppColors.primary;
    final foregroundColor = destructive || !tonal
        ? Colors.white
        : AppColors.primary;

    final child = AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: loading
          ? SizedBox(
              key: const ValueKey('loading'),
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: foregroundColor,
              ),
            )
          : Row(
              key: const ValueKey('label'),
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 17, color: foregroundColor),
                  const SizedBox(width: 7),
                ],
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      color: foregroundColor,
                    ),
                  ),
                ),
              ],
            ),
    );

    final button = SizedBox(
      height: height,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: backgroundColor.withValues(alpha: 0.55),
          disabledForegroundColor: foregroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: child,
      ),
    );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}
