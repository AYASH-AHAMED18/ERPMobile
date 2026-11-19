import 'package:flutter/material.dart';

import '../../features/attendance/domain/attendance.dart';
import '../../features/calendar/domain/calendar_event.dart';
import '../../features/chat/domain/chat.dart';
import '../../features/dashboard/domain/dashboard.dart';
import '../../features/events/domain/company_event.dart';
import '../../features/leave/domain/leave.dart';
import '../../features/live/domain/meeting.dart';
import '../../features/mailbox/domain/email.dart';
import '../../features/sharing/domain/shared_file.dart';
import '../../features/summary/domain/summary.dart';
import '../../features/tasks/domain/task.dart';
import '../models/employee.dart';

/// Development-only in-memory database.
///
/// Everything here is clearly isolated from production repositories. No screen
/// reads this file directly; only `*MockRepository` classes do.
class MockDatabase {
  MockDatabase._();
  static final MockDatabase instance = MockDatabase._();

  factory MockDatabase() => instance;

  static final DateTime now = DateTime.now();

  late final Employee currentUser = Employee(
    id: 'emp-001',
    employeeCode: 'SCL-001',
    name: 'Ayash Perera',
    email: 'ayash@speedcodelabs.com',
    phone: '+94 77 452 8891',
    department: 'Engineering',
    designation: 'Senior Flutter Engineer',
    avatarUrl: 'https://i.pravatar.cc/200?img=12',
    role: 'Employee',
    joinedAt: DateTime(2022, 4, 18),
    location: 'Colombo, Sri Lanka',
    workStatus: EmployeeWorkStatus.atWork,
    checkedInAt: DateTime(now.year, now.month, now.day, 8, 47),
  );

  static final List<Employee> employees = [
    Employee(
      id: 'emp-001',
      employeeCode: 'SCL-001',
      name: 'Ayash Perera',
      email: 'ayash@speedcodelabs.com',
      phone: '+94 77 452 8891',
      department: 'Engineering',
      designation: 'Senior Flutter Engineer',
      avatarUrl: 'https://i.pravatar.cc/150?img=12',
      joinedAt: DateTime(2022, 4, 18),
      location: 'Colombo',
    ),
    Employee(
      id: 'emp-002',
      employeeCode: 'SCL-014',
      name: 'Nethmi Fernando',
      email: 'nethmi@speedcodelabs.com',
      phone: '+94 71 890 4421',
      department: 'Digital Marketing',
      designation: 'Marketing Lead',
      avatarUrl: 'https://i.pravatar.cc/150?img=47',
      workStatus: EmployeeWorkStatus.atWork,
      checkedInAt: DateTime(now.year, now.month, now.day, 8, 59),
    ),
    Employee(
      id: 'emp-003',
      employeeCode: 'SCL-021',
      name: 'Kavindu Silva',
      email: 'kavindu@speedcodelabs.com',
      phone: '+94 76 221 5530',
      department: 'Engineering',
      designation: 'Backend Engineer',
      avatarUrl: 'https://i.pravatar.cc/150?img=33',
      workStatus: EmployeeWorkStatus.atWork,
      checkedInAt: DateTime(now.year, now.month, now.day, 9, 12),
    ),
    Employee(
      id: 'emp-004',
      employeeCode: 'SCL-027',
      name: 'Dilini Jayasinghe',
      email: 'dilini@speedcodelabs.com',
      phone: '+94 70 335 9912',
      department: 'Design',
      designation: 'Product Designer',
      avatarUrl: 'https://i.pravatar.cc/150?img=45',
      workStatus: EmployeeWorkStatus.remote,
      checkedInAt: DateTime(now.year, now.month, now.day, 9, 5),
    ),
    Employee(
      id: 'emp-005',
      employeeCode: 'SCL-032',
      name: 'Ravindu Bandara',
      email: 'ravindu@speedcodelabs.com',
      phone: '+94 77 118 6720',
      department: 'Transportation',
      designation: 'Fleet Supervisor',
      avatarUrl: 'https://i.pravatar.cc/150?img=15',
      workStatus: EmployeeWorkStatus.onLeave,
    ),
    Employee(
      id: 'emp-006',
      employeeCode: 'SCL-038',
      name: 'Tharushi Weerasinghe',
      email: 'tharushi@speedcodelabs.com',
      phone: '+94 74 902 3388',
      department: 'Human Resources',
      designation: 'HR Executive',
      avatarUrl: 'https://i.pravatar.cc/150?img=44',
      workStatus: EmployeeWorkStatus.atWork,
      checkedInAt: DateTime(now.year, now.month, now.day, 8, 52),
    ),
    Employee(
      id: 'emp-007',
      employeeCode: 'SCL-041',
      name: 'Sanjaya Kumar',
      email: 'sanjaya@speedcodelabs.com',
      phone: '+94 75 660 1284',
      department: 'Digital Marketing',
      designation: 'SEO Specialist',
      avatarUrl: 'https://i.pravatar.cc/150?img=51',
      workStatus: EmployeeWorkStatus.onLeave,
    ),
    Employee(
      id: 'emp-008',
      employeeCode: 'SCL-046',
      name: 'Ishara Mendis',
      email: 'ishara@speedcodelabs.com',
      phone: '+94 77 218 0044',
      department: 'Engineering',
      designation: 'QA Engineer',
      avatarUrl: 'https://i.pravatar.cc/150?img=48',
      workStatus: EmployeeWorkStatus.atWork,
      checkedInAt: DateTime(now.year, now.month, now.day, 8, 58),
    ),
  ];

