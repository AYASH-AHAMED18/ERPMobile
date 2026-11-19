import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart' as dates;
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../authentication/presentation/auth_controller.dart';
import '../../../tasks/domain/task.dart';
import '../../../tasks/presentation/task_controllers.dart';

class MyTasksCard extends ConsumerWidget {
  const MyTasksCard({super.key, this.onViewTasks, this.onTaskTap});

  final VoidCallback? onViewTasks;
  final ValueChanged<TaskItem>? onTaskTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(taskBoardControllerProvider);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.isDark ? 0.18 : 0.025,
            ),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.checklist_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Tasks',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      tasksAsync.maybeWhen(
                        data: (tasks) =>
                            '${_myTasks(ref, tasks).length} assigned to you',
                        orElse: () => 'Loading your assigned work',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onViewTasks,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: const Size(0, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('View All', style: TextStyle(fontSize: 11.5)),
                    const SizedBox(width: 1),
                    const Icon(Icons.chevron_right_rounded, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          tasksAsync.when(
            loading: () => const SizedBox(
              height: 150,
              child: AppLoadingIndicator(message: 'Loading tasks...'),
            ),
            error: (error, _) => SizedBox(
              height: 150,
              child: AppErrorWidget(
                message: 'Unable to load your tasks.',
                compact: true,
                onRetry: () =>
                    ref.read(taskBoardControllerProvider.notifier).refresh(),
              ),
            ),
            data: (tasks) {
              final myTasks = _myTasks(ref, tasks);
              if (myTasks.isEmpty) {
                return const AppEmptyState(
                  title: 'No tasks assigned',
                  message: 'Tasks assigned to you will appear here.',
                  icon: Icons.task_alt_rounded,
                  compact: true,
                );
              }
              final stats = _TaskSummary.from(myTasks);
              final visible = [...myTasks]
                ..sort((a, b) {
                  if (a.isOverdue != b.isOverdue) return a.isOverdue ? -1 : 1;
                  return a.dueDate.compareTo(b.dueDate);
                });
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryTile(
                          label: 'Pending',
                          value: stats.pending,
                          color: AppColors.info,
                          icon: Icons.pending_actions_outlined,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _SummaryTile(
                          label: 'In Progress',
                          value: stats.inProgress,
                          color: AppColors.warning,
                          icon: Icons.autorenew_rounded,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _SummaryTile(
                          label: 'Completed',
                          value: stats.completed,
                          color: AppColors.success,
                          icon: Icons.task_alt_rounded,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _SummaryTile(
                          label: 'Overdue',
                          value: stats.overdue,
                          color: AppColors.error,
                          icon: Icons.warning_amber_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...visible
                      .take(3)
                      .map(
                        (task) => Padding(
                          padding: const EdgeInsets.only(bottom: 7),
                          child: _TaskRow(
                            task: task,
                            onTap: onTaskTap == null
                                ? null
                                : () => onTaskTap!(task),
                          ),
                        ),
                      ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  List<TaskItem> _myTasks(WidgetRef ref, List<TaskItem> tasks) {
    final me = ref.watch(currentEmployeeProvider);
    return tasks
        .where(
          (task) =>
              task.assignedToMe || (me != null && task.assignee.id == me.id),
        )
        .toList();
  }
}

class _TaskSummary {
  const _TaskSummary({
    required this.pending,
    required this.inProgress,
    required this.completed,
    required this.overdue,
  });

  final int pending;
  final int inProgress;
  final int completed;
  final int overdue;

  factory _TaskSummary.from(List<TaskItem> tasks) {
    return _TaskSummary(
      pending: tasks
          .where(
            (task) =>
                task.status == TaskStatus.backlog ||
                task.status == TaskStatus.todo,
          )
          .length,
      inProgress: tasks
          .where(
            (task) =>
                task.status == TaskStatus.inProgress ||
                task.status == TaskStatus.review,
          )
          .length,
      completed: tasks.where((task) => task.status == TaskStatus.done).length,
      overdue: tasks.where((task) => task.isOverdue).length,
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final int value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: context.isDark ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(height: 3),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 15,
              height: 1,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: context.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task, this.onTap});

  final TaskItem task;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final overdue = task.isOverdue;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
          decoration: BoxDecoration(
            color: overdue
                ? AppColors.error.withValues(alpha: context.isDark ? 0.1 : 0.04)
                : context.canvas,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: overdue
                  ? AppColors.error.withValues(alpha: 0.22)
                  : context.line,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: task.priority.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  StatusBadge(
                    label: task.status.label,
                    color: task.status.color,
                    compact: true,
                  ),
                ],
              ),
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  task.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 9.5, color: context.textSecondary),
                ),
              ],
              if (task.progress != null) ...[
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: task.progress,
                    minHeight: 4,
                    backgroundColor: context.line,
                    valueColor: AlwaysStoppedAnimation(task.priority.color),
                  ),
                ),
              ],
              const SizedBox(height: 5),
              Row(
                children: [
                  Icon(
                    overdue
                        ? Icons.error_outline_rounded
                        : Icons.event_outlined,
                    size: 11,
                    color: overdue ? AppColors.error : context.textSecondary,
                  ),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      'Due ${dates.AppDate.shortDate(task.dueDate)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: overdue ? FontWeight.w700 : FontWeight.w500,
                        color: overdue
                            ? AppColors.error
                            : context.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(
                    label: task.priority.label,
                    color: task.priority.color,
                    compact: true,
                  ),
                  if (task.assignedBy != null &&
                      task.assignedBy!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'By ${task.assignedBy}',
                        maxLines: 1,
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 8,
                          color: context.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
