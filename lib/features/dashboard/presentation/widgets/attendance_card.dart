import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/models/employee.dart';
import '../../../../core/utils/date_utils.dart' as dates;
import '../../../../core/widgets/app_states.dart';
import '../../../attendance/domain/attendance.dart';
import '../../../attendance/presentation/attendance_controller.dart';
import '../dashboard_controller.dart';
import 'attendance_chip.dart';

const _timeOutReasons = <String>[
  'End of day',
  'Lunch break',
  'Client visit',
  'Medical appointment',
  'Working from home',
  'Other',
];

class AttendanceCard extends ConsumerStatefulWidget {
  const AttendanceCard({super.key, required this.employee, this.onViewHistory});

  final Employee employee;
  final VoidCallback? onViewHistory;

  @override
  ConsumerState<AttendanceCard> createState() => _AttendanceCardState();
}

class _AttendanceCardState extends ConsumerState<AttendanceCard> {
  Timer? _ticker;
  String? _reason;
  String? _reasonError;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      final attendance = ref.read(attendanceControllerProvider).value?.today;
      if (mounted && attendance != null && attendance.isCheckedIn) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _timeIn() async {
    if (ref.read(attendanceActionProvider) != AttendanceAction.idle) return;
    ref.read(attendanceActionProvider.notifier).set(AttendanceAction.timeIn);
    try {
      final record = await ref
          .read(attendanceControllerProvider.notifier)
          .timeIn();
      if (!mounted) return;
      showAppSnackBar(
        context,
        'Checked in at ${dates.AppDate.time(record.checkIn)}',
        isSuccess: true,
      );
      await ref.read(dashboardControllerProvider.notifier).refresh();
    } catch (error) {
      if (!mounted) return;
      showAppSnackBar(context, _friendly(error), isError: true);
    } finally {
      ref.read(attendanceActionProvider.notifier).set(AttendanceAction.idle);
    }
  }

  Future<void> _timeOut() async {
    if (ref.read(attendanceActionProvider) != AttendanceAction.idle) return;
    final reason = _reason?.trim();
    if (reason == null || reason.isEmpty) {
      setState(() {
        _reasonError = 'Please select a reason to time out.';
      });
      showAppSnackBar(
        context,
        'Select a reason before timing out.',
        isError: true,
      );
      return;
    }

    ref.read(attendanceActionProvider.notifier).set(AttendanceAction.timeOut);
    try {
      final record = await ref
          .read(attendanceControllerProvider.notifier)
          .timeOut(reason);
      if (!mounted) return;
      setState(() {
        _reason = null;
        _reasonError = null;
      });
      showAppSnackBar(
        context,
        'Checked out at ${dates.AppDate.time(record.checkOut)}',
        isSuccess: true,
      );
      await ref.read(dashboardControllerProvider.notifier).refresh();
    } catch (error) {
      if (!mounted) return;
      showAppSnackBar(context, _friendly(error), isError: true);
    } finally {
      ref.read(attendanceActionProvider.notifier).set(AttendanceAction.idle);
    }
  }

  String _friendly(Object error) {
    final text = error.toString();
    return text.replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    final attendance = ref.watch(attendanceControllerProvider);
    final action = ref.watch(attendanceActionProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: context.isDark
            ? AppColors.attendanceGradientDark
            : AppColors.attendanceGradient,
        borderRadius: BorderRadius.circular(AppRadii.xxl),
        border: Border.all(color: AppColors.successBorder, width: 1.5),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GreetingSection(employee: widget.employee),
          const SizedBox(height: AppSpacing.lg),
          attendance.when(
            loading: () => const SizedBox(
              height: 210,
              child: AppLoadingIndicator(message: 'Loading attendance...'),
            ),
            error: (error, _) => SizedBox(
              height: 210,
              child: AppErrorWidget(
                message: 'Unable to load attendance right now.',
                compact: true,
                onRetry: () =>
                    ref.read(attendanceControllerProvider.notifier).refresh(),
              ),
            ),
            data: (snapshot) => _AttendanceBody(
              snapshot: snapshot,
              action: action,
              reason: _reason,
              reasonError: _reasonError,
              onReasonChanged: (value) {
                setState(() {
                  _reason = value;
                  _reasonError = null;
                });
              },
              onTimeIn: _timeIn,
              onTimeOut: _timeOut,
            ),
          ),
        ],
      ),
    );
  }
}