  late AttendanceRecord attendance = AttendanceRecord(
    date: now,
    checkIn: DateTime(now.year, now.month, now.day, 8, 47),
    status: AttendanceStatus.working,
    scheduledStart: DateTime(now.year, now.month, now.day, 9),
    scheduledEnd: DateTime(now.year, now.month, now.day, 17, 30),
  );

  late final List<AttendanceDaySummary> attendanceSummary = _buildSummary();

  List<AttendanceDaySummary> _buildSummary() {
    final today = DateTime(now.year, now.month, now.day);
    final previous = <DateTime>[];
    var cursor = today.subtract(const Duration(days: 1));
    while (previous.length < 2) {
      if (cursor.weekday != DateTime.saturday &&
          cursor.weekday != DateTime.sunday) {
        previous.add(cursor);
      }
      cursor = cursor.subtract(const Duration(days: 1));
    }
    previous.sort((a, b) => a.compareTo(b));

    AttendanceDaySummary buildDay(DateTime day) {
      final isToday = day == today;
      final checkIn = DateTime(day.year, day.month, day.day, 8, 55);
      final checkOut = isToday
          ? null
          : DateTime(day.year, day.month, day.day, 17, 42);
      return AttendanceDaySummary(
        label: isToday ? 'Today' : 'Day',
        day: '${day.day}',
        date: day,
        status: isToday
            ? AttendanceStatus.working
            : AttendanceStatus.checkedOut,
        checkIn: isToday ? attendance.checkIn : checkIn,
        checkOut: checkOut,
        workedDuration: checkOut?.difference(checkIn),
      );
    }

    return [...previous.map(buildDay), buildDay(today)];
  }

  final List<Notice> notices = [
    Notice(
      id: 'notice-1',
      title: 'Quarterly performance review schedule',
      description:
          'The Q3 performance review cycle begins next Monday. Please complete your self-assessment form before Friday 5:00 PM. Managers will schedule one-to-one sessions through the HR portal.',
      postedAt: now.subtract(const Duration(hours: 3)),
      author: 'Tharushi Weerasinghe',
      authorDesignation: 'HR Executive',
      authorDepartment: 'Human Resources',
      authorAvatarUrl: 'https://i.pravatar.cc/150?img=44',
      priority: NoticePriority.important,
      hasAttachment: true,
      attachmentName: 'self-assessment-form.pdf',
    ),
    Notice(
      id: 'notice-2',
      title: 'Office closed for Poya Day',
      description:
          'The Colombo office will remain closed on Friday for Poya Day. All client deliverables should be handed over by Thursday evening. Support rotations remain unchanged.',
      postedAt: now.subtract(const Duration(days: 1, hours: 4)),
      author: 'Admin',
      authorDesignation: 'Administration',
      authorDepartment: 'People Operations',
      isRead: true,
    ),
    Notice(
      id: 'notice-3',
      title: 'New expense claim process',
      description:
          'Finance has introduced a new digital expense claim workflow. Receipts must be attached within 14 days of the expense date. Contact finance for training sessions.',
      postedAt: now.subtract(const Duration(days: 3)),
      author: 'Finance Team',
      authorDesignation: 'Finance',
      authorDepartment: 'Finance',
      isRead: true,
    ),
  ];

  final List<AppNotification> notifications = [
    AppNotification(
      id: 'n-1',
      title: 'Task moved to Review',
      message: 'Nethmi moved "Campaign analytics redesign" to Review.',
      createdAt: now.subtract(const Duration(minutes: 25)),
      type: NotificationType.info,
    ),
    AppNotification(
      id: 'n-2',
      title: 'Leave approved',
      message: 'Your casual leave request for next Wednesday was approved.',
      createdAt: now.subtract(const Duration(hours: 2)),
      type: NotificationType.success,
    ),
    AppNotification(
      id: 'n-3',
      title: 'Timesheet reminder',
      message: 'Remember to time out before 6:00 PM today.',
      createdAt: now.subtract(const Duration(hours: 5)),
      isRead: true,
      type: NotificationType.warning,
    ),
    AppNotification(
      id: 'n-4',
      title: 'New notice from admin',
      message: 'Quarterly performance review schedule has been published.',
      createdAt: now.subtract(const Duration(hours: 7)),
      type: NotificationType.info,
    ),
  ];

  final EmployeeStatusSummary employeeStatus = EmployeeStatusSummary(
    atWork: 4,
    onLeave: 2,
    employees: [
      employeeById('emp-002'),
      employeeById('emp-003'),
      employeeById('emp-004'),
      employeeById('emp-005'),
      employeeById('emp-006'),
      employeeById('emp-007'),
      employeeById('emp-008'),
    ],
  );

