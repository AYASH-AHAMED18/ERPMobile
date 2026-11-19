import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../tasks/domain/task.dart';
import 'segmented_progress_bar.dart';

class ProjectProgressRow extends StatelessWidget {
  const ProjectProgressRow({super.key, required this.project});

  final TeamProgress project;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                project.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '${project.totalTasks}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SegmentedProgressBar(
          height: AppSizes.projectProgressHeight,
          segments: [
            ProgressSegment(
              label: 'To do',
              color: AppColors.statusTodo,
              value: project.pending,
            ),
            ProgressSegment(
              label: 'In progress',
              color: AppColors.statusInProgress,
              value: project.inProgress,
            ),
            ProgressSegment(
              label: 'Done',
              color: AppColors.statusDone,
              value: project.completed,
            ),
          ],
        ),
      ],
    );
  }
}
