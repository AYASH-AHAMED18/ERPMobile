import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/attendance_repository.dart';
import '../domain/attendance.dart';

class AttendanceController extends AsyncNotifier<AttendanceSnapshot> {
  @override
  Future<AttendanceSnapshot> build() {
    return ref.watch(attendanceRepositoryProvider).fetchToday();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(attendanceRepositoryProvider).fetchToday(),
    );
  }

  Future<AttendanceRecord> timeIn({String? note}) async {
    final record = await ref
        .read(attendanceRepositoryProvider)
        .timeIn(note: note);
    final snapshot = state.value;
    if (snapshot != null) {
      state = AsyncData(
        AttendanceSnapshot(
          today: record,
          summary: _updatedSummary(snapshot.summary, record),
          weeklyHours: snapshot.weeklyHours,
        ),
      );
    }
    return record;
  }

  Future<AttendanceRecord> timeOut(String reason) async {
    final record = await ref
        .read(attendanceRepositoryProvider)
        .timeOut(reason: reason);
    final snapshot = state.value;
    if (snapshot != null) {
      state = AsyncData(
        AttendanceSnapshot(
          today: record,
          summary: _updatedSummary(snapshot.summary, record),
          weeklyHours: snapshot.weeklyHours,
        ),
      );
    }
    return record;
  }

  List<AttendanceDaySummary> _updatedSummary(
    List<AttendanceDaySummary> summary,
    AttendanceRecord record,
  ) {
    return summary.map((day) {
      if (day.label == 'Today' ||
          (day.date != null &&
              day.date!.year == record.date.year &&
              day.date!.month == record.date.month &&
              day.date!.day == record.date.day)) {
        return AttendanceDaySummary(
          label: day.label,
          day: day.day,
          status: record.status,
          checkIn: record.checkIn,
          checkOut: record.checkOut,
          date: day.date ?? record.date,
          workedDuration: record.duration,
        );
      }
      return day;
    }).toList();
  }
}

enum AttendanceAction { idle, timeIn, timeOut }

class AttendanceActionController extends Notifier<AttendanceAction> {
  @override
  AttendanceAction build() => AttendanceAction.idle;

  void set(AttendanceAction action) => state = action;
}

final attendanceControllerProvider =
    AsyncNotifierProvider<AttendanceController, AttendanceSnapshot>(
      AttendanceController.new,
    );

final attendanceActionProvider =
    NotifierProvider<AttendanceActionController, AttendanceAction>(
      AttendanceActionController.new,
    );