  static Employee employeeById(String id) => employees.firstWhere(
    (employee) => employee.id == id,
    orElse: () => employees.first,
  );

  final TaskStats taskStats = const TaskStats(
    backlog: 6,
    todo: 12,
    inProgress: 9,
    review: 4,
    done: 19,
  );

  final List<TeamProgress> teamProgress = const [
    TeamProgress(
      name: 'Digital Marketing Team',
      totalTasks: 24,
      completed: 15,
      inProgress: 5,
      color: Color(0xFF3B82F6),
    ),
    TeamProgress(
      name: 'Team A - Transportation',
      totalTasks: 18,
      completed: 9,
      inProgress: 4,
      color: Color(0xFFF59E0B),
    ),
    TeamProgress(
      name: 'Engineering Squad',
      totalTasks: 31,
      completed: 21,
      inProgress: 6,
      color: Color(0xFF8B5CF6),
    ),
    TeamProgress(
      name: 'Design Studio',
      totalTasks: 14,
      completed: 10,
      inProgress: 2,
      color: Color(0xFF10B981),
    ),
  ];

  late final List<TaskItem> tasks = [
    TaskItem(
      id: 'task-001',
      title: 'Campaign analytics redesign',
      description:
          'Rebuild the paid campaign analytics dashboard with channel-level attribution, cohort filters and export to CSV. Align visual language with the new SpeedCode ERP design system.',
      status: TaskStatus.review,
      priority: TaskPriority.high,
      projectName: 'Marketing Intelligence',
      assignee: employeeById('emp-002'),
      dueDate: now.add(const Duration(days: 2)),
      createdAt: now.subtract(const Duration(days: 9)),
      assignedToMe: true,
      assignedBy: 'Nethmi Fernando',
      tags: const ['analytics', 'dashboard'],
      comments: [
        TaskComment(
          id: 'c-1',
          author: employeeById('emp-003'),
          message: 'Attribution data is now available in the events table.',
          createdAt: now.subtract(const Duration(days: 1, hours: 3)),
        ),
        TaskComment(
          id: 'c-2',
          author: employeeById('emp-001'),
          message: 'Reviewing the export flow. Will send notes this afternoon.',
          createdAt: now.subtract(const Duration(hours: 4)),
        ),
      ],
      attachments: const [
        TaskAttachment(
          name: 'analytics-spec.pdf',
          url: 'https://example.com/analytics-spec.pdf',
          size: '1.8 MB',
        ),
        TaskAttachment(
          name: 'dashboard-v2.fig',
          url: 'https://example.com/dashboard-v2.fig',
          size: '6.2 MB',
        ),
      ],
      activity: [
        TaskActivity(
          id: 'a-1',
          message: 'moved task to Review',
          actor: 'Nethmi Fernando',
          createdAt: now.subtract(const Duration(minutes: 25)),
        ),
        TaskActivity(
          id: 'a-2',
          message: 'added 2 attachments',
          actor: 'Nethmi Fernando',
          createdAt: now.subtract(const Duration(days: 1)),
        ),
      ],
    ),
    TaskItem(
      id: 'task-002',
      title: 'Driver mobile onboarding flow',
      description:
          'Design and implement the driver onboarding flow for the transportation team, including document upload, vehicle verification and training checklist.',
      status: TaskStatus.inProgress,
      priority: TaskPriority.urgent,
      projectName: 'Fleet Operations',
      assignee: employeeById('emp-001'),
      dueDate: now.add(const Duration(days: 1)),
      assignedToMe: true,
      createdAt: now.subtract(const Duration(days: 5)),
      assignedBy: 'Nethmi Fernando',
      progress: 0.65,
      tags: const ['mobile', 'fleet'],
      comments: [
        TaskComment(
          id: 'c-3',
          author: employeeById('emp-005'),
          message: 'Vehicle verification API is ready for integration.',
          createdAt: now.subtract(const Duration(hours: 6)),
        ),
      ],
      activity: [
        TaskActivity(
          id: 'a-3',
          message: 'changed status to In progress',
          actor: 'Ayash Perera',
          createdAt: now.subtract(const Duration(days: 2)),
        ),
      ],
    ),
    TaskItem(
      id: 'task-003',
      title: 'Landing page A/B test',
      description:
          'Set up a two-variant landing page test for the enterprise plan. Track conversion, cost per lead and demo bookings for two weeks.',
      status: TaskStatus.todo,
      priority: TaskPriority.medium,
      projectName: 'Growth Experiments',
      assignee: employeeById('emp-007'),
      dueDate: now.add(const Duration(days: 5)),
      createdAt: now.subtract(const Duration(days: 3)),
      tags: const ['growth'],
      comments: [],
    ),
    TaskItem(
      id: 'task-004',
      title: 'Payroll report automation',
      description:
          'Automate the monthly payroll reconciliation report and email it to finance on the 1st of each month.',
      status: TaskStatus.backlog,
      priority: TaskPriority.low,
      projectName: 'Internal Tools',
      assignee: employeeById('emp-003'),
      dueDate: now.add(const Duration(days: 12)),
      createdAt: now.subtract(const Duration(days: 12)),
    ),
    TaskItem(
      id: 'task-005',
      title: 'Attendance widget performance',
      description:
          'Reduce cold-start render time of the attendance widget below 120ms and remove repeated rebuilds.',
      status: TaskStatus.done,
      priority: TaskPriority.medium,
      projectName: 'ERP Core',
      assignee: employeeById('emp-001'),
      dueDate: now.subtract(const Duration(days: 1)),
      assignedToMe: true,
      assignedBy: 'Kavindu Silva',
      createdAt: now.subtract(const Duration(days: 14)),
      tags: const ['performance'],
    ),
    TaskItem(
      id: 'task-006',
      title: 'Quarterly brand assets',
      description:
          'Prepare the updated social media kit for Q3 including Poya Day and Independence Day variants.',
      status: TaskStatus.inProgress,
      priority: TaskPriority.high,
      projectName: 'Brand Refresh',
      assignee: employeeById('emp-004'),
      dueDate: now.add(const Duration(days: 4)),
      tags: const ['design', 'brand'],
      createdAt: now.subtract(const Duration(days: 6)),
    ),
    TaskItem(
      id: 'task-007',
      title: 'Employee handbook update',
      description:
          'Update leave policy, remote work guidelines and the new expense claim process in the employee handbook.',
      status: TaskStatus.todo,
      priority: TaskPriority.medium,
      projectName: 'People Operations',
      assignee: employeeById('emp-006'),
      dueDate: now.add(const Duration(days: 8)),
      createdAt: now.subtract(const Duration(days: 4)),
    ),
    TaskItem(
      id: 'task-008',
      title: 'Regression suite for chat',
      description:
          'Add widget and integration coverage for attachments, delivery states and conversation search.',
      status: TaskStatus.inProgress,
      priority: TaskPriority.high,
      projectName: 'ERP Core',
      assignee: employeeById('emp-008'),
      dueDate: now.add(const Duration(days: 3)),
      assignedToMe: true,
      assignedBy: 'Kavindu Silva',
      progress: 0.4,
      createdAt: now.subtract(const Duration(days: 7)),
    ),
    TaskItem(
      id: 'task-009',
      title: 'Client onboarding checklist',
      description:
          'Standardise the client onboarding checklist and add automated reminders for missing documents.',
      status: TaskStatus.review,
      priority: TaskPriority.medium,
      projectName: 'Client Success',
      assignee: employeeById('emp-002'),
      dueDate: now.add(const Duration(days: 6)),
      createdAt: now.subtract(const Duration(days: 10)),
    ),
    TaskItem(
      id: 'task-010',
      title: 'Vehicle maintenance reminders',
      description:
          'Send push reminders 500km before the next scheduled service and log completion against each vehicle.',
      status: TaskStatus.done,
      priority: TaskPriority.low,
      projectName: 'Fleet Operations',
      assignee: employeeById('emp-005'),
      dueDate: now.subtract(const Duration(days: 2)),
      createdAt: now.subtract(const Duration(days: 20)),
    ),
  ];

