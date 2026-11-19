import 'package:intl/intl.dart';

abstract final class AppDate {
  static final _time = DateFormat('hh:mm a');
  static final _shortTime = DateFormat('HH:mm');
  static final _day = DateFormat('EEE, dd MMM');
  static final _full = DateFormat('EEEE, dd MMMM yyyy');
  static final _monthYear = DateFormat('MMMM yyyy');
  static final _shortDate = DateFormat('dd MMM yyyy');
  static final _messageTime = DateFormat('hh:mm a');
  static final _relativeDate = DateFormat('MMM d');

  static String time(DateTime? value) =>
      value == null ? '--:--' : _time.format(value);
  static String shortTime(DateTime? value) =>
      value == null ? '--:--' : _shortTime.format(value);
  static String day(DateTime value) => _day.format(value);
  static String full(DateTime value) => _full.format(value);
  static String monthYear(DateTime value) => _monthYear.format(value);
  static String shortDate(DateTime value) => _shortDate.format(value);
  static String messageTime(DateTime value) => _messageTime.format(value);
  static String relativeDate(DateTime value) => _relativeDate.format(value);

  static String greeting([DateTime? now]) {
    final hour = (now ?? DateTime.now()).hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static String duration(Duration value) {
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60);
    if (hours == 0) return '${minutes}m';
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }

  static String relativeTime(DateTime value) {
    final now = DateTime.now();
    final diff = now.difference(value);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return shortDate(value);
  }

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
