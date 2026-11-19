import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/models/employee.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/dashboard.dart';
import 'person_row.dart';

class OnLeaveCard extends StatelessWidget {
  const OnLeaveCard({super.key, required this.status, required this.onOpen});

  final EmployeeStatusSummary status;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final employees = status.employees
        .where((employee) => employee.workStatus == EmployeeWorkStatus.onLeave)
        .toList();
    final count = status.onLeave > 0 ? status.onLeave : employees.length;

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
              Expanded(
                child: Text(
                  'On leave',
                  style: TextStyle(
                    fontSize: 20,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: context.textPrimary,
                  ),
                ),
              ),
              CountBadge(
                count: count,
                color: AppColors.warningLight,
                textColor: AppColors.warningText,
                borderColor: AppColors.warningBorder,
                height: 32,
                fontSize: 12,
              ),
              const SizedBox(width: AppSpacing.sm),
              TextButton(
                onPressed: onOpen,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Open'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (employees.isEmpty)
            Text(
              'No one is on leave today.',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: context.textSecondary,
              ),
            )
          else
            ...employees.map(
              (employee) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: PersonRow(employee: employee),
              ),
            ),
        ],
      ),
    );
  }
}
