import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart' as dates;
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_module_scaffold.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/status_badge.dart';
import '../domain/leave.dart';
import 'leave_controller.dart';

class LeaveScreen extends ConsumerStatefulWidget {
  const LeaveScreen({super.key});

  @override
  ConsumerState<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends ConsumerState<LeaveScreen> {
  LeaveStatus? _historyFilter;

  @override
  Widget build(BuildContext context) {
    final overviewAsync = ref.watch(leaveControllerProvider);
    return ErpModuleScaffold(
      body: overviewAsync.when(
        loading: () =>
            const AppLoadingIndicator(message: 'Loading leave data...'),
        error: (error, _) => AppErrorWidget(
          message: 'We could not load your leave information.',
          onRetry: () => ref.read(leaveControllerProvider.notifier).refresh(),
        ),
        data: (overview) {
          final today = dates.AppDate.dateOnly(DateTime.now());
          final currentRequests =
              overview.requests
                  .where(
                    (request) =>
                        !dates.AppDate.dateOnly(
                          request.endDate,
                        ).isBefore(today) &&
                        request.status != LeaveStatus.rejected &&
                        request.status != LeaveStatus.cancelled,
                  )
                  .toList()
                ..sort((a, b) => a.startDate.compareTo(b.startDate));
          final history =
              overview.requests
                  .where(
                    (request) =>
                        dates.AppDate.dateOnly(
                          request.endDate,
                        ).isBefore(today) ||
                        request.status == LeaveStatus.rejected ||
                        request.status == LeaveStatus.cancelled,
                  )
                  .where(
                    (request) =>
                        _historyFilter == null ||
                        request.status == _historyFilter,
                  )
                  .toList()
                ..sort((a, b) => b.startDate.compareTo(a.startDate));
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(leaveControllerProvider.notifier).refresh(),
            color: AppColors.primary,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                AppPageTitle(
                  title: 'Leave Management',
                  subtitle: 'Balances, applications and approval history',
                  trailing: IconButton(
                    tooltip: 'Refresh leave',
                    onPressed: () =>
                        ref.read(leaveControllerProvider.notifier).refresh(),
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _CurrentLeaveStatus(overview: overview, today: today),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: ModuleSectionTitle(
                    title: 'Leave balance',
                    subtitle: 'Available days by leave category',
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _BalanceSummaryCard(
                          label: 'Annual',
                          remaining: overview.balance.annualRemaining,
                          total: overview.balance.annualTotal,
                          color: AppColors.info,
                          icon: Icons.flight_takeoff_rounded,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _BalanceSummaryCard(
                          label: 'Casual',
                          remaining: overview.balance.casualRemaining,
                          total: overview.balance.casualTotal,
                          color: AppColors.review,
                          icon: Icons.wb_sunny_outlined,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _BalanceSummaryCard(
                          label: 'Medical',
                          remaining: overview.balance.sickRemaining,
                          total: overview.balance.sickTotal,
                          color: AppColors.warning,
                          icon: Icons.medical_services_outlined,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: ModuleSectionTitle(
                    title: 'Apply for leave',
                    subtitle: 'Submit a request for HR review',
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: _ApplyLeaveForm(),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ModuleSectionTitle(
                    title: 'My leave requests',
                    subtitle:
                        '${currentRequests.length} current request${currentRequests.length == 1 ? '' : 's'}',
                    trailing: overview.pendingCount == 0
                        ? null
                        : StatusBadge(
                            label: '${overview.pendingCount} pending',
                            color: AppColors.warning,
                            compact: true,
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                if (currentRequests.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: _InlineEmpty(
                      icon: Icons.event_available_outlined,
                      message: 'No current or upcoming leave requests.',
                    ),
                  )
                else
                  ...currentRequests.map(
                    (request) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: _LeaveRequestCard(
                        request: request,
                        onTap: () => _showDetails(request),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ModuleSectionTitle(
                    title: 'Leave history',
                    subtitle: 'Past and closed requests',
                    trailing: Text(
                      '${history.length} shown',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: context.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: ModuleFilterRow(
                    children: [
                      AppFilterChip(
                        label: 'All',
                        count: overview.requests.length,
                        selected: _historyFilter == null,
                        onSelected: (_) =>
                            setState(() => _historyFilter = null),
                      ),
                      ...LeaveStatus.values.map(
                        (status) => AppFilterChip(
                          label: status.label,
                          color: status.color,
                          count: overview.byStatus(status).length,
                          selected: _historyFilter == status,
                          onSelected: (_) => setState(
                            () => _historyFilter = _historyFilter == status
                                ? null
                                : status,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (history.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: _InlineEmpty(
                      icon: Icons.history_rounded,
                      message: 'No leave records match this filter.',
                    ),
                  )
                else
                  ...history.map(
                    (request) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: _LeaveRequestCard(
                        request: request,
                        onTap: () => _showDetails(request),
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

  void _showDetails(LeaveRequest request) {
    showModalBottomSheet<void>(
      context: context,
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
                    label: request.type.label,
                    color: request.type.color,
                  ),
                  const Spacer(),
                  StatusBadge(
                    label: request.status.label,
                    color: request.status.color,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${request.days} day${request.days == 1 ? '' : 's'} of leave',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${dates.AppDate.shortDate(request.startDate)} - ${dates.AppDate.shortDate(request.endDate)}',
                style: TextStyle(fontSize: 11.5, color: context.textSecondary),
              ),
              const SizedBox(height: 3),
              Text(
                'Request ${request.id.toUpperCase()}',
                style: TextStyle(fontSize: 9.5, color: context.textSecondary),
              ),
              const Divider(height: 24),
              const Text(
                'Reason',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 5),
              Text(
                request.reason,
                style: const TextStyle(fontSize: 12.5, height: 1.55),
              ),
              if (request.attachmentName != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.attach_file_rounded,
                      size: 15,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        request.attachmentName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (request.reviewNote != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: request.status.color.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: request.status.color.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.reviewedBy == null
                            ? 'Review note'
                            : 'Reviewed by ${request.reviewedBy}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: request.status.color,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        request.reviewNote!,
                        style: const TextStyle(fontSize: 11.5, height: 1.45),
                      ),
                    ],
                  ),
                ),
              ],
              if (request.status == LeaveStatus.pending) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Text(
                    'This request is awaiting HR review. Cancellation is managed by HR until the backend cancellation endpoint is available.',
                    style: TextStyle(fontSize: 10.5, height: 1.45),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Applied ${dates.AppDate.full(request.appliedAt)}',
                style: TextStyle(fontSize: 10, color: context.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrentLeaveStatus extends StatelessWidget {
  const _CurrentLeaveStatus({required this.overview, required this.today});

  final LeaveOverview overview;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    LeaveRequest? active;
    for (final request in overview.requests) {
      final start = dates.AppDate.dateOnly(request.startDate);
      final end = dates.AppDate.dateOnly(request.endDate);
      if (request.status == LeaveStatus.approved &&
          !today.isBefore(start) &&
          !today.isAfter(end)) {
        active = request;
        break;
      }
    }
    final onLeave = active != null;
    final color = onLeave ? AppColors.info : AppColors.success;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: context.isDark ? 0.18 : 0.09),
            context.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              shape: BoxShape.circle,
            ),
            child: Icon(
              onLeave ? Icons.beach_access_rounded : Icons.work_outline_rounded,
              size: 22,
              color: color,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      onLeave ? 'Currently on leave' : 'Currently at work',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    StatusBadge(
                      label: onLeave ? 'On leave' : 'Working',
                      color: color,
                      compact: true,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  onLeave
                      ? '${active.type.label} • ${dates.AppDate.shortDate(active.startDate)} - ${dates.AppDate.shortDate(active.endDate)}'
                      : '${overview.balance.totalRemaining} leave days available • ${overview.pendingCount} request${overview.pendingCount == 1 ? '' : 's'} pending',
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.4,
                    color: context.textSecondary,
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

class _BalanceSummaryCard extends StatelessWidget {
  const _BalanceSummaryCard({
    required this.label,
    required this.remaining,
    required this.total,
    required this.color,
    required this.icon,
  });

  final String label;
  final int remaining;
  final int total;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: context.isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            '$remaining',
            style: TextStyle(
              fontSize: 23,
              height: 1,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'of $total days',
            style: TextStyle(fontSize: 8.5, color: context.textSecondary),
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : remaining / total,
              minHeight: 4,
              backgroundColor: context.line,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplyLeaveForm extends ConsumerStatefulWidget {
  const _ApplyLeaveForm();

  @override
  ConsumerState<_ApplyLeaveForm> createState() => _ApplyLeaveFormState();
}

class _ApplyLeaveFormState extends ConsumerState<_ApplyLeaveForm> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  LeaveType _type = LeaveType.annual;
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  String? _attachmentName;
  bool _submitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  int get _days => _endDate.difference(_startDate).inDays + 1;

  Future<void> _pickDate({required bool start}) async {
    final now = DateTime.now();
    final initial = start ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 7)),
      lastDate: now.add(const Duration(days: 365)),
      helpText: start ? 'Select start date' : 'Select end date',
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) _endDate = _startDate;
      } else {
        _endDate = picked.isBefore(_startDate) ? _startDate : picked;
      }
    });
  }

  Future<void> _pickAttachment() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      );
      final file = files.isEmpty ? null : files.first;
      if (file != null) {
        setState(() => _attachmentName = file.name);
      }
    } catch (_) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        'File picker is unavailable on this platform.',
        isError: true,
      );
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      await ref
          .read(leaveControllerProvider.notifier)
          .apply(
            type: _type,
            startDate: _startDate,
            endDate: _endDate,
            reason: _reasonController.text.trim(),
            attachmentName: _attachmentName,
          );
      if (!mounted) return;
      _reasonController.clear();
      setState(() => _attachmentName = null);
      showAppSnackBar(
        context,
        'Leave application submitted for approval.',
        isSuccess: true,
      );
    } catch (_) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        'Leave application could not be submitted.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.edit_calendar_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 7),
                const Expanded(
                  child: Text(
                    'New leave application',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
                StatusBadge(
                  label: '$_days day${_days == 1 ? '' : 's'}',
                  color: AppColors.primary,
                  compact: true,
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppDropdownField<LeaveType>(
              label: 'Leave type',
              value: _type,
              icon: Icons.category_outlined,
              items: LeaveType.values
                  .map(
                    (type) =>
                        DropdownMenuItem(value: type, child: Text(type.label)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _type = value);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: 'Start date',
                    date: _startDate,
                    onTap: () => _pickDate(start: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DateField(
                    label: 'End date',
                    date: _endDate,
                    onTap: () => _pickDate(start: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _reasonController,
              label: 'Reason',
              hint: 'Explain the reason for your leave',
              prefixIcon: Icons.notes_outlined,
              maxLines: 4,
              minLines: 3,
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please provide a reason';
                }
                if (value.trim().length < 10) {
                  return 'Please provide at least 10 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickAttachment,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.line),
                  color: context.canvas,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.attach_file_rounded,
                      size: 17,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        _attachmentName ??
                            'Attach supporting document (optional)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: _attachmentName == null
                              ? context.textSecondary
                              : context.textPrimary,
                          fontWeight: _attachmentName == null
                              ? FontWeight.w400
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (_attachmentName != null)
                      InkResponse(
                        onTap: () => setState(() => _attachmentName = null),
                        radius: 16,
                        child: const Icon(Icons.close_rounded, size: 16),
                      )
                    else
                      Icon(
                        Icons.upload_file_rounded,
                        size: 17,
                        color: context.textSecondary,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            AppPrimaryButton(
              label: 'Submit application',
              icon: Icons.send_rounded,
              loading: _submitting,
              onPressed: _submitting ? null : _submit,
            ),
            const SizedBox(height: 7),
            Text(
              'Applications are reviewed by HR. Leave day rules are applied by the existing leave service.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 8.5,
                height: 1.4,
                color: context.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaveRequestCard extends StatelessWidget {
  const _LeaveRequestCard({required this.request, required this.onTap});

  final LeaveRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: request.type.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      request.type == LeaveType.sick
                          ? Icons.medical_services_outlined
                          : Icons.beach_access_outlined,
                      size: 17,
                      color: request.type.color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.type.label,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${dates.AppDate.shortDate(request.startDate)} - ${dates.AppDate.shortDate(request.endDate)} • ${request.days} day${request.days == 1 ? '' : 's'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9.5,
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 5),
                  StatusBadge(
                    label: request.status.label,
                    color: request.status.color,
                    compact: true,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                request.reason,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  height: 1.4,
                  color: context.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    request.id.toUpperCase(),
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                      color: context.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Applied ${dates.AppDate.shortDate(request.appliedAt)}',
                    style: TextStyle(
                      fontSize: 8.5,
                      color: context.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 4),
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

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.line),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: AppColors.primary),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10.5, color: context.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: 7),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.line),
              color: context.surface,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    dates.AppDate.shortDate(date),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: context.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
