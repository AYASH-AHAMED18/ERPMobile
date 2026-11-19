import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../tasks/domain/task.dart';
import 'project_progress_row.dart';
import 'segmented_progress_bar.dart';
import 'status_stat_card.dart';

class ProjectTaskStatusCard extends StatelessWidget {
  const ProjectTaskStatusCard({
    super.key,
    required this.stats,
    required this.projects,
    required this.onOpenBoard,
  });

  final TaskStats stats;
  final List<TeamProgress> projects;
  final VoidCallback onOpenBoard;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Project task status',
                    style: TextStyle(
                      fontSize: 20,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${stats.total} tasks on your active projects',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onOpenBoard,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('Open board'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SegmentedProgressBar(
          segments: [
            if (stats.backlog > 0)
              ProgressSegment(
                label: 'Backlog',
                color: AppColors.statusBacklog,
                value: stats.backlog,
              ),
            ProgressSegment(
              label: 'To do',
              color: AppColors.statusTodo,
              value: stats.todo,
            ),
            ProgressSegment(
              label: 'In progress',
              color: AppColors.statusInProgress,
              value: stats.inProgress,
            ),
            ProgressSegment(
              label: 'Review',
              color: AppColors.statusReview,
              value: stats.review,
            ),
            ProgressSegment(
              label: 'Done',
              color: AppColors.statusDone,
              value: stats.done,
            ),
            if (stats.blocked > 0)
              ProgressSegment(
                label: 'Blocked',
                color: AppColors.statusBlocked,
                value: stats.blocked,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        StatusStatCard(
          label: 'Backlog',
          value: stats.backlog,
          color: AppColors.statusBacklog,
        ),
        const SizedBox(height: AppSpacing.lg),
        StatusStatCard(
          label: 'To do',
          value: stats.todo,
          color: AppColors.statusTodo,
        ),
        const SizedBox(height: AppSpacing.lg),
        StatusStatCard(
          label: 'In progress',
          value: stats.inProgress,
          color: AppColors.statusInProgress,
        ),
        const SizedBox(height: AppSpacing.lg),
        StatusStatCard(
          label: 'Review',
          value: stats.review,
          color: AppColors.statusReview,
        ),
        const SizedBox(height: AppSpacing.lg),
        StatusStatCard(
          label: 'Done',
          value: stats.done,
          color: AppColors.statusDone,
        ),
        if (stats.blocked > 0) ...[
          const SizedBox(height: AppSpacing.lg),
          StatusStatCard(
            label: 'Blocked',
            value: stats.blocked,
            color: AppColors.statusBlocked,
          ),
        ],
        if (projects.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          for (var index = 0; index < projects.length; index++) ...[
            ProjectProgressRow(project: projects[index]),
            if (index != projects.length - 1)
              const SizedBox(height: AppSpacing.lg),
          ],
        ],
      ],
    );
  }
}