  final Map<String, List<ChatMessage>> messages = {
    'conv-1': [
      ChatMessage(
        id: 'm-1',
        senderId: 'emp-002',
        senderName: 'Nethmi Fernando',
        text:
            'Good morning! Did you get a chance to look at the campaign screens?',
        createdAt: now.subtract(const Duration(hours: 3, minutes: 20)),
        isMine: false,
      ),
      ChatMessage(
        id: 'm-2',
        senderId: 'emp-001',
        senderName: 'Ayash Perera',
        text:
            'Yes, the layout looks great. I left two comments on the export flow.',
        createdAt: now.subtract(const Duration(hours: 3, minutes: 5)),
        isMine: true,
        status: MessageDeliveryStatus.read,
      ),
      ChatMessage(
        id: 'm-3',
        senderId: 'emp-002',
        senderName: 'Nethmi Fernando',
        text: 'Perfect, I will update them before the review call.',
        createdAt: now.subtract(const Duration(hours: 2, minutes: 50)),
        isMine: false,
      ),
      ChatMessage(
        id: 'm-4',
        senderId: 'emp-002',
        senderName: 'Nethmi Fernando',
        text: 'Can you join at 3 PM?',
        createdAt: now.subtract(const Duration(minutes: 38)),
        isMine: false,
      ),
    ],
    'conv-2': [
      ChatMessage(
        id: 'm-5',
        senderId: 'emp-003',
        senderName: 'Kavindu Silva',
        text:
            'Deployed the attendance API to staging. The timeout reason field is optional as agreed.',
        createdAt: now.subtract(const Duration(hours: 5)),
        isMine: false,
      ),
      ChatMessage(
        id: 'm-6',
        senderId: 'emp-001',
        senderName: 'Ayash Perera',
        text: 'Great. I will wire the mobile dropdown and test it today.',
        createdAt: now.subtract(const Duration(hours: 4, minutes: 44)),
        isMine: true,
        status: MessageDeliveryStatus.read,
      ),
    ],
    'conv-3': [
      ChatMessage(
        id: 'm-7',
        senderId: 'emp-004',
        senderName: 'Dilini Jayasinghe',
        text: 'Shared the Q3 brand kit in the Design folder.',
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
        isMine: false,
      ),
      ChatMessage(
        id: 'm-8',
        senderId: 'emp-001',
        senderName: 'Ayash Perera',
        text: 'Thanks! The social templates look excellent.',
        createdAt: now.subtract(const Duration(days: 1, hours: 1)),
        isMine: true,
        status: MessageDeliveryStatus.read,
      ),
    ],
    'conv-group': [
      ChatMessage(
        id: 'm-9',
        senderId: 'emp-006',
        senderName: 'Tharushi Weerasinghe',
        text: 'Reminder: self-assessment forms are due Friday.',
        createdAt: now.subtract(const Duration(hours: 8)),
        isMine: false,
      ),
      ChatMessage(
        id: 'm-10',
        senderId: 'emp-003',
        senderName: 'Kavindu Silva',
        text: 'Noted. I will submit mine tomorrow.',
        createdAt: now.subtract(const Duration(hours: 7, minutes: 30)),
        isMine: false,
      ),
    ],
  };

