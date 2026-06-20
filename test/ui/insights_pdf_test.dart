import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/domain/focus_report.dart';
import 'package:hourglass/domain/session_mode.dart';
import 'package:hourglass/domain/session_record.dart';
import 'package:hourglass/ui/insights_pdf.dart';

SessionRecord rec(
  DateTime at, {
  SessionMode mode = SessionMode.flowBlock,
  int focusMin = 25,
  int plannedMin = 25,
  bool completed = true,
  bool abandoned = false,
  String intention = 'write the report',
}) =>
    SessionRecord(
      id: 0,
      startedAt: at,
      mode: mode,
      intention: intention,
      plannedDuration: Duration(minutes: plannedMin),
      recordedFocus: Duration(minutes: focusMin),
      completed: completed,
      abandoned: abandoned,
      autoContinue: false,
      soundscape: 'sand',
      skinId: 'classic',
      planJson: null,
    );

void main() {
  final now = DateTime(2026, 6, 20, 12);

  test('FocusReportData.from derives lifetime metrics from the session list', () {
    final sessions = [
      rec(DateTime(2026, 6, 18, 9), focusMin: 25),
      rec(DateTime(2026, 6, 19, 9), focusMin: 50, plannedMin: 50),
      rec(DateTime(2026, 6, 20, 8), focusMin: 30, mode: SessionMode.pomodoro),
    ];
    final d = FocusReportData.from(
        sessions: sessions, now: now, name: 'Deep', isPro: true);

    expect(d.totalSessions, 3);
    expect(d.totalFocus, const Duration(minutes: 105));
    expect(d.activeDaysTotal, 3);
    expect(d.currentStreak, 3); // 18,19,20 ending today
    expect(d.last14Strip.length, 14);
    expect(d.modeStats.length, 2); // Flow + Pomodoro
    expect(d.focusScore, isNotNull); // has qualifying Flow sessions
  });

  test('cold-start (one session) is honest: no Flow score, no fabricated rate', () {
    final d = FocusReportData.from(
      sessions: [rec(DateTime(2026, 6, 20, 9), mode: SessionMode.custom)],
      now: now,
      name: '',
      isPro: false,
    );
    expect(d.totalSessions, 1);
    expect(d.focusScore, isNull); // Custom only → no Flow score
    expect(d.completionRate, isNull); // < 3 sessions
    expect(d.intentionThemes, isNull); // < 5 intentions
  });

  test('buildFocusReportBytes produces a valid PDF for a rich history', () async {
    final sessions = [
      for (var i = 30; i >= 0; i--)
        rec(now.subtract(Duration(days: i, hours: 3)),
            focusMin: 20 + (i % 4) * 15),
      for (var i = 10; i >= 0; i--)
        rec(now.subtract(Duration(days: i * 5)),
            mode: SessionMode.pomodoro, focusMin: 25),
    ];
    final d = FocusReportData.from(
        sessions: sessions, now: now, name: 'Deep', isPro: true);
    final bytes = await buildFocusReportBytes(d);

    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(2000));
  });

  test('builds a valid PDF for a single cold-start session', () async {
    final d = FocusReportData.from(
      sessions: [rec(DateTime(2026, 6, 20, 9))],
      now: now,
      name: '',
      isPro: false,
    );
    final bytes = await buildFocusReportBytes(d);
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });
}
