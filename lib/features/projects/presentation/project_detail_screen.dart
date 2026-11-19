import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart' as dates;
import '../../../core/widgets/app_module_scaffold.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/employee_avatar.dart';
import '../../../core/widgets/status_badge.dart';
import '../../tasks/domain/task.dart';
import '../../tasks/presentation/task_controllers.dart';
import '../domain/project.dart';
import 'projects_controller.dart';

enum _TaskFilter {
  all('All tasks'),
  todo('To Do'),
  inProgress('In Progress'),
  review('Under Review'),
  completed('Completed'),
  blocked('Blocked');

  const _TaskFilter(this.label);
  final String label;

  bool matches(TaskItem task) => switch (this) {
    _TaskFilter.all => true,
    _TaskFilter.todo =>
      task.status == TaskStatus.todo || task.status == TaskStatus.backlog,
    _TaskFilter.inProgress => task.status == TaskStatus.inProgress,
    _TaskFilter.review => task.status == TaskStatus.review,
    _TaskFilter.completed => task.status == TaskStatus.done,
    _TaskFilter.blocked => task.status == TaskStatus.blocked,
  };
}

class ProjectDetailScreen extends ConsumerStatefulWidget {
  const ProjectDetailScreen({super.key, required this.projectId});

  final String projectId;

