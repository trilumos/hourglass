import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/app/providers.dart';
import 'package:hourglass/domain/personal_bests.dart';
import 'package:hourglass/domain/session_mode.dart';
import 'package:hourglass/ui/insights_pdf.dart';

void main() {
  test('buildInsightsReportBytes produces a valid, non-trivial PDF', () async {
    final bytes = await buildInsightsReportBytes(
      name: 'Deep',
      now: DateTime(2026, 6, 20),
      score: 72,
      stats: const ProfileStats(
        totalFocus: Duration(hours: 12, minutes: 30),
        streak: 5,
        sessionsCompleted: 18,
        weekFocus: Duration(hours: 3),
        bestStreak: 9,
        avgSession: Duration(minutes: 41),
        longestSession: Duration(minutes: 92),
        totalSessions: 22,
        firstDate: null,
      ),
      bests: const PersonalBests(
        bestDayFocus: Duration(hours: 2, minutes: 10),
        bestDayDate: null,
        longestSession: Duration(minutes: 92),
        longestSessionDate: null,
        bestStreak: 9,
        highestFocusScore: 81,
        focusingSince: null,
      ),
      byMode: const {
        SessionMode.flowBlock: Duration(hours: 8),
        SessionMode.pomodoro: Duration(hours: 3),
        SessionMode.custom: Duration(hours: 1, minutes: 30),
      },
      last14: List.filled(14, const Duration(minutes: 30)),
      activeDays30: 12,
    );

    // %PDF magic header + a real document body.
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(1000));
  });

  test('handles an empty/zero history without throwing', () async {
    final bytes = await buildInsightsReportBytes(
      name: '',
      now: DateTime(2026, 6, 20),
      score: 0,
      stats: ProfileStats.empty,
      bests: const PersonalBests(
        bestDayFocus: null,
        bestDayDate: null,
        longestSession: null,
        longestSessionDate: null,
        bestStreak: 0,
        highestFocusScore: null,
        focusingSince: null,
      ),
      byMode: const {},
      last14: List.filled(14, Duration.zero),
      activeDays30: 0,
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });
}
