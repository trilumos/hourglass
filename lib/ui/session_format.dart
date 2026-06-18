import '../domain/session_mode.dart';

/// Small shared formatters for the history + summary screens.

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String modeLabel(SessionMode m) => switch (m) {
      SessionMode.flowBlock => 'Flow Block',
      SessionMode.pomodoro => 'Pomodoro',
      SessionMode.custom => 'Custom',
    };

/// "25m", "1h", "1h 5m", or "<1m" for a recorded-but-sub-minute session.
String formatFocusDuration(Duration d) {
  if (d.inSeconds <= 0) return '0m';
  if (d.inMinutes <= 0) return '<1m';
  final h = d.inHours;
  final m = d.inMinutes % 60;
  if (h == 0) return '${m}m';
  if (m == 0) return '${h}h';
  return '${h}h ${m}m';
}

/// "9:05 AM" — 12-hour clock, no intl dependency.
String formatClock(DateTime d) {
  final ampm = d.hour < 12 ? 'AM' : 'PM';
  var h = d.hour % 12;
  if (h == 0) h = 12;
  return '$h:${d.minute.toString().padLeft(2, '0')} $ampm';
}

String formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

/// "Today" / "Yesterday" / "12 Jun 2026" for a day grouping header.
String dayHeading(DateTime d, DateTime now) {
  DateTime only(DateTime x) => DateTime(x.year, x.month, x.day);
  final diff = only(now).difference(only(d)).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return formatDate(d);
}
