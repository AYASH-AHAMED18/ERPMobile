import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class AttendanceChip extends StatelessWidget {
  const AttendanceChip({
    super.key,
    required this.label,
    this.fillColor,
    this.borderColor,
    this.textColor,
    this.icon,
  });

  final String label;
  final Color? fillColor;
  final Color? borderColor;
  final Color? textColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final foreground = textColor ?? context.textPrimary;
    final border = borderColor ?? context.line;

    return Container(
      constraints: const BoxConstraints(minHeight: 36),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: fillColor ?? Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11.5,
              height: 1.1,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}