class _GreetingSection extends StatelessWidget {
  const _GreetingSection({required this.employee});

  final Employee employee;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dates.AppDate.greeting(),
          style: TextStyle(
            fontSize: 18,
            height: 1.2,
            fontWeight: FontWeight.w500,
            color: context.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          employee.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 28,
            height: 1.12,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.7,
            color: context.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _AttendanceBody extends StatelessWidget {
  const _AttendanceBody({
    required this.snapshot,
    required this.action,
    required this.reason,
    required this.reasonError,
    required this.onReasonChanged,
    required this.onTimeIn,
    required this.onTimeOut,
  });

  final AttendanceSnapshot snapshot;
  final AttendanceAction action;
  final String? reason;
  final String? reasonError;
  final ValueChanged<String?> onReasonChanged;
  final VoidCallback onTimeIn;
  final VoidCallback onTimeOut;

  @override
  Widget build(BuildContext context) {
    final today = snapshot.today;
    final onLeave = today.status == AttendanceStatus.onLeave;
    final isWorking = today.isCheckedIn;
    final isCheckedOut = today.isCheckedOut;
    final busy = action != AttendanceAction.idle;
    final yesterday = _summaryFor(
      snapshot.summary,
      DateTime.now().subtract(const Duration(days: 1)),
    );
    final latest = _latestSummary(snapshot.summary, today);
    final latestDate = latest.date ?? today.date;
    final todayDuration = today.duration;

    final statusLabel = onLeave
        ? 'Leave'
        : isWorking
        ? 'In'
        : 'Out';
    final statusColor = onLeave
        ? AppColors.info
        : isWorking
        ? AppColors.success
        : AppColors.warning;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            AttendanceChip(
              label: statusLabel,
              fillColor: statusColor,
              borderColor: statusColor,
              textColor: Colors.white,
            ),
            AttendanceChip(
              label:
                  '${DateFormat('EEE, MMM d').format(latestDate)}  '
                  '${dates.AppDate.duration(latest.duration)}',
            ),
            AttendanceChip(
              label:
                  'Yesterday  '
                  '${yesterday == null ? '—' : dates.AppDate.duration(yesterday.duration)}',
            ),
            AttendanceChip(
              label: 'Today  ${dates.AppDate.duration(todayDuration)}',
              fillColor: AppColors.successLight,
              borderColor: AppColors.successBorder,
              textColor: AppColors.success,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _ReasonDropdown(
          value: reason,
          errorText: reasonError,
          enabled: isWorking && !busy,
          onChanged: onReasonChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        _AttendanceActionButton(
          label: onLeave
              ? 'ON LEAVE'
              : isWorking
              ? 'TIME OUT'
              : 'TIME IN',
          color: onLeave
              ? AppColors.info
              : isWorking
              ? AppColors.warning
              : AppColors.success,
          loading:
              (isWorking && action == AttendanceAction.timeOut) ||
              (!isWorking && action == AttendanceAction.timeIn),
          enabled: !onLeave && !busy,
          onPressed: isWorking ? onTimeOut : onTimeIn,
        ),
        const SizedBox(height: AppSpacing.lg),
        _AttendanceTimeline(
          record: today,
          isWorking: isWorking,
          isCheckedOut: isCheckedOut,
          onLeave: onLeave,
          duration: todayDuration,
        ),
      ],
    );
  }

  static AttendanceDaySummary? _summaryFor(
    List<AttendanceDaySummary> summary,
    DateTime expected,
  ) {
    for (final day in summary) {
      final date = day.date;
      if (date != null && dates.AppDate.isSameDay(date, expected)) {
        return day;
      }
    }
    return null;
  }

  static AttendanceDaySummary _latestSummary(
    List<AttendanceDaySummary> summary,
    AttendanceRecord fallback,
  ) {
    AttendanceDaySummary? latest;
    for (final day in summary) {
      if (day.date == null) continue;
      if (latest == null || day.date!.isAfter(latest.date!)) {
        latest = day;
      }
    }
    return latest ??
        AttendanceDaySummary(
          label: 'Today',
          day: fallback.date.day.toString(),
          date: fallback.date,
          status: fallback.status,
          checkIn: fallback.checkIn,
          checkOut: fallback.checkOut,
          workedDuration: fallback.duration,
        );
  }
}

class _ReasonDropdown extends StatelessWidget {
  const _ReasonDropdown({
    required this.value,
    required this.errorText,
    required this.enabled,
    required this.onChanged,
  });

  final String? value;
  final String? errorText;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final borderColor = errorText != null
        ? AppColors.error
        : enabled
        ? context.line
        : context.line.withValues(alpha: 0.7);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            color: context.isDark
                ? AppColors.darkSurfaceAlt
                : AppColors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: borderColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: Text(
                'Reason to time out',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: context.textSecondary,
                ),
              ),
              icon: Icon(
                Icons.unfold_more_rounded,
                size: 22,
                color: enabled ? context.textPrimary : context.textSecondary,
              ),
              dropdownColor: context.surface,
              borderRadius: BorderRadius.circular(AppRadii.md),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: context.textPrimary,
              ),
              items: _timeOutReasons
                  .map(
                    (reason) => DropdownMenuItem<String>(
                      value: reason,
                      child: Text(
                        reason,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: enabled ? onChanged : null,
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xxs),
            child: Text(
              errorText!,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AttendanceActionButton extends StatelessWidget {
  const _AttendanceActionButton({
    required this.label,
    required this.color,
    required this.loading,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final bool loading;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.lg);
    final effectiveColor = enabled ? color : color.withValues(alpha: 0.55);

    return Semantics(
      button: true,
      enabled: enabled,
      label: loading ? 'Please wait' : label,
      onTap: enabled ? onPressed : null,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        height: AppSizes.attendanceButton,
        width: double.infinity,
        decoration: BoxDecoration(
          color: effectiveColor,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: enabled ? 0.26 : 0.1),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: radius,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.3,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AttendanceTimeline extends StatelessWidget {
  const _AttendanceTimeline({
    required this.record,
    required this.isWorking,
    required this.isCheckedOut,
    required this.onLeave,
    required this.duration,
  });

  final AttendanceRecord record;
  final bool isWorking;
  final bool isCheckedOut;
  final bool onLeave;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final inColor = onLeave ? AppColors.info : AppColors.success;
    final outColor = onLeave ? AppColors.info : AppColors.warning;
    final footnote = onLeave
        ? 'On leave · Attendance paused'
        : isCheckedOut
        ? 'Completed · ${dates.AppDate.duration(duration)}'
        : isWorking
        ? 'On the clock · ${dates.AppDate.duration(duration)}'
        : 'Not checked in · 0m';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TimelineRow(
          label: 'In',
          value: record.checkIn == null
              ? '— not yet'
              : dates.AppDate.time(record.checkIn),
          color: inColor,
          filled: record.checkIn != null,
          showLine: true,
        ),
        _TimelineRow(
          label: 'Out',
          value: record.checkOut == null
              ? '— ${isWorking ? 'open' : 'pending'}'
              : dates.AppDate.time(record.checkOut),
          color: outColor,
          filled: isCheckedOut,
          showLine: false,
        ),
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xxl),
          child: Row(
            children: [
              if (isWorking && !onLeave)
                const Padding(
                  padding: EdgeInsets.only(right: AppSpacing.xs),
                  child: _PulseDot(),
                ),
              Flexible(
                child: Text(
                  footnote,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: context.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.label,
    required this.value,
    required this.color,
    required this.filled,
    required this.showLine,
  });

  final String label;
  final String value;
  final Color color;
  final bool filled;
  final bool showLine;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: AppSizes.attendanceTimelineDot,
                  height: AppSizes.attendanceTimelineDot,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    color: filled ? color : context.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: filled ? color : color.withValues(alpha: 0.85),
                      width: 1.8,
                    ),
                  ),
                ),
                if (showLine)
                  Container(
                    width: 1.5,
                    height: 19,
                    margin: const EdgeInsets.only(top: 2),
                    color: context.line,
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$label ',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: filled ? context.textPrimary : color,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, height: 1.2),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatelessWidget {
  const _PulseDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: AppColors.success,
        shape: BoxShape.circle,
      ),
    );
  }
}