  final List<Conversation> conversations = [
    Conversation(
      id: 'conv-1',
      title: 'Nethmi Fernando',
      participants: [employeeById('emp-002')],
      lastMessage: 'Can you join at 3 PM?',
      lastMessageAt: now.subtract(const Duration(minutes: 38)),
      unreadCount: 2,
      isOnline: true,
      pinned: true,
    ),
    Conversation(
      id: 'conv-2',
      title: 'Kavindu Silva',
      participants: [employeeById('emp-003')],
      lastMessage: 'Deployed the attendance API to staging.',
      lastMessageAt: now.subtract(const Duration(hours: 5)),
      isOnline: true,
    ),
    Conversation(
      id: 'conv-3',
      title: 'Dilini Jayasinghe',
      participants: [employeeById('emp-004')],
      lastMessage: 'Shared the Q3 brand kit in the Design folder.',
      lastMessageAt: now.subtract(const Duration(days: 1, hours: 2)),
      isOnline: false,
    ),
    Conversation(
      id: 'conv-group',
      title: 'ERP Core Team',
      participants: [
        employeeById('emp-003'),
        employeeById('emp-008'),
        employeeById('emp-006'),
      ],
      lastMessage: 'Kavindu: Noted. I will submit mine tomorrow.',
      lastMessageAt: now.subtract(const Duration(hours: 7)),
      isGroup: true,
      unreadCount: 5,
    ),
    Conversation(
      id: 'conv-4',
      title: 'Tharushi Weerasinghe',
      participants: [employeeById('emp-006')],
      lastMessage: 'Your leave request has been approved.',
      lastMessageAt: now.subtract(const Duration(days: 2)),
      isOnline: false,
    ),
  ];

  late final List<Meeting> meetings = [
    Meeting(
      id: 'meet-1',
      title: 'Daily engineering stand-up',
      host: 'Kavindu Silva',
      startsAt: now.add(const Duration(minutes: 35)),
      endsAt: now.add(const Duration(minutes: 50)),
      description:
          'Quick sync on sprint progress, blockers and today\'s release checklist.',
      status: MeetingStatus.upcoming,
      meetingUrl: 'https://meet.google.com/scl-standup',
      attendees: 8,
    ),
    Meeting(
      id: 'meet-2',
      title: 'Campaign review with marketing',
      host: 'Nethmi Fernando',
      startsAt: now.subtract(const Duration(minutes: 10)),
      endsAt: now.add(const Duration(minutes: 50)),
      description:
          'Walk through the campaign analytics redesign and finalise the export flow.',
      status: MeetingStatus.live,
      meetingUrl: 'https://meet.google.com/scl-campaign',
      attendees: 5,
    ),
    Meeting(
      id: 'meet-3',
      title: 'Monthly all-hands',
      host: 'Tharushi Weerasinghe',
      startsAt: now.add(const Duration(days: 2, hours: 2)),
      endsAt: now.add(const Duration(days: 2, hours: 3)),
      description:
          'Company update, quarterly priorities and open Q&A with leadership.',
      status: MeetingStatus.upcoming,
      meetingUrl: 'https://zoom.us/j/scl-allhands',
      attendees: 42,
      isExternal: true,
    ),
    Meeting(
      id: 'meet-4',
      title: 'Sprint retrospective',
      host: 'Ayash Perera',
      startsAt: now.subtract(const Duration(days: 2)),
      endsAt: now.subtract(const Duration(days: 2, hours: -1)),
      description: 'Sprint 14 retro and action items.',
      status: MeetingStatus.completed,
      attendees: 9,
    ),
    Meeting(
      id: 'meet-5',
      title: 'Design critique',
      host: 'Dilini Jayasinghe',
      startsAt: now.subtract(const Duration(days: 4)),
      endsAt: now.subtract(const Duration(days: 4, hours: -1)),
      description: 'Reviewed the new employee profile and settings screens.',
      status: MeetingStatus.completed,
      attendees: 4,
    ),
  ];

  late final LeaveBalance leaveBalance = const LeaveBalance(
    annualTotal: 21,
    annualUsed: 8,
    casualTotal: 10,
    casualUsed: 4,
    sickTotal: 7,
    sickUsed: 2,
  );

