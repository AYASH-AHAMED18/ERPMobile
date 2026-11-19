import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

enum LeaveType {
  annual('Annual leave', AppColors.info),
  casual('Casual leave', AppColors.review),
  sick('Sick leave', AppColors.warning),
  unpaid('Unpaid leave', AppColors.backlog),
  maternity('Maternity leave', AppColors.primary),
  other('Other', AppColors.secondaryText);

  const LeaveType(this.label, this.color);
  final String label;
  final Color color;

  static LeaveType fromValue(dynamic value) => LeaveType.values.firstWhere(
    (type) => type.name == value?.toString().toLowerCase(),
    orElse: () => LeaveType.annual,
  );
}

enum LeaveStatus {
  pending('Pending', AppColors.warning),
  approved('Approved', AppColors.success),
  rejected('Rejected', AppColors.error),
  cancelled('Cancelled', AppColors.backlog);

  const LeaveStatus(this.label, this.color);
  final String label;
  final Color color;

  static LeaveStatus fromValue(dynamic value) => LeaveStatus.values.firstWhere(
    (status) => status.name == value?.toString().toLowerCase(),
    orElse: () => LeaveStatus.pending,
  );
}

class LeaveRequest {
  const LeaveRequest({
    required this.id,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.reason,
    required this.status,
    required this.appliedAt,
    this.attachmentName,
    this.reviewedBy,
    this.reviewNote,
  });

  final String id;
  final LeaveType type;
  final DateTime startDate;
  final DateTime endDate;
  final int days;
  final String reason;
  final LeaveStatus status;
  final DateTime appliedAt;
  final String? attachmentName;
  final String? reviewedBy;
  final String? reviewNote;

  factory LeaveRequest.fromJson(Map<String, dynamic> json) => LeaveRequest(
    id: (json['id'] ?? '').toString(),
    type: LeaveType.fromValue(json['type']),
    startDate:
        DateTime.tryParse(json['start_date']?.toString() ?? '') ??
        DateTime.now(),
    endDate:
        DateTime.tryParse(json['end_date']?.toString() ?? '') ?? DateTime.now(),
    days: (json['days'] as num?)?.toInt() ?? 1,
    reason: (json['reason'] ?? '').toString(),
    status: LeaveStatus.fromValue(json['status']),
    appliedAt:
        DateTime.tryParse(json['applied_at']?.toString() ?? '') ??
        DateTime.now(),
    attachmentName: json['attachment_name']?.toString(),
    reviewedBy: json['reviewed_by']?.toString(),
    reviewNote: json['review_note']?.toString(),
  );
}

class LeaveOverview {
  const LeaveOverview({required this.balance, required this.requests});

  final LeaveBalance balance;
  final List<LeaveRequest> requests;

  List<LeaveRequest> byStatus(LeaveStatus status) =>
      requests.where((request) => request.status == status).toList();

  int get pendingCount => byStatus(LeaveStatus.pending).length;
}

class LeaveBalance {
  const LeaveBalance({
    required this.annualTotal,
    required this.annualUsed,
    required this.casualTotal,
    required this.casualUsed,
    required this.sickTotal,
    required this.sickUsed,
  });

  final int annualTotal;
  final int annualUsed;
  final int casualTotal;
  final int casualUsed;
  final int sickTotal;
  final int sickUsed;

  int get annualRemaining => (annualTotal - annualUsed).clamp(0, annualTotal);
  int get casualRemaining => (casualTotal - casualUsed).clamp(0, casualTotal);
  int get sickRemaining => (sickTotal - sickUsed).clamp(0, sickTotal);
  int get totalRemaining => annualRemaining + casualRemaining + sickRemaining;

  factory LeaveBalance.fromJson(Map<String, dynamic> json) => LeaveBalance(
    annualTotal: (json['annual_total'] as num?)?.toInt() ?? 0,
    annualUsed: (json['annual_used'] as num?)?.toInt() ?? 0,
    casualTotal: (json['casual_total'] as num?)?.toInt() ?? 0,
    casualUsed: (json['casual_used'] as num?)?.toInt() ?? 0,
    sickTotal: (json['sick_total'] as num?)?.toInt() ?? 0,
    sickUsed: (json['sick_used'] as num?)?.toInt() ?? 0,
  );
}
