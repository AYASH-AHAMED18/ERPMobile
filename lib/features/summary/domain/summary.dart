import '../../../core/models/employee.dart';

class SummaryData {
  const SummaryData({
    required this.employee,
    required this.totalWorkingDays,
    required this.presentDays,
    required this.absentDays,
    required this.leaveDays,
    required this.totalHours,
    required this.overtimeHours,
    required this.tasksAssigned,
    required this.tasksCompleted,
    required this.projects,
    required this.weeklyHours,
    required this.monthlyAttendance,
    required this.taskDistribution,
  });

  final Employee employee;
  final int totalWorkingDays;
  final int presentDays;
  final int absentDays;
  final int leaveDays;
  final double totalHours;
  final double overtimeHours;
  final int tasksAssigned;
  final int tasksCompleted;
  final List<String> projects;
  final List<double> weeklyHours;
  final List<AttendancePoint> monthlyAttendance;
  final Map<String, int> taskDistribution;

  double get attendanceRate =>
      totalWorkingDays == 0 ? 0 : presentDays / totalWorkingDays;

  double get taskCompletionRate =>
      tasksAssigned == 0 ? 0 : tasksCompleted / tasksAssigned;
}

class AttendancePoint {
  const AttendancePoint(this.label, this.present, this.absent);
  final String label;
  final int present;
  final int absent;
}
