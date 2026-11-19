import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_config.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/mock/mock_database.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/response_utils.dart';
import '../domain/attendance.dart';

abstract class AttendanceRepository {
  Future<AttendanceSnapshot> fetchToday();
  Future<AttendanceRecord> timeIn({String? note});
  Future<AttendanceRecord> timeOut({required String reason});
}

class MockAttendanceRepository implements AttendanceRepository {
  MockAttendanceRepository(this._db);

  final MockDatabase _db;

  @override
  Future<AttendanceSnapshot> fetchToday() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return AttendanceSnapshot(
      today: _db.attendance,
      summary: List.unmodifiable(_db.attendanceSummary),
      weeklyHours: const [7.4, 8.1, 7.8, 8.6, 7.9, 0, 0],
    );
  }

  @override
  Future<AttendanceRecord> timeIn({String? note}) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (_db.attendance.isCheckedIn) {
      throw const AppException('You have already checked in today.');
    }
    final previous = _db.attendance;
    _db.attendance = AttendanceRecord(
      date: previous.date,
      checkIn: DateTime.now(),
      timeInNote: note?.trim().isEmpty ?? true ? null : note?.trim(),
      status: AttendanceStatus.working,
      scheduledStart: previous.scheduledStart,
      scheduledEnd: previous.scheduledEnd,
    );
    return _db.attendance;
  }

  @override
  Future<AttendanceRecord> timeOut({required String reason}) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!_db.attendance.hasCheckedIn) {
      throw const AppException('You need to check in before checking out.');
    }
    if (_db.attendance.isCheckedOut) {
      throw const AppException('You have already checked out today.');
    }
    final now = DateTime.now();
    _db.attendance = _db.attendance.copyWith(
      checkOut: now,
      timeOutReason: reason,
      status: AttendanceStatus.checkedOut,
    );
    return _db.attendance;
  }
}

class ApiAttendanceRepository implements AttendanceRepository {
  ApiAttendanceRepository(this._client);

  final ApiClient _client;

  @override
  Future<AttendanceSnapshot> fetchToday() async {
    final data = asMap(await _client.get(ApiEndpoints.attendanceToday));
    return AttendanceSnapshot(
      today: AttendanceRecord.fromJson(mapOf(data['today'])),
      summary: asList(data['summary']).map((item) {
        final map = mapOf(item);
        final checkIn = DateTime.tryParse(
          (map['check_in'] ?? map['time_in'] ?? '').toString(),
        );
        final checkOut = DateTime.tryParse(
          (map['check_out'] ?? map['time_out'] ?? '').toString(),
        );
        final workedMinutes = (map['worked_minutes'] as num?)?.toInt();
        return AttendanceDaySummary(
          label: (map['label'] ?? '').toString(),
          day: (map['day'] ?? '').toString(),
          status: AttendanceStatus.values.firstWhere(
            (status) => status.name == map['status'],
            orElse: () => AttendanceStatus.notCheckedIn,
          ),
          checkIn: checkIn,
          checkOut: checkOut,
          date: DateTime.tryParse((map['date'] ?? '').toString()),
          workedDuration: workedMinutes == null
              ? null
              : Duration(minutes: workedMinutes),
        );
      }).toList(),
      weeklyHours: asList(
        data['weekly_hours'],
      ).map((value) => (value as num).toDouble()).toList(),
    );
  }

  @override
  Future<AttendanceRecord> timeIn({String? note}) async {
    final data = await _client.post(
      ApiEndpoints.attendanceTimeIn,
      data: {if (note != null && note.trim().isNotEmpty) 'note': note.trim()},
    );
    return AttendanceRecord.fromJson(asMap(data));
  }

  @override
  Future<AttendanceRecord> timeOut({required String reason}) async {
    final data = await _client.post(
      ApiEndpoints.attendanceTimeOut,
      data: {'reason': reason},
    );
    return AttendanceRecord.fromJson(asMap(data));
  }
}

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  if (AppConfig.useMockData) {
    return MockAttendanceRepository(MockDatabase.instance);
  }
  return ApiAttendanceRepository(ref.watch(apiClientProvider));
});
