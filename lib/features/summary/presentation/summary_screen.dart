import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/employee_avatar.dart';
import '../../../core/widgets/status_badge.dart';
import '../domain/summary.dart';
import 'summary_controller.dart';

class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(summaryControllerProvider);
    return Scaffold(
      backgroundColor: context.canvas,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('My Summary'),
            Text(
              'Performance and attendance overview',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w400,
                color: context.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh summary',
            onPressed: () =>
                ref.read(summaryControllerProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded, size: 21),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: summaryAsync.when(
        loading: () =>
            const AppLoadingIndicator(message: 'Calculating your summary...'),
        error: (error, _) => AppErrorWidget(
          message: 'Unable to load your summary.',
          onRetry: () => ref.read(summaryControllerProvider.notifier).refresh(),
        ),
        data: (summary) => RefreshIndicator(
          onRefresh: () =>
              ref.read(summaryControllerProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 22),
            children: [
              _ProfileSummary(summary: summary),
              const SizedBox(height: 12),
              _QuickStats(summary: summary),
              const SizedBox(height: 12),
              _AttendanceOverview(summary: summary),
              const SizedBox(height: 12),
              _WeeklyHours(summary: summary),
              const SizedBox(height: 12),
              _TaskPerformance(summary: summary),
              const SizedBox(height: 12),
              _Projects(summary: summary),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({required this.summary});

  final SummaryData summary;

  @override
  Widget build(BuildContext context) {
    final employee = summary.employee;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.line),
      ),
      child: Row(
        children: [
          EmployeeAvatar(
            name: employee.name,
            imageUrl: employee.avatarUrl,
            size: 48,
            borderColor: AppColors.primary.withValues(alpha: 0.2),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employee.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${employee.employeeCode} • ${employee.department}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 9.5, color: context.textSecondary),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 5,
                  runSpacing: 4,
                  children: [
                    StatusBadge(
                      label: employee.designation,
                      color: AppColors.primary,
                      compact: true,
                    ),
                    const StatusBadge(
                      label: 'Full time',
                      color: AppColors.info,
                      compact: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStats extends StatelessWidget {
  const _QuickStats({required this.summary});

  final SummaryData summary;

  @override
  Widget build(BuildContext context) {
    final stats = [
      _Stat(
        'Working days',
        '${summary.totalWorkingDays}',
        AppColors.info,
        Icons.calendar_month_outlined,
      ),
      _Stat(
        'Present',
        '${summary.presentDays}',
        AppColors.success,
        Icons.check_circle_outline_rounded,
      ),
      _Stat(
        'Absent',
        '${summary.absentDays}',
        AppColors.error,
        Icons.cancel_outlined,
      ),
      _Stat(
        'Leave',
        '${summary.leaveDays}',
        AppColors.warning,
        Icons.beach_access_outlined,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: stats
              .map(
                (stat) => SizedBox(
                  width: width,
                  child: Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: context.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.line),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: stat.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(stat.icon, size: 16, color: stat.color),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stat.value,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                  color: stat.color,
                                ),
                              ),
                              Text(
                                stat.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: context.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _Stat {
  const _Stat(this.label, this.value, this.color, this.icon);
  final String label;
  final String value;
  final Color color;
  final IconData icon;
}

class _AttendanceOverview extends StatelessWidget {
  const _AttendanceOverview({required this.summary});

  final SummaryData summary;

  @override
  Widget build(BuildContext context) {
    final rate = summary.attendanceRate;
    final present = summary.presentDays;
    final absent = summary.absentDays;
    final leave = summary.leaveDays;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Attendance overview',
            subtitle: 'This month',
            icon: Icons.pie_chart_outline_rounded,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 104,
                height: 104,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 36,
                        startDegreeOffset: -90,
                        sections: [
                          PieChartSectionData(
                            value: present.toDouble(),
                            color: AppColors.success,
                            radius: 16,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            value: leave.toDouble(),
                            color: AppColors.warning,
                            radius: 16,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            value: absent.toDouble(),
                            color: AppColors.error,
                            radius: 16,
                            showTitle: false,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(rate * 100).round()}%',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: context.textPrimary,
                          ),
                        ),
                        Text(
                          'attendance',
                          style: TextStyle(
                            fontSize: 8.5,
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    _LegendRow(
                      color: AppColors.success,
                      label: 'Present',
                      value: '$present days',
                    ),
                    const SizedBox(height: 7),
                    _LegendRow(
                      color: AppColors.warning,
                      label: 'Leave',
                      value: '$leave days',
                    ),
                    const SizedBox(height: 9),
                    _LegendRow(
                      color: AppColors.error,
                      label: 'Absent',
                      value: '$absent days',
                    ),
                    const SizedBox(height: 9),
                    _LegendRow(
                      color: AppColors.info,
                      label: 'Total hours',
                      value: '${summary.totalHours.toStringAsFixed(1)} h',
                    ),
                    const SizedBox(height: 9),
                    _LegendRow(
                      color: AppColors.review,
                      label: 'Overtime',
                      value: '${summary.overtimeHours.toStringAsFixed(1)} h',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Row(
              children: [
                Expanded(
                  flex: present,
                  child: Container(height: 7, color: AppColors.success),
                ),
                Expanded(
                  flex: leave,
                  child: Container(height: 7, color: AppColors.warning),
                ),
                Expanded(
                  flex: absent,
                  child: Container(height: 7, color: AppColors.error),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Monthly attendance distribution',
                style: TextStyle(fontSize: 9.5, color: context.textSecondary),
              ),
              const Spacer(),
              Text(
                '${summary.presentDays}/${summary.totalWorkingDays} days',
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 10.5, color: context.textSecondary),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _WeeklyHours extends StatelessWidget {
  const _WeeklyHours({required this.summary});

  final SummaryData summary;

  @override
  Widget build(BuildContext context) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final values = summary.weeklyHours.length >= 7
        ? summary.weeklyHours.sublist(0, 7)
        : [...summary.weeklyHours, ...List.filled(7, 0.0)].sublist(0, 7);
    final total = values.fold<double>(0, (sum, value) => sum + value);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Weekly working hours',
            subtitle: '${total.toStringAsFixed(1)} hours logged this week',
            icon: Icons.bar_chart_rounded,
            actionLabel: 'This week',
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 165,
            child: BarChart(
              BarChartData(
                maxY: 10,
                minY: 0,
                alignment: BarChartAlignment.spaceAround,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2.5,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: context.line,
                    strokeWidth: 1,
                    dashArray: const [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      interval: 2.5,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          fontSize: 8.5,
                          color: context.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= days.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Text(
                            days[index],
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w500,
                              color: context.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                        BarTooltipItem(
                          '${rod.toY.toStringAsFixed(1)} h',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < 7; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: values[i],
                          width: 16,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                          color: i == 5 || i == 6
                              ? AppColors.backlog.withValues(alpha: 0.5)
                              : AppColors.primary,
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: 10,
                            color: context.canvas,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskPerformance extends StatelessWidget {
  const _TaskPerformance({required this.summary});

  final SummaryData summary;

  @override
  Widget build(BuildContext context) {
    final colors = {
      'Backlog': AppColors.backlog,
      'To do': AppColors.todo,
      'In progress': AppColors.inProgress,
      'Review': AppColors.review,
      'Done': AppColors.done,
    };
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Task completion',
            subtitle:
                '${summary.tasksCompleted} of ${summary.tasksAssigned} tasks completed',
            icon: Icons.task_alt_rounded,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(summary.taskCompletionRate * 100).round()}%',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  'completion rate',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: context.textSecondary,
                  ),
                ),
              ),
              const Spacer(),
              StatusBadge(
                label: '${summary.tasksCompleted} done',
                color: AppColors.success,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: summary.taskCompletionRate,
              minHeight: 8,
              backgroundColor: context.canvas,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.success,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...summary.taskDistribution.entries.map((entry) {
            final total = summary.taskDistribution.values.fold<int>(
              0,
              (sum, value) => sum + value,
            );
            final ratio = total == 0 ? 0.0 : entry.value / total;
            final color = colors[entry.key] ?? AppColors.primary;
            return Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                children: [
                  SizedBox(
                    width: 74,
                    child: Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 10,
                        color: context.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 6,
                        backgroundColor: context.canvas,
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 20,
                    child: Text(
                      '${entry.value}',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _Projects extends StatelessWidget {
  const _Projects({required this.summary});

  final SummaryData summary;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Project participation',
            subtitle: '${summary.projects.length} active projects',
            icon: Icons.workspaces_outlined,
          ),
          const SizedBox(height: 12),
          if (summary.projects.isEmpty)
            Text(
              'No active project participation.',
              style: TextStyle(fontSize: 11, color: context.textSecondary),
            )
          else
            ...summary.projects.map(
              (project) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.canvas,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.line),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.folder_outlined,
                        size: 15,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        project,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                    const StatusBadge(
                      label: 'Active',
                      color: AppColors.success,
                      compact: true,
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 15,
                  color: AppColors.info,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Hours are calculated from approved attendance records and completed task activity.',
                    style: TextStyle(
                      fontSize: 9.5,
                      height: 1.4,
                      color: context.textSecondary,
                    ),
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