  late final List<LeaveRequest> leaveRequests = [
    LeaveRequest(
      id: 'leave-1',
      type: LeaveType.casual,
      startDate: now.add(const Duration(days: 6)),
      endDate: now.add(const Duration(days: 6)),
      days: 1,
      reason: 'Personal banking appointment in the afternoon.',
      status: LeaveStatus.approved,
      appliedAt: now.subtract(const Duration(days: 2)),
      reviewedBy: 'Tharushi Weerasinghe',
      reviewNote: 'Approved. Please hand over the release checklist.',
    ),
    LeaveRequest(
      id: 'leave-2',
      type: LeaveType.annual,
      startDate: now.add(const Duration(days: 18)),
      endDate: now.add(const Duration(days: 22)),
      days: 5,
      reason: 'Family holiday planned earlier this year.',
      status: LeaveStatus.pending,
      appliedAt: now.subtract(const Duration(hours: 20)),
    ),
    LeaveRequest(
      id: 'leave-3',
      type: LeaveType.sick,
      startDate: now.subtract(const Duration(days: 12)),
      endDate: now.subtract(const Duration(days: 11)),
      days: 2,
      reason: 'Flu with medical certificate attached.',
      status: LeaveStatus.approved,
      appliedAt: now.subtract(const Duration(days: 13)),
      reviewedBy: 'Tharushi Weerasinghe',
      attachmentName: 'medical-certificate.pdf',
    ),
    LeaveRequest(
      id: 'leave-4',
      type: LeaveType.unpaid,
      startDate: now.subtract(const Duration(days: 34)),
      endDate: now.subtract(const Duration(days: 34)),
      days: 1,
      reason: 'Personal matter.',
      status: LeaveStatus.rejected,
      appliedAt: now.subtract(const Duration(days: 36)),
      reviewedBy: 'Tharushi Weerasinghe',
      reviewNote: 'Rejected due to a scheduled client release. Please reapply.',
    ),
  ];

  late final List<CalendarEvent> events = _buildEvents();

  List<CalendarEvent> _buildEvents() {
    final today = DateTime(now.year, now.month, now.day);
    return [
      CalendarEvent(
        id: 'e-1',
        title: 'Daily stand-up',
        date: today,
        type: CalendarEventType.meeting,
        description: 'Engineering daily sync at 9:30 AM.',
        startTime: '09:30',
        endTime: '09:45',
        location: 'Google Meet',
      ),
      CalendarEvent(
        id: 'e-2',
        title: 'Campaign review',
        date: today,
        type: CalendarEventType.company,
        description: 'Walk through the analytics redesign with marketing.',
        startTime: '15:00',
        endTime: '15:45',
        location: 'Meeting room - Orchid',
      ),
      CalendarEvent(
        id: 'e-3',
        title: 'Poya Day holiday',
        date: DateTime(now.year, now.month, now.day + 3),
        type: CalendarEventType.holiday,
        description: 'Office closed. Support rotation remains active.',
      ),
      CalendarEvent(
        id: 'e-4',
        title: 'Nethmi on leave',
        date: DateTime(now.year, now.month, now.day + 5),
        type: CalendarEventType.leave,
        description: 'Approved annual leave.',
      ),
      CalendarEvent(
        id: 'e-5',
        title: 'Monthly all-hands',
        date: DateTime(now.year, now.month, now.day + 2),
        type: CalendarEventType.company,
        description: 'Company update and Q&A with leadership.',
        startTime: '11:00',
        endTime: '12:00',
        location: 'Main auditorium',
      ),
      CalendarEvent(
        id: 'e-6',
        title: 'Sprint 15 planning',
        date: DateTime(now.year, now.month, now.day + 7),
        type: CalendarEventType.meeting,
        description: 'Sprint planning and capacity allocation.',
        startTime: '10:00',
        endTime: '11:30',
      ),
      CalendarEvent(
        id: 'e-7',
        title: 'Design critique',
        date: DateTime(now.year, now.month, now.day + 9),
        type: CalendarEventType.personal,
        description: 'Review employee profile and settings screens.',
        startTime: '14:00',
        location: 'Design studio',
        createdByMe: true,
      ),
      CalendarEvent(
        id: 'e-8',
        title: 'Independence Day',
        date: DateTime(now.year, now.month, now.day + 14),
        type: CalendarEventType.holiday,
        description: 'Public holiday.',
      ),
    ];
  }

