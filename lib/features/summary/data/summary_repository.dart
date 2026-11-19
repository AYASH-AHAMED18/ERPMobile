import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_config.dart';
import '../../../core/mock/mock_database.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/response_utils.dart';
import '../../profile/domain/employee.dart';
import '../domain/summary.dart';

abstract class SummaryRepository {
  Future<SummaryData> fetchSummary();
}

class MockSummaryRepository implements SummaryRepository {
  MockSummaryRepository(this._db);
  final MockDatabase _db;

  @override
  Future<SummaryData> fetchSummary() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return _db.summary;
  }
}

class ApiSummaryRepository implements SummaryRepository {
  ApiSummaryRepository(this._client);
  final ApiClient _client;

  @override
  Future<SummaryData> fetchSummary() async {
    final data = asMap(await _client.get(ApiEndpoints.summary));
    final attendance = mapOf(data['attendance']);
    final tasks = mapOf(data['tasks']);
    return SummaryData(
      employee: Employee.fromJson(mapOf(data['employee'])),
      totalWorkingDays:
          (attendance['total_working_days'] as num?)?.toInt() ?? 0,
      presentDays: (attendance['present_days'] as num?)?.toInt() ?? 0,
      absentDays: (attendance['absent_days'] as num?)?.toInt() ?? 0,
      leaveDays: (attendance['leave_days'] as num?)?.toInt() ?? 0,
      totalHours: (attendance['total_hours'] as num?)?.toDouble() ?? 0,
      overtimeHours: (attendance['overtime_hours'] as num?)?.toDouble() ?? 0,
      tasksAssigned: (tasks['assigned'] as num?)?.toInt() ?? 0,
      tasksCompleted: (tasks['completed'] as num?)?.toInt() ?? 0,
      projects: asList(
        data['projects'],
      ).map((project) => project.toString()).toList(),
      weeklyHours: asList(
        data['weekly_hours'],
      ).map((value) => (value as num).toDouble()).toList(),
      monthlyAttendance: asList(data['monthly_attendance']).map((item) {
        final map = mapOf(item);
        return AttendancePoint(
          (map['label'] ?? '').toString(),
          (map['present'] as num?)?.toInt() ?? 0,
          (map['absent'] as num?)?.toInt() ?? 0,
        );
      }).toList(),
      taskDistribution: mapOf(
        tasks['distribution'],
      ).map((key, value) => MapEntry(key, (value as num).toInt())),
    );
  }
}

final summaryRepositoryProvider = Provider<SummaryRepository>((ref) {
  if (AppConfig.useMockData) {
    return MockSummaryRepository(MockDatabase.instance);
  }
  return ApiSummaryRepository(ref.watch(apiClientProvider));
});
