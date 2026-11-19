import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart' as dates;
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/employee_avatar.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/dashboard.dart';
import '../dashboard_controller.dart';

class NoticeBoardCard extends StatelessWidget {
  const NoticeBoardCard({
    super.key,
    required this.notices,
    required this.unreadCount,
    required this.canPost,
    required this.onReadMore,
    required this.onViewAll,
  });

  final List<Notice> notices;
  final int unreadCount;
  final bool canPost;
  final ValueChanged<Notice> onReadMore;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final ordered = [...notices]
      ..sort((a, b) => b.postedAt.compareTo(a.postedAt));
    final primary = ordered.isEmpty ? null : ordered.first;
    final count = unreadCount > 0 ? unreadCount : ordered.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: context.isDark
            ? AppColors.noticeGradientDark
            : AppColors.noticeGradient,
        borderRadius: BorderRadius.circular(AppRadii.xxl),
        border: Border.all(color: AppColors.warningBorder),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notice board',
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
                      'From admin',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (canPost)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: Tooltip(
                    message: 'Post a notice',
                    child: InkResponse(
                      onTap: () => showNoticeComposer(context),
                      radius: 18,
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: Icon(
                          Icons.add_rounded,
                          size: 20,
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              if (count > 0)
                InkWell(
                  onTap: primary == null ? null : onViewAll,
                  customBorder: const CircleBorder(),
                  child: _NoticeCountBadge(count: count),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Divider(
              height: 1,
              color: AppColors.warningBorder.withValues(
                alpha: context.isDark ? 0.45 : 0.9,
              ),
            ),
          ),
          if (primary == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xl,
              ),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(AppRadii.lg),
                border: Border.all(color: AppColors.warningBorder),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.campaign_outlined,
                    size: 28,
                    color: AppColors.warning.withValues(alpha: 0.9),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'No new announcements',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onReadMore(primary),
                borderRadius: BorderRadius.circular(AppRadii.lg),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(AppRadii.lg),
                    border: Border.all(color: AppColors.warningBorder),
                    boxShadow: AppShadows.soft,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              primary.title,
                              style: TextStyle(
                                fontSize: 20,
                                height: 1.25,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                color: context.textPrimary,
                              ),
                            ),
                          ),
                          if (!primary.isRead) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(top: 6),
                              decoration: const BoxDecoration(
                                color: AppColors.warning,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (primary.description.trim().isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          primary.description,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.65,
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          EmployeeAvatar(
                            name: primary.author,
                            imageUrl: primary.authorAvatarUrl,
                            size: 24,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              primary.author,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: context.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            dates.AppDate.relativeTime(primary.postedAt),
                            style: TextStyle(
                              fontSize: 10,
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NoticeCountBadge extends StatelessWidget {
  const _NoticeCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 34),
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.warningBorder),
      ),
      child: Text(
        count > 9 ? '9+' : '$count',
        style: const TextStyle(
          color: AppColors.warningText,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}

class NoticeTile extends StatelessWidget {
  const NoticeTile({
    super.key,
    required this.notice,
    required this.onTap,
    this.compact = true,
  });

  final Notice notice;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accent = notice.priority == NoticePriority.urgent
        ? AppColors.error
        : notice.priority == NoticePriority.important
        ? AppColors.primary
        : AppColors.info;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(compact ? 10 : 12),
          decoration: BoxDecoration(
            color: notice.isRead
                ? context.canvas
                : accent.withValues(alpha: context.isDark ? 0.1 : 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  StatusBadge(
                    label: _priorityLabel(notice.priority),
                    color: accent,
                    compact: true,
                  ),
                  if (!notice.isRead) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    dates.AppDate.relativeTime(notice.postedAt),
                    style: TextStyle(fontSize: 9, color: context.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                notice.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 12 : 13,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                notice.description,
                maxLines: compact ? 2 : 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  height: 1.4,
                  color: context.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  EmployeeAvatar(
                    name: notice.author,
                    imageUrl: notice.authorAvatarUrl,
                    size: 22,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notice.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary,
                          ),
                        ),
                        if (notice.authorSubtitle.isNotEmpty)
                          Text(
                            notice.authorSubtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 8.5,
                              color: context.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (notice.hasAttachment)
                    Tooltip(
                      message: notice.attachmentName ?? 'Attachment',
                      child: const Icon(
                        Icons.attach_file_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ),
                  const SizedBox(width: 3),
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
    );
  }
}

String _priorityLabel(NoticePriority priority) => switch (priority) {
  NoticePriority.urgent => 'Urgent',
  NoticePriority.important => 'Important',
  NoticePriority.normal => 'Normal',
};

Color _priorityColor(NoticePriority priority) => switch (priority) {
  NoticePriority.urgent => AppColors.error,
  NoticePriority.important => AppColors.warning,
  NoticePriority.normal => AppColors.info,
};

Future<void> showNoticeDetails(BuildContext context, Notice notice) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StatusBadge(
                  label: _priorityLabel(notice.priority),
                  color: _priorityColor(notice.priority),
                  compact: true,
                ),
                const Spacer(),
                Text(
                  '${dates.AppDate.shortDate(notice.postedAt)} • '
                  '${dates.AppDate.messageTime(notice.postedAt)}',
                  style: TextStyle(fontSize: 10, color: context.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              notice.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 19,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                EmployeeAvatar(
                  name: notice.author,
                  imageUrl: notice.authorAvatarUrl,
                  size: 34,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notice.author,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                        ),
                      ),
                      if (notice.authorSubtitle.isNotEmpty)
                        Text(
                          notice.authorSubtitle,
                          style: TextStyle(
                            fontSize: 9.5,
                            color: context.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              notice.description,
              style: TextStyle(
                fontSize: 13,
                height: 1.65,
                color: context.textPrimary,
              ),
            ),
            if (notice.hasAttachment) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.attach_file_rounded,
                      size: 15,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        notice.attachmentName ?? 'Attachment',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> showAllNoticesSheet(
  BuildContext context, {
  required List<Notice> notices,
  required ValueChanged<Notice> onNoticeTap,
}) {
  final ordered = [...notices]
    ..sort((a, b) => b.postedAt.compareTo(a.postedAt));
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      maxChildSize: 0.94,
      minChildSize: 0.45,
      builder: (context, controller) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Row(
              children: [
                const Text(
                  'All notices',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text(
                  '${ordered.length} notices',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ordered.isEmpty
                ? const AppEmptyState(
                    title: 'No announcements available',
                    message: 'Company notices from your team will appear here.',
                    icon: Icons.campaign_outlined,
                  )
                : ListView.separated(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: ordered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) => NoticeTile(
                      notice: ordered[index],
                      compact: false,
                      onTap: () {
                        Navigator.pop(context);
                        onNoticeTap(ordered[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    ),
  );
}

Future<void> showNoticeComposer(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: const _NoticeComposerSheet(),
    ),
  );
}

class _NoticeComposerSheet extends ConsumerStatefulWidget {
  const _NoticeComposerSheet();

  @override
  ConsumerState<_NoticeComposerSheet> createState() =>
      _NoticeComposerSheetState();
}

class _NoticeComposerSheetState extends ConsumerState<_NoticeComposerSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  NoticePriority _priority = NoticePriority.normal;
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    if (title.isEmpty || description.isEmpty) {
      showAppSnackBar(
        context,
        'Please enter a notice title and description.',
        isError: true,
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref
          .read(dashboardControllerProvider.notifier)
          .createNotice(
            title: title,
            description: description,
            priority: _priority,
          );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      showAppSnackBarWith(messenger, 'Notice posted.', isSuccess: true);
    } catch (error) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        'Notice could not be posted. Please try again.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Post a notice',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Your name, designation and department will be attached automatically.',
            style: TextStyle(fontSize: 10.5, color: context.textSecondary),
          ),
          const SizedBox(height: 14),
          AppTextField(
            controller: _titleController,
            label: 'Notice title',
            hint: 'e.g. Office closed for Poya Day',
            prefixIcon: Icons.title_rounded,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _descriptionController,
            label: 'Description',
            hint: 'Add the full announcement',
            prefixIcon: Icons.notes_outlined,
            maxLines: 5,
            minLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 12),
          AppDropdownField<NoticePriority>(
            label: 'Priority',
            value: _priority,
            icon: Icons.flag_outlined,
            items: NoticePriority.values
                .map(
                  (priority) => DropdownMenuItem(
                    value: priority,
                    child: Text(_priorityLabel(priority)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _priority = value);
            },
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded, size: 17),
            label: Text(_submitting ? 'Posting...' : 'Post notice'),
          ),
        ],
      ),
    );
  }
}