  late final List<CompanyEvent> companyEvents = [
    CompanyEvent(
      id: 'event-1',
      title: 'Product innovation workshop',
      date: DateTime(now.year, now.month, now.day + 4),
      category: EventCategory.workshop,
      description:
          'A hands-on session for product, engineering and design to explore ideas for the next ERP release. Teams will pitch concepts and leave with a validated action plan.',
      startTime: '09:30',
      endTime: '12:30',
      location: 'Innovation Lab, Level 3',
      organizer: 'Dilini Jayasinghe',
      organizerDepartment: 'Design',
      status: EventStatus.upcoming,
      registrationEnabled: true,
      participantCount: 18,
      participants: [
        employeeById('emp-001'),
        employeeById('emp-003'),
        employeeById('emp-004'),
        employeeById('emp-008'),
      ],
      instructions:
          'Bring a laptop and one customer problem you want to solve. Lunch will be provided.',
    ),
    CompanyEvent(
      id: 'event-2',
      title: 'Monthly all-hands',
      date: DateTime(now.year, now.month, now.day + 2),
      category: EventCategory.townHall,
      description:
          'Company update covering quarterly priorities, customer wins and an open Q&A with leadership.',
      startTime: '11:00',
      endTime: '12:00',
      location: 'Main auditorium',
      organizer: 'Tharushi Weerasinghe',
      organizerDepartment: 'Human Resources',
      status: EventStatus.upcoming,
      registrationEnabled: false,
      participantCount: 64,
      participants: [
        employeeById('emp-002'),
        employeeById('emp-005'),
        employeeById('emp-006'),
      ],
      instructions: 'Remote employees can join through the live meeting link.',
    ),
    CompanyEvent(
      id: 'event-3',
      title: 'Engineering knowledge share',
      date: DateTime(now.year, now.month, now.day),
      category: EventCategory.training,
      description:
          'Practical patterns for resilient Flutter applications, followed by an open discussion on testing and release automation.',
      startTime: '15:00',
      endTime: '16:00',
      location: 'Meeting room - Orchid',
      organizer: 'Kavindu Silva',
      organizerDepartment: 'Engineering',
      status: EventStatus.ongoing,
      registrationEnabled: true,
      registered: true,
      participantCount: 22,
      participants: [
        employeeById('emp-001'),
        employeeById('emp-003'),
        employeeById('emp-008'),
      ],
    ),
    CompanyEvent(
      id: 'event-4',
      title: 'New joiners welcome breakfast',
      date: DateTime(now.year, now.month, now.day - 8),
      category: EventCategory.celebration,
      description:
          'A relaxed breakfast to welcome the newest members of the SpeedCode Labs team.',
      startTime: '08:30',
      endTime: '09:30',
      location: 'Rooftop cafe',
      organizer: 'Tharushi Weerasinghe',
      organizerDepartment: 'Human Resources',
      status: EventStatus.completed,
      participantCount: 31,
      participants: [
        employeeById('emp-002'),
        employeeById('emp-006'),
        employeeById('emp-007'),
      ],
    ),
    CompanyEvent(
      id: 'event-5',
      title: 'Inter-department cricket match',
      date: DateTime(now.year, now.month, now.day + 16),
      category: EventCategory.sports,
      description:
          'Engineering takes on Marketing in the annual friendly cricket match. Families and colleagues are welcome to cheer from the sidelines.',
      startTime: '14:00',
      endTime: '18:00',
      location: 'Colombo Oval',
      organizer: 'Sanjaya Kumar',
      organizerDepartment: 'Digital Marketing',
      status: EventStatus.upcoming,
      registrationEnabled: true,
      participantCount: 26,
      participants: [
        employeeById('emp-002'),
        employeeById('emp-003'),
        employeeById('emp-007'),
      ],
      instructions:
          'Players should arrive by 1:15 PM. Sportswear and water bottles are recommended.',
    ),
    CompanyEvent(
      id: 'event-6',
      title: 'Quarterly planning offsite',
      date: DateTime(now.year, now.month, now.day + 9),
      category: EventCategory.meeting,
      description:
          'Leadership planning session for next quarter. Attendance is limited to department leads.',
      startTime: '09:00',
      endTime: '17:00',
      location: 'Hilton Colombo',
      organizer: 'Ayash Perera',
      organizerDepartment: 'Engineering',
      status: EventStatus.cancelled,
      registrationEnabled: false,
      participantCount: 12,
      participants: [
        employeeById('emp-001'),
        employeeById('emp-002'),
        employeeById('emp-006'),
      ],
    ),
  ];

