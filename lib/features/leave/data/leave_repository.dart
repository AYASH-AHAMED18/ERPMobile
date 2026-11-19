import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_config.dart';
import '../../../core/mock/mock_database.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/response_utils.dart';
import '../domain/leave.dart';

abstract class LeaveRepository {
  Future<LeaveOverview> fetchOverview();
  Future<LeaveRequest> applyLeave({
    required LeaveType type,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    String? attachmentName,
  });
}

class MockLeaveRepository implements LeaveRepository {
  MockLeaveRepository(this._db);
  final MockDatabase _db;

  @override
  Future<LeaveOverview> fetchOverview() async {
    await Future<void>.delayed(const Duration(milliseconds: 550));
    return LeaveOverview(
      balance: _db.leaveBalance,
      requests: List.unmodifiable(_db.leaveRequests),
    );
  }

  @override
  Future<LeaveRequest> applyLeave({
    required LeaveType type,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    String? attachmentName,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 850));
    final days = endDate.difference(startDate).inDays + 1;
    final request = LeaveRequest(
      id: 'leave-${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      startDate: startDate,
      endDate: endDate,
      days: days,
      reason: reason,
      status: LeaveStatus.pending,
      appliedAt: DateTime.now(),
      attachmentName: attachmentName,
    );
    _db.leaveRequests.insert(0, request);
    return request;
  }
}

class ApiLeaveRepository implements LeaveRepository {
  ApiLeaveRepository(this._client);
  final ApiClient _client;

  @override
  Future<LeaveOverview> fetchOverview() async {
    final data = asMap(await _client.get(ApiEndpoints.leaveRequests));
    return LeaveOverview(
      balance: LeaveBalance.fromJson(mapOf(data['balance'])),
      requests: asList(
        data['requests'],
      ).map((item) => LeaveRequest.fromJson(mapOf(item))).toList(),
    );
  }

  @override
  Future<LeaveRequest> applyLeave({
    required LeaveType type,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    String? attachmentName,
  }) async {
    final data = await _client.post(
      ApiEndpoints.leaveRequests,
      data: {
        'type': type.name,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'reason': reason,
        'attachment_name': ?attachmentName,
      },
    );
    return LeaveRequest.fromJson(asMap(data));
  }
}

final leaveRepositoryProvider = Provider<LeaveRepository>((ref) {
  if (AppConfig.useMockData) {
    return MockLeaveRepository(MockDatabase.instance);
  }
  return ApiLeaveRepository(ref.watch(apiClientProvider));
});
