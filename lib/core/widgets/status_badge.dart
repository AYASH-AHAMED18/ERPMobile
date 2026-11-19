import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.compact = false,
    this.filled = false,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final bool compact;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: filled ? color : color.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: compact ? 10 : 12,
              color: filled ? Colors.white : color,
            ),
            const SizedBox(width: 4),
          ] else
            Container(
              width: compact ? 5 : 6,
              height: compact ? 5 : 6,
              decoration: BoxDecoration(
                color: filled ? Colors.white : color,
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 10 : 11.5,
              fontWeight: FontWeight.w600,
              color: filled ? Colors.white : color,
            ),
          ),
        ],
      ),
    );
  }
}

class CountBadge extends StatelessWidget {
  const CountBadge({
    super.key,
    required this.count,
    this.color,
    this.cap = 99,
    this.height = 18,
    this.fontSize = 9.5,
    this.textColor,
    this.borderColor,
    this.borderWidth = 1.5,
  });

  final int count;
  final Color? color;
  final int cap;
  final double height;
  final double fontSize;
  final Color? textColor;
  final Color? borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final bg = color ?? AppColors.error;
    return Container(
      constraints: BoxConstraints(minWidth: height),
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(
          color: borderColor ?? context.surface,
          width: borderWidth,
        ),
      ),
      child: Text(
        count > cap ? '$cap+' : '$count',
        style: TextStyle(
          color: textColor ?? Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}
