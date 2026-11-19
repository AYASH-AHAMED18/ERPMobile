/// Canonical relative routes for the SpeedCode Labs ERP API.
///
/// These are the only places endpoint paths are declared. When the production
/// backend is connected, update this file (and the API repositories) rather
/// than the UI layer.
abstract final class ApiEndpoints {
  static const login = '/auth/login';
  static const logout = '/auth/logout';
  static const refresh = '/auth/refresh';
  static const me = '/auth/me';
  static const changePassword = '/auth/change-password';
  static const updateProfile = '/employees/me';

  static const dashboard = '/dashboard';
  static const notices = '/notices';
  static const notifications = '/notifications';

  static const attendanceToday = '/attendance/today';
  static const attendanceSummary = '/attendance/summary';
  static const attendanceTimeIn = '/attendance/time-in';
  static const attendanceTimeOut = '/attendance/time-out';

  static const tasks = '/tasks';
  static const taskStats = '/tasks/stats';
  static const teamProgress = '/tasks/team-progress';
  static const employeesStatus = '/employees/status';

  static const conversations = '/chat/conversations';
  static const meetings = '/live/meetings';
  static const leaveRequests = '/leave/requests';
  static const leaveBalance = '/leave/balance';
  static const calendarEvents = '/calendar/events';
  static const sharedFiles = '/sharing/files';
  static const summary = '/summary/me';
  static const mailbox = '/mailbox';
  static const sendMail = '/mailbox/send';

  static String task(String id) => '/tasks/$id';
  static String taskComments(String id) => '/tasks/$id/comments';
  static String conversation(String id) => '/chat/conversations/$id';
  static String messages(String id) => '/chat/conversations/$id/messages';
  static String leave(String id) => '/leave/requests/$id';
  static String email(String id) => '/mailbox/$id';
}
