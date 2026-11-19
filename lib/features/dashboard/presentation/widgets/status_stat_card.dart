import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class StatusStatCard extends StatelessWidget {
  const StatusStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: context.line),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: context.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 32,
              height: 1,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              color: context.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
