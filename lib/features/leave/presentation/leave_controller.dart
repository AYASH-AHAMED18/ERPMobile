import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/leave_repository.dart';
import '../domain/leave.dart';

class LeaveController extends AsyncNotifier<LeaveOverview> {
  @override
  Future<LeaveOverview> build() {
    return ref.watch(leaveRepositoryProvider).fetchOverview();
  }

  Future<void> refresh() async {
    state = const AsyncLoading<LeaveOverview>();
    state = await AsyncValue.guard(
      () => ref.read(leaveRepositoryProvider).fetchOverview(),
    );
  }

  Future<LeaveRequest> apply({
    required LeaveType type,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    String? attachmentName,
  }) async {
    final request = await ref
        .read(leaveRepositoryProvider)
        .applyLeave(
          type: type,
          startDate: startDate,
          endDate: endDate,
          reason: reason,
          attachmentName: attachmentName,
        );
    await refresh();
    return request;
  }
}

final leaveControllerProvider =
    AsyncNotifierProvider<LeaveController, LeaveOverview>(LeaveController.new);