  @override
  ConsumerState<ProjectDetailScreen> createState() =>
      _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  _TaskFilter _filter = _TaskFilter.all;

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsControllerProvider);
    Project? project;
    for (final item in projects.value ?? const <Project>[]) {
      if (item.id == widget.projectId) {
        project = item;
        break;
      }
    }
    return ErpModuleScaffold(
      body: projects.when(
        loading: () => const AppLoadingIndicator(message: 'Loading project...'),
        error: (error, _) => AppErrorWidget(
          message: 'This project could not be loaded.',
          onRetry: () =>
              ref.read(projectsControllerProvider.notifier).refresh(),
        ),
        data: (_) {
          if (project == null) {
            return Column(
              children: [
                AppPageTitle(
                  title: 'Project details',
                  subtitle: 'Project not found',
                  onBack: () => context.pop(),
                ),
                const Expanded(
                  child: AppEmptyState(
                    title: 'Project not found',
                    message: 'This project may no longer be assigned to you.',
                    icon: Icons.folder_off_outlined,
                  ),
                ),
              ],
            );
          }
          final tasks = project.tasks.where(_filter.matches).toList();
          tasks.sort((a, b) {
            if (a.status == TaskStatus.done && b.status != TaskStatus.done) {
              return 1;
            }
            if (b.status == TaskStatus.done && a.status != TaskStatus.done) {
              return -1;
            }
            return a.dueDate.compareTo(b.dueDate);
          });
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(projectsControllerProvider.notifier).refresh(),
            color: AppColors.primary,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 26),
              children: [
                AppPageTitle(
                  title: 'Project details',
                  subtitle: project.code,
                  onBack: () => context.pop(),
                  trailing: IconButton(
                    tooltip: 'Refresh project',
                    onPressed: () =>
                        ref.read(projectsControllerProvider.notifier).refresh(),
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _ProjectSummary(project: project),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _DetailMetric(
                          label: 'Tasks',
                          value: '${project.totalTasks}',
                          color: AppColors.info,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _DetailMetric(
                          label: 'Completed',
                          value: '${project.completedTasks}',
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _DetailMetric(
                          label: 'Pending',
                          value: '${project.pendingTasks}',
                          color: AppColors.warning,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _DetailMetric(
                          label: 'Blocked',
                          value: '${project.blockedTasks}',
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ModuleSectionTitle(
                    title: 'My tasks',
                    subtitle:
                        '${tasks.length} task${tasks.length == 1 ? '' : 's'} shown',
                    trailing: TextButton(
                      onPressed: () {
                        ref
                            .read(taskBoardControllerProvider.notifier)
                            .refresh();
                        context.go('/more/tasks');
                      },
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 28),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                      ),
                      child: const Text(
                        'Task board',
                        style: TextStyle(fontSize: 10.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: ModuleFilterRow(
                    children: [
                      for (final filter in _TaskFilter.values)
                        AppFilterChip(
                          label: filter.label,
                          count: project.tasks.where(filter.matches).length,
                          selected: _filter == filter,
                          onSelected: (_) => setState(() => _filter = filter),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (tasks.isEmpty)
                  const AppEmptyState(
                    title: 'No tasks in this view',
                    message: 'Try a different status filter.',
                    icon: Icons.assignment_outlined,
                    compact: true,
                  )
                else
                  ...tasks.map(
                    (task) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: _ProjectTaskCard(
                        task: task,
                        onTap: () async {
                          await context.push('/tasks/${task.id}');
                          await ref
                              .read(projectsControllerProvider.notifier)
                              .refresh();
                          await ref
                              .read(taskBoardControllerProvider.notifier)
                              .refresh();
                        },
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProjectSummary extends StatelessWidget {
  const _ProjectSummary({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final progressColor = project.status == ProjectStatus.completed
        ? AppColors.success
        : project.isDelayed
        ? AppColors.warning
        : AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusBadge(
                label: project.status.label,
                color: project.status.color,
              ),
              const SizedBox(width: 6),
              StatusBadge(
                label: '${project.priority.label} priority',
                color: project.priority.color,
              ),
              const Spacer(),
              if (project.isDelayed)
                const StatusBadge(
                  label: 'Delayed',
                  color: AppColors.error,
                  compact: true,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            project.name,
            style: const TextStyle(
              fontSize: 20,
              height: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            project.description,
            style: TextStyle(
              fontSize: 11,
              height: 1.5,
              color: context.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              EmployeeAvatar(name: project.manager, size: 34),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Project manager',
                      style: TextStyle(
                        fontSize: 9,
                        color: context.textSecondary,
                      ),
                    ),
                    Text(
                      project.manager,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              EmployeeAvatarGroup(
                names: project.team.map((member) => member.name).toList(),
                size: 28,
                max: 3,
              ),
            ],
          ),
          const Divider(height: 22),
          Row(
            children: [
              Expanded(
                child: _DateBlock(
                  label: 'Start date',
                  value: project.startDate == null
                      ? 'Not available'
                      : dates.AppDate.shortDate(project.startDate!),
                  icon: Icons.play_circle_outline_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DateBlock(
                  label: 'Deadline',
                  value: dates.AppDate.shortDate(project.deadline),
                  icon: Icons.flag_outlined,
                  color: project.isDelayed ? AppColors.error : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Overall progress',
                style: TextStyle(fontSize: 10, color: context.textSecondary),
              ),
              const Spacer(),
              Text(
                '${(project.progress * 100).round()}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: progressColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: project.progress,
              minHeight: 7,
              backgroundColor: context.line,
              valueColor: AlwaysStoppedAnimation(progressColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateBlock extends StatelessWidget {
  const _DateBlock({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? context.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: context.canvas,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.line),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 8.5, color: context.textSecondary),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: color ?? context.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailMetric extends StatelessWidget {
  const _DetailMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              height: 1,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
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

class _ProjectTaskCard extends StatelessWidget {
  const _ProjectTaskCard({required this.task, required this.onTap});

  final TaskItem task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final deadlineColor = task.status == TaskStatus.done
        ? AppColors.success
        : task.isOverdue
        ? AppColors.error
        : dates.AppDate.isSameDay(task.dueDate, DateTime.now())
        ? AppColors.warning
        : context.textSecondary;
    final deadlineLabel = task.status == TaskStatus.done
        ? 'Completed'
        : dates.AppDate.isSameDay(task.dueDate, DateTime.now())
        ? 'Due today'
        : task.isOverdue
        ? 'Overdue'
        : dates.AppDate.shortDate(task.dueDate);
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusBadge(
                      label: task.status.label,
                      color: task.status.color,
                      compact: true,
                    ),
                    const SizedBox(width: 5),
                    StatusBadge(
                      label: task.priority.label,
                      color: task.priority.color,
                      compact: true,
                    ),
                    const Spacer(),
                    StatusBadge(
                      label: deadlineLabel,
                      color: deadlineColor,
                      compact: true,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  task.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    task.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.4,
                      color: context.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    EmployeeAvatar(
                      name: task.assignee.name,
                      imageUrl: task.assignee.avatarUrl,
                      size: 22,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        task.assignee.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9.5,
                          color: context.textSecondary,
                        ),
                      ),
                    ),
                    if (task.comments.isNotEmpty) ...[
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 11,
                        color: context.textSecondary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${task.comments.length}',
                        style: TextStyle(
                          fontSize: 8.5,
                          color: context.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 7),
                    ],
                    if (task.attachments.isNotEmpty) ...[
                      Icon(
                        Icons.attach_file_rounded,
                        size: 11,
                        color: context.textSecondary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${task.attachments.length}',
                        style: TextStyle(
                          fontSize: 8.5,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(width: 5),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: context.textSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
