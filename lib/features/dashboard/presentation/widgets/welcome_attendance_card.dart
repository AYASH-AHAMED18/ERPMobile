import 'package:flutter/material.dart';

import '../../../../core/models/employee.dart';
import 'attendance_card.dart';

class WelcomeAttendanceCard extends StatelessWidget {
  const WelcomeAttendanceCard({
    super.key,
    required this.employee,
    this.onViewHistory,
  });

  final Employee employee;
  final VoidCallback? onViewHistory;

  @override
  Widget build(BuildContext context) {
    return AttendanceCard(employee: employee, onViewHistory: onViewHistory);
  }
}
