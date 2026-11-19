import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart' as dates;
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_module_scaffold.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/employee_avatar.dart';
import '../../../core/widgets/status_badge.dart';
import '../domain/task.dart';
import 'task_controllers.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  final _commentController = TextEditingController();
  bool _updating = false;
  bool _sendingComment = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(TaskItem task, TaskStatus status) async {
    if (task.status == status) return;
    setState(() => _updating = true);
    try {
      await ref
          .read(taskDetailControllerProvider(widget.taskId).notifier)
          .updateStatus(status);
      if (!mounted) return;
      showAppSnackBar(
        context,
        'Task moved to ${status.label}',
        isSuccess: true,
      );
    } catch (_) {
      if (!mounted) return;
      showAppSnackBar(context, 'Unable to update task status.', isError: true);
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _sendComment(TaskItem task) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    setState(() => _sendingComment = true);
    try {
      await ref
          .read(taskDetailControllerProvider(widget.taskId).notifier)
          .addComment(text);
      _commentController.clear();
      if (!mounted) return;
      FocusScope.of(context).unfocus();
    } catch (_) {
      if (!mounted) return;
      showAppSnackBar(context, 'Unable to post comment.', isError: true);
    } finally {
      if (mounted) setState(() => _sendingComment = false);
    }
  }

  Future<void> _openAttachment(TaskAttachment attachment) async {
    final uri = Uri.tryParse(attachment.url);
    var opened = false;
    if (uri != null) {
      try {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        opened = false;
      }
    }
    if (!opened && mounted) {
      showAppSnackBar(
        context,
        'Attachment link is not available in demo mode.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskAsync = ref.watch(taskDetailControllerProvider(widget.taskId));
    return ErpModuleScaffold(
      body: taskAsync.when(
        loading: () => const AppLoadingIndicator(message: 'Loading task...'),
        error: (error, _) => AppErrorWidget(
          message: 'Unable to load this task.',
          onRetry: () =>
              ref.invalidate(taskDetailControllerProvider(widget.taskId)),
        ),
        data: (task) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 22),
          children: [
            AppPageTitle(
              title: 'Task details',
              subtitle: task.projectName,
              padding: const EdgeInsets.only(bottom: 12),
              onBack: () => Navigator.of(context).maybePop(),
            ),
            _TaskHeader(task: task),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.notes_rounded,
                        size: 17,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 7),
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Text(
                    task.description,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.6,
                      color: context.textPrimary,
                    ),
                  ),
                  if (task.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: task.tags
                          .map(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.07,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '#$tag',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.swap_horiz_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 7),
                      const Text(
                        'Update status',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      if (_updating)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: TaskStatus.values.map((status) {
                      final selected = task.status == status;
                      return GestureDetector(
                        onTap: _updating
                            ? null
                            : () => _updateStatus(task, status),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? status.color.withValues(alpha: 0.14)
                                : context.canvas,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected ? status.color : context.line,
                              width: selected ? 1.3 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: status.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                status.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: selected
                                      ? status.color
                                      : context.textSecondary,
                                ),
                              ),
                              if (selected) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.check_rounded,
                                  size: 13,
                                  color: status.color,
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            if (task.attachments.isNotEmpty) ...[
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.attach_file_rounded,
                          size: 17,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          'Attachments (${task.attachments.length})',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...task.attachments.map(
                      (attachment) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.09),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.description_outlined,
                            size: 17,
                            color: AppColors.info,
                          ),
                        ),
                        title: Text(
                          attachment.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: context.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          attachment.size,
                          style: TextStyle(
                            fontSize: 9.5,
                            color: context.textSecondary,
                          ),
                        ),
                        trailing: const Icon(Icons.download_rounded, size: 17),
                        onTap: () => _openAttachment(attachment),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.history_rounded,
                        size: 17,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 7),
                      const Text(
                        'Activity history',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (task.activity.isEmpty)
                    Text(
                      'No activity recorded yet.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: context.textSecondary,
                      ),
                    )
                  else
                    ...task.activity
                        .take(6)
                        .map(
                          (activity) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 3),
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: activity.actor,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: context.textPrimary,
                                          ),
                                        ),
                                        TextSpan(
                                          text: ' ${activity.message}',
                                          style: TextStyle(
                                            color: context.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                                Text(
                                  dates.AppDate.relativeTime(
                                    activity.createdAt,
                                  ),
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: context.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.forum_outlined,
                        size: 17,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'Comments (${task.comments.length})',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (task.comments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No comments yet. Start the conversation.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: context.textSecondary,
                        ),
                      ),
                    )
                  else
                    ...task.comments.map(
                      (comment) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            EmployeeAvatar(
                              name: comment.author.name,
                              imageUrl: comment.author.avatarUrl,
                              size: 30,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          comment.author.name,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: context.textPrimary,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        dates.AppDate.relativeTime(
                                          comment.createdAt,
                                        ),
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: context.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(9),
                                    decoration: BoxDecoration(
                                      color: context.canvas,
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(10),
                                        bottomLeft: Radius.circular(10),
                                        bottomRight: Radius.circular(10),
                                      ),
                                      border: Border.all(color: context.line),
                                    ),
                                    child: Text(
                                      comment.message,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        height: 1.45,
                                        color: context.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          minLines: 1,
                          maxLines: 4,
                          textCapitalization: TextCapitalization.sentences,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: context.textPrimary,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Write a comment...',
                            isDense: true,
                          ),
                          onSubmitted: (_) => _sendComment(task),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 42,
                        height: 42,
                        child: FilledButton(
                          onPressed: _sendingComment
                              ? null
                              : () => _sendComment(task),
                          style: FilledButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(42, 42),
                          ),
                          child: _sendingComment
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded, size: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskHeader extends StatelessWidget {
  const _TaskHeader({required this.task});

  final TaskItem task;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusBadge(label: task.status.label, color: task.status.color),
              const SizedBox(width: 6),
              StatusBadge(
                label: '${task.priority.label} priority',
                color: task.priority.color,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: context.canvas,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.line),
                ),
                child: Text(
                  task.id.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: context.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            task.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 19,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.folder_outlined,
                size: 13,
                color: AppColors.primary,
              ),
              const SizedBox(width: 5),
              Text(
                task.projectName,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const Divider(height: 22),
          Row(
            children: [
              EmployeeAvatar(
                name: task.assignee.name,
                imageUrl: task.assignee.avatarUrl,
                size: 32,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assigned to',
                      style: TextStyle(
                        fontSize: 9,
                        color: context.textSecondary,
                      ),
                    ),
                    Text(
                      task.assignee.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Due date',
                    style: TextStyle(fontSize: 9, color: context.textSecondary),
                  ),
                  Text(
                    dates.AppDate.shortDate(task.dueDate),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: task.isOverdue
                          ? AppColors.error
                          : context.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