  late final List<SharedFile> sharedFiles = [
    SharedFile(
      id: 'f-1',
      name: 'Q3 Marketing Report.pdf',
      category: FileCategory.documents,
      sizeLabel: '2.4 MB',
      uploadedAt: now.subtract(const Duration(hours: 5)),
      owner: 'Nethmi Fernando',
      url: 'https://example.com/q3-marketing-report.pdf',
      description: 'Campaign performance and channel attribution summary.',
    ),
    SharedFile(
      id: 'f-2',
      name: 'Campaign Budget 2026.xlsx',
      category: FileCategory.spreadsheets,
      sizeLabel: '860 KB',
      uploadedAt: now.subtract(const Duration(days: 1)),
      owner: 'Nethmi Fernando',
      url: 'https://example.com/campaign-budget.xlsx',
      description: 'Approved budget allocations by channel.',
    ),
    SharedFile(
      id: 'f-3',
      name: 'Brand Guidelines v4.pdf',
      category: FileCategory.documents,
      sizeLabel: '12.8 MB',
      uploadedAt: now.subtract(const Duration(days: 3)),
      owner: 'Dilini Jayasinghe',
      url: 'https://example.com/brand-guidelines.pdf',
      description: 'Logo usage, colour tokens and typography.',
    ),
    SharedFile(
      id: 'f-4',
      name: 'Employee Handbook 2026.docx',
      category: FileCategory.documents,
      sizeLabel: '1.1 MB',
      uploadedAt: now.subtract(const Duration(days: 4)),
      owner: 'Tharushi Weerasinghe',
      url: 'https://example.com/employee-handbook.docx',
      description: 'Policies, leave rules and benefits.',
    ),
    SharedFile(
      id: 'f-5',
      name: 'Fleet Dashboard Mockup.png',
      category: FileCategory.images,
      sizeLabel: '3.6 MB',
      uploadedAt: now.subtract(const Duration(days: 2)),
      owner: 'Dilini Jayasinghe',
      url: 'https://example.com/fleet-dashboard.png',
      description: 'High fidelity dashboard concept.',
    ),
    SharedFile(
      id: 'f-6',
      name: 'Q3 All-hands Deck.pptx',
      category: FileCategory.presentations,
      sizeLabel: '8.2 MB',
      uploadedAt: now.subtract(const Duration(days: 6)),
      owner: 'Tharushi Weerasinghe',
      url: 'https://example.com/q3-all-hands.pptx',
      description: 'Company update and quarterly priorities.',
      allowDownload: false,
    ),
    SharedFile(
      id: 'f-7',
      name: 'Release Notes 4.2.txt',
      category: FileCategory.other,
      sizeLabel: '24 KB',
      uploadedAt: now.subtract(const Duration(hours: 9)),
      owner: 'Kavindu Silva',
      url: 'https://example.com/release-notes.txt',
      description: 'ERP 4.2 changelog.',
    ),
  ];

  late final SummaryData summary = SummaryData(
    employee: currentUser,
    totalWorkingDays: 22,
    presentDays: 19,
    absentDays: 1,
    leaveDays: 2,
    totalHours: 168.5,
    overtimeHours: 6.5,
    tasksAssigned: 18,
    tasksCompleted: 14,
    projects: const ['ERP Core', 'Fleet Operations', 'Marketing Intelligence'],
    weeklyHours: const [7.4, 8.1, 7.8, 8.6, 7.9, 0, 0],
    monthlyAttendance: const [
      AttendancePoint('W1', 5, 0),
      AttendancePoint('W2', 5, 0),
      AttendancePoint('W3', 4, 1),
      AttendancePoint('W4', 5, 0),
    ],
    taskDistribution: const {
      'Backlog': 2,
      'To do': 3,
      'In progress': 4,
      'Review': 3,
      'Done': 6,
    },
  );

  late final List<EmailMessage> emails = [
    EmailMessage(
      id: 'mail-1',
      from: 'Tharushi Weerasinghe',
      to: 'ayash@speedcodelabs.com',
      subject: 'Performance review self-assessment',
      body:
          'Hi Ayash,\n\nThe Q3 performance review cycle is now open. Please complete your self-assessment form before Friday at 5:00 PM so your manager can prepare for the one-to-one session.\n\nLet me know if you need any support.\n\nBest,\nTharushi',
      sentAt: now.subtract(const Duration(hours: 2)),
      folder: MailFolder.inbox,
      isRead: false,
    ),
    EmailMessage(
      id: 'mail-2',
      from: 'Nethmi Fernando',
      to: 'ayash@speedcodelabs.com',
      subject: 'Campaign review notes',
      body:
          'Hi Ayash,\n\nAttached are the notes from today\'s campaign review. The main open item is the CSV export flow. I have added comments in Figma.\n\nThanks,\nNethmi',
      sentAt: now.subtract(const Duration(hours: 6)),
      folder: MailFolder.inbox,
      attachments: const [
        EmailAttachment(name: 'campaign-review-notes.pdf', sizeLabel: '420 KB'),
      ],
    ),
    EmailMessage(
      id: 'mail-3',
      from: 'Finance Team',
      to: 'all-staff@speedcodelabs.com',
      subject: 'July expense claims deadline',
      body:
          'Dear team,\n\nJuly expense claims must be submitted by the 5th of August. Please attach all receipts to avoid delays in reimbursement.\n\nFinance Team',
      sentAt: now.subtract(const Duration(days: 1, hours: 3)),
      folder: MailFolder.inbox,
      isRead: true,
    ),
    EmailMessage(
      id: 'mail-4',
      from: 'Ayash Perera',
      to: 'Kavindu Silva',
      subject: 'Attendance API integration',
      body:
          'Hi Kavindu,\n\nThe mobile app is now using the staging attendance API. The timeout reason is passed as optional. I will share test results tomorrow.\n\nThanks,\nAyash',
      sentAt: now.subtract(const Duration(days: 1)),
      folder: MailFolder.sent,
      isRead: true,
    ),
    EmailMessage(
      id: 'mail-5',
      from: 'Ayash Perera',
      to: 'Dilini Jayasinghe',
      subject: 'Profile screen feedback',
      body:
          'Hi Dilini,\n\nI have drafted feedback on the profile screen. I will finish the notes and send them across tomorrow.',
      sentAt: now.subtract(const Duration(hours: 9)),
      folder: MailFolder.drafts,
    ),
  ];
}
