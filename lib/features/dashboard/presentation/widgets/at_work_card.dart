import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/dashboard.dart';
import 'person_row.dart';

class AtWorkCard extends StatelessWidget {
  const AtWorkCard({super.key, required this.status});

  final EmployeeStatusSummary status;

  @override
  Widget build(BuildContext context) {
    final employees = status.workingEmployees;
    final count = status.atWork > 0 ? status.atWork : employees.length;
    final visibleRows = employees.isEmpty
        ? 1
        : math.min(4.5, employees.length.toDouble());
    final listHeight = employees.isEmpty
        ? 84.0
        : visibleRows * AppSizes.listRow +
              math.max(0, visibleRows.ceil() - 1) * AppSpacing.md;

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
                  'At work',
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
                color: AppColors.successLight,
                textColor: AppColors.success,
                borderColor: AppColors.successBorder,
                height: 32,
                fontSize: 12,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: listHeight,
            child: employees.isEmpty
                ? Center(
                    child: Text(
                      'No one is at work right now.',
                      style: TextStyle(
                        fontSize: 13,
                        color: context.textSecondary,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    physics: const ClampingScrollPhysics(),
                    itemCount: employees.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) =>
                        PersonRow(employee: employees[index]),
                  ),
          ),
        ],
      ),
    );
  }
}
