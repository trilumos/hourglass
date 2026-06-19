import 'session_record.dart';

/// Serializes focus history to CSV (user-initiated export). Pure: no I/O.
/// Columns: startedAt (ISO-8601), mode, plannedMinutes, focusedMinutes,
/// completed, abandoned, intention. Intention is CSV-escaped.
String sessionsToCsv(List<SessionRecord> sessions) {
  final buf = StringBuffer(
      'startedAt,mode,plannedMinutes,focusedMinutes,completed,abandoned,intention\n');
  String mins(Duration d) => (d.inSeconds / 60).toStringAsFixed(1);
  for (final s in sessions) {
    final row = [
      s.startedAt.toIso8601String(),
      s.mode.name,
      mins(s.plannedDuration),
      mins(s.recordedFocus),
      s.completed.toString(),
      s.abandoned.toString(),
      _esc(s.intention),
    ];
    buf.writeln(row.join(','));
  }
  return buf.toString();
}

/// Quote a field if it contains a comma, quote, or newline; double inner quotes.
String _esc(String field) {
  if (field.contains(',') ||
      field.contains('"') ||
      field.contains('\n') ||
      field.contains('\r')) {
    return '"${field.replaceAll('"', '""')}"';
  }
  return field;
}
