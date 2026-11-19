import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedcode_erp/core/models/employee.dart';
import 'package:speedcode_erp/features/attendance/data/attendance_repository.dart';
import 'package:speedcode_erp/features/attendance/domain/attendance.dart';
import 'package:speedcode_erp/features/calendar/domain/calendar_event.dart';
import 'package:speedcode_erp/features/dashboard/domain/dashboard.dart';
import 'package:speedcode_erp/features/dashboard/presentation/widgets/at_work_card.dart';
import 'package:speedcode_erp/features/dashboard/presentation/widgets/dashboard_calendar_card.dart';
import 'package:speedcode_erp/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:speedcode_erp/features/dashboard/presentation/widgets/my_tasks_card.dart';
import 'package:speedcode_erp/features/dashboard/presentation/widgets/notice_board_card.dart';
import 'package:speedcode_erp/features/dashboard/presentation/widgets/todays_events_card.dart';
import 'package:speedcode_erp/features/dashboard/presentation/widgets/welcome_attendance_card.dart';
import 'package:speedcode_erp/features/tasks/data/task_repository.dart';
import 'package:speedcode_erp/features/tasks/domain/task.dart';

const employee = Employee(
  id: 'e1',
  employeeCode: 'SCL-001',
  name: 'Ayash Perera',
  email: 'a@b.com',
  phone: '',
  department: 'Engineering',
  designation: 'Senior Flutter Engineer',
  checkedInAt: null,
);

DateTime now = DateTime.now();

class FakeAttendanceRepo implements AttendanceRepository {
  @override
  Future<AttendanceSnapshot> fetchToday() async => AttendanceSnapshot(
    today: AttendanceRecord(
      date: now,
      checkIn: DateTime(now.year, now.month, now.day, 8, 47),
      status: AttendanceStatus.working,
    ),
    summary: [
      AttendanceDaySummary(
        label: 'Day',
        day: '14',
        date: now.subtract(const Duration(days: 2)),
        status: AttendanceStatus.checkedOut,
        checkIn: DateTime(now.year, now.month, now.day - 2, 8, 55),
        checkOut: DateTime(now.year, now.month, now.day - 2, 17, 42),
      ),
      AttendanceDaySummary(
        label: 'Day',
        day: '15',
        date: now.subtract(const Duration(days: 1)),
        status: AttendanceStatus.checkedOut,
        checkIn: DateTime(now.year, now.month, now.day - 1, 8, 50),
        checkOut: DateTime(now.year, now.month, now.day - 1, 17, 30),
      ),
    ],
  );

  @override
  Future<AttendanceRecord> timeIn({String? note}) async =>
      throw UnimplementedError();

  @override
  Future<AttendanceRecord> timeOut({required String reason}) async =>
      throw UnimplementedError();
}

class FakeTaskRepo implements TaskRepository {
  @override
  Future<TaskItem> addComment(String id, String message) async =>
      throw UnimplementedError();

  @override
  Future<TaskItem> fetchTask(String id) async => throw UnimplementedError();

  @override
  Future<List<TaskItem>> fetchTasks({
    String? assignedTo,
    TaskStatus? status,
    String? search,
  }) async => List.generate(
    3,
    (i) => TaskItem(
      id: 'T$i',
      title: 'Task $i',
      description: 'Short description for task $i',
      status: TaskStatus.values[i],
      priority: TaskPriority.values[i],
      projectName: 'Project',
      assignee: employee,
      dueDate: now.add(Duration(days: i)),
      assignedToMe: true,
      assignedBy: 'Nethmi Fernando',
      progress: i == 1 ? 0.5 : null,
    ),
  );

  @override
  Future<TaskItem> updateStatus(String id, TaskStatus status) async =>
      throw UnimplementedError();
}

Widget host(Widget child) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: child,
    ),
  ),
);

void size(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('header fits 360', (tester) async {
    size(tester);
    await tester.pumpWidget(
      host(
        DashboardHeader(
          employee: employee,
          unreadNotifications: 3,
          isDark: false,
          onOpenMenu: () {},
          onScanQr: () {},
          onNotifications: () {},
          onToggleTheme: () {},
          onProfile: () {},
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('attendance, notice, events, at work and tasks fit 360', (
    tester,
  ) async {
    size(tester);
    final events = [
      CalendarEvent(
        id: '1',
        title: 'Daily stand-up',
        date: now,
        type: CalendarEventType.meeting,
        startTime: '09:30',
        endTime: '09:45',
        location: 'Google Meet',
      ),
      CalendarEvent(
        id: '2',
        title: 'Campaign review meeting with marketing',
        date: now,
        type: CalendarEventType.company,
        startTime: '15:00',
        endTime: '15:45',
        location: 'Meeting room - Orchid',
      ),
    ];
    final notices = [
      Notice(
        id: 'n1',
        title: 'Quarterly performance review schedule',
        description:
            'Please complete your self-assessment form before Friday 5:00 PM.',
        postedAt: now.subtract(const Duration(hours: 3)),
        author: 'Tharushi Weerasinghe',
        authorDesignation: 'HR Executive',
        authorDepartment: 'Human Resources',
        priority: NoticePriority.important,
        hasAttachment: true,
        attachmentName: 'form.pdf',
      ),
      Notice(
        id: 'n2',
        title: 'Office closed for Poya Day',
        description: 'The Colombo office will remain closed on Friday.',
        postedAt: now.subtract(const Duration(days: 1)),
        author: 'Admin',
        priority: NoticePriority.urgent,
      ),
    ];
    final status = EmployeeStatusSummary(
      atWork: 2,
      onLeave: 0,
      employees: [
        employee.copyWith(
          checkedInAt: DateTime(now.year, now.month, now.day, 8, 47),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          attendanceRepositoryProvider.overrideWithValue(FakeAttendanceRepo()),
          taskRepositoryProvider.overrideWithValue(FakeTaskRepo()),
        ],
        child: host(
          Column(
            children: [
              WelcomeAttendanceCard(employee: employee),
              const SizedBox(height: 12),
              NoticeBoardCard(
                notices: notices,
                unreadCount: 1,
                canPost: false,
                onReadMore: (_) {},
                onViewAll: () {},
              ),
              const SizedBox(height: 12),
              DashboardCalendarCard(
                events: events,
                onViewFull: () {},
                todayAttendance: AttendanceRecord(
                  date: now,
                  checkIn: DateTime(now.year, now.month, now.day, 8, 47),
                  status: AttendanceStatus.working,
                ),
              ),
              const SizedBox(height: 12),
              TodaysEventsCard(events: events),
              const SizedBox(height: 12),
              AtWorkCard(status: status),
              const SizedBox(height: 12),
              const MyTasksCard(),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
