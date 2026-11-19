import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart' as dates;
import '../../../../core/widgets/employee_avatar.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/task.dart';

class TaskListCard extends StatelessWidget {
  const TaskListCard({
    super.key,
    required this.task,
    required this.onTap,
    this.showAssignee = true,
  });

  final TaskItem task;
  final VoidCallback onTap;
  final bool showAssignee;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: task.status.color),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(11),
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
                            const SizedBox(width: 6),
                            StatusBadge(
                              label: task.priority.label,
                              color: task.priority.color,
                              compact: true,
                            ),
                            const Spacer(),
                            if (task.isOverdue)
                              const StatusBadge(
                                label: 'Overdue',
                                color: AppColors.error,
                                compact: true,
                              ),
                          ],
                        ),
                        const SizedBox(height: 9),
                        Text(
                          task.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          task.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            height: 1.45,
                            color: context.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Row(
                          children: [
                            Icon(
                              Icons.folder_outlined,
                              size: 12,
                              color: context.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                task.projectName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: context.textSecondary,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 11,
                              color: task.isOverdue
                                  ? AppColors.error
                                  : context.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dates.AppDate.shortDate(task.dueDate),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: task.isOverdue
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: task.isOverdue
                                    ? AppColors.error
                                    : context.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        if (showAssignee) ...[
                          const SizedBox(height: 9),
                          Row(
                            children: [
                              EmployeeAvatar(
                                name: task.assignee.name,
                                imageUrl: task.assignee.avatarUrl,
                                size: 24,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  task.assignee.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: context.textPrimary,
                                  ),
                                ),
                              ),
                              if (task.comments.isNotEmpty) ...[
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 12,
                                  color: context.textSecondary,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${task.comments.length}',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    color: context.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              if (task.attachments.isNotEmpty) ...[
                                Icon(
                                  Icons.attach_file_rounded,
                                  size: 12,
                                  color: context.textSecondary,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${task.attachments.length}',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    color: context.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TaskKanbanCard extends StatelessWidget {
  const TaskKanbanCard({super.key, required this.task, required this.onTap});

  final TaskItem task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: context.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StatusBadge(
                  label: task.priority.label,
                  color: task.priority.color,
                  compact: true,
                ),
                const Spacer(),
                if (task.isOverdue)
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 14,
                    color: AppColors.error,
                  ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              task.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.3,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              task.projectName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 9.5, color: context.textSecondary),
            ),
            const SizedBox(height: 9),
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
                    task.assignee.name.split(' ').first,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9.5,
                      color: context.textSecondary,
                    ),
                  ),
                ),
                Text(
                  dates.AppDate.shortDate(task.dueDate),
                  style: TextStyle(
                    fontSize: 8.5,
                    color: task.isOverdue
                        ? AppColors.error
                        : context.textSecondary,
                    fontWeight: task.isOverdue
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
