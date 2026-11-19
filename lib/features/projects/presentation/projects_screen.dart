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
import '../domain/project.dart';
import 'projects_controller.dart';

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  ProjectStatus? _status;

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsControllerProvider);
    return ErpModuleScaffold(
      body: projects.when(
        loading: () =>
            const AppLoadingIndicator(message: 'Loading projects...'),
        error: (error, _) => AppErrorWidget(
          message: 'Your projects could not be loaded.',
          onRetry: () =>
              ref.read(projectsControllerProvider.notifier).refresh(),
        ),
        data: (allProjects) {
          final visible = _status == null
              ? allProjects
              : allProjects
                    .where((project) => project.status == _status)
                    .toList();
          final pendingTasks = allProjects.fold<int>(
            0,
            (sum, project) => sum + project.pendingTasks,
          );
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(projectsControllerProvider.notifier).refresh(),
            color: AppColors.primary,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                const AppPageTitle(
                  title: 'My Projects',
                  subtitle: 'Projects assigned to you and their task progress',
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ProjectMetric(
                          label: 'Projects',
                          value: '${allProjects.length}',
                          icon: Icons.folder_copy_outlined,
                          color: AppColors.info,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ProjectMetric(
                          label: 'Active',
                          value:
                              '${allProjects.where((p) => p.status == ProjectStatus.active).length}',
                          icon: Icons.play_circle_outline_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ProjectMetric(
                          label: 'Completed',
                          value:
                              '${allProjects.where((p) => p.status == ProjectStatus.completed).length}',
                          icon: Icons.check_circle_outline_rounded,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ProjectMetric(
                          label: 'Pending',
                          value: '$pendingTasks',
                          icon: Icons.pending_actions_outlined,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: ModuleFilterRow(
                    children: [
                      AppFilterChip(
                        label: 'All projects',
                        count: allProjects.length,
                        selected: _status == null,
                        onSelected: (_) => setState(() => _status = null),
                      ),
                      ...ProjectStatus.values.map(
                        (status) => AppFilterChip(
                          label: status.label,
                          color: status.color,
                          count: allProjects
                              .where((project) => project.status == status)
                              .length,
                          selected: _status == status,
                          onSelected: (_) => setState(
                            () => _status = _status == status ? null : status,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ModuleSectionTitle(
                    title: 'Project portfolio',
                    subtitle:
                        '${visible.length} project${visible.length == 1 ? '' : 's'} shown',
                  ),
                ),
                const SizedBox(height: 8),
                if (visible.isEmpty)
                  const AppEmptyState(
                    title: 'No projects found',
                    message:
                        'Projects linked to your assigned tasks will appear here.',
                    icon: Icons.folder_off_outlined,
                  )
                else
                  ...visible.map(
                    (project) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: _ProjectCard(
                        project: project,
                        onTap: () =>
                            context.push('/more/projects/${project.id}'),
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

class _ProjectMetric extends StatelessWidget {
  const _ProjectMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: context.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
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
            style: TextStyle(fontSize: 8.5, color: context.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project, required this.onTap});

  final Project project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progressColor = project.status == ProjectStatus.completed
        ? AppColors.success
        : project.isDelayed
        ? AppColors.warning
        : AppColors.primary;
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: context.canvas,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: context.line),
                      ),
                      child: Text(
                        project.code,
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: context.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    StatusBadge(
                      label: project.priority.label,
                      color: project.priority.color,
                      compact: true,
                    ),
                    const Spacer(),
                    StatusBadge(
                      label: project.status.label,
                      color: project.status.color,
                      compact: true,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  project.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  project.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.4,
                    color: context.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    EmployeeAvatar(name: project.manager, size: 24),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        project.manager,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '${project.completedTasks}/${project.totalTasks} tasks',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      'Progress',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: context.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(project.progress * 100).round()}%',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
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
                    minHeight: 6,
                    backgroundColor: context.line,
                    valueColor: AlwaysStoppedAnimation(progressColor),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 11,
                      color: project.isDelayed
                          ? AppColors.error
                          : context.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dates.AppDate.shortDate(project.deadline),
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: project.isDelayed
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: project.isDelayed
                            ? AppColors.error
                            : context.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (project.isDelayed)
                      const StatusBadge(
                        label: 'Delayed',
                        color: AppColors.error,
                        compact: true,
                      ),
                    const Spacer(),
                    EmployeeAvatarGroup(
                      names: project.team.map((member) => member.name).toList(),
                      size: 24,
                      max: 3,
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
