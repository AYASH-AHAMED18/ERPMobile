import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

enum AttendanceStatus {
  notCheckedIn('Not checked in', AppColors.backlog),
  working('Working', AppColors.success),
  checkedOut('Checked out', AppColors.info),
  onLeave('On leave', AppColors.warning),
  late('Late', AppColors.warning),
  absent('Absent', AppColors.error);

  const AttendanceStatus(this.label, this.color);
  final String label;
  final Color color;
}

class AttendanceRecord {
  const AttendanceRecord({
    required this.date,
    this.checkIn,
    this.checkOut,
    this.timeInNote,
    this.timeOutReason,
    this.status = AttendanceStatus.notCheckedIn,
    this.scheduledStart,
    this.scheduledEnd,
    this.workedDuration,
  });

  final DateTime date;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String? timeInNote;
  final String? timeOutReason;
  final AttendanceStatus status;
  final DateTime? scheduledStart;
  final DateTime? scheduledEnd;
  final Duration? workedDuration;

  bool get isCheckedIn => checkIn != null && checkOut == null;
  bool get isCheckedOut => checkOut != null;
  bool get hasCheckedIn => checkIn != null;

  Duration get duration {
    if (checkIn == null) return Duration.zero;
    if (isCheckedIn) return DateTime.now().difference(checkIn!);
    if (workedDuration != null) return workedDuration!;
    return (checkOut ?? DateTime.now()).difference(checkIn!);
  }

  String get statusLabel {
    if (isCheckedOut) return 'Checked Out';
    if (isCheckedIn) return 'Checked In';
    if (status == AttendanceStatus.onLeave) return 'On Leave';
    if (status == AttendanceStatus.absent) return 'Absent';
    return 'Not Checked In';
  }

  AttendanceRecord copyWith({
    DateTime? checkIn,
    DateTime? checkOut,
    String? timeInNote,
    String? timeOutReason,
    AttendanceStatus? status,
  }) {
    return AttendanceRecord(
      date: date,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      timeInNote: timeInNote ?? this.timeInNote,
      timeOutReason: timeOutReason ?? this.timeOutReason,
      status: status ?? this.status,
      scheduledStart: scheduledStart,
      scheduledEnd: scheduledEnd,
      workedDuration: workedDuration,
    );
  }

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      checkIn: DateTime.tryParse(json['check_in']?.toString() ?? ''),
      checkOut: DateTime.tryParse(json['check_out']?.toString() ?? ''),
      timeInNote: (json['time_in_note'] ?? json['note'])?.toString(),
      timeOutReason: json['time_out_reason']?.toString(),
      status: AttendanceStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => AttendanceStatus.notCheckedIn,
      ),
    );
  }
}

class AttendanceDaySummary {
  const AttendanceDaySummary({
    required this.label,
    required this.day,
    required this.status,
    this.checkIn,
    this.checkOut,
    this.date,
    this.workedDuration,
  });

  final String label;
  final String day;
  final AttendanceStatus status;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final DateTime? date;
  final Duration? workedDuration;

  Duration get duration {
    if (workedDuration != null) return workedDuration!;
    if (checkIn == null) return Duration.zero;
    return (checkOut ?? checkIn!).difference(checkIn!);
  }

  String get shortStatus {
    switch (status) {
      case AttendanceStatus.working:
        return 'Present';
      case AttendanceStatus.checkedOut:
        return 'Present';
      case AttendanceStatus.late:
        return 'Late';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.onLeave:
        return 'Leave';
      default:
        return 'Upcoming';
    }
  }
}

class AttendanceSnapshot {
  const AttendanceSnapshot({
    required this.today,
    required this.summary,
    this.weeklyHours = const [],
  });

  final AttendanceRecord today;
  final List<AttendanceDaySummary> summary;
  final List<double> weeklyHours;
}
