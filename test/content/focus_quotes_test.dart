import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/content/focus_quotes.dart';

void main() {
  group('segmentFor / greetingFor', () {
    test('maps boundary hours to the right segment', () {
      expect(segmentFor(DateTime(2026, 6, 15, 5)), TimeSegment.morning);
      expect(segmentFor(DateTime(2026, 6, 15, 11, 59)), TimeSegment.morning);
      expect(segmentFor(DateTime(2026, 6, 15, 12)), TimeSegment.afternoon);
      expect(segmentFor(DateTime(2026, 6, 15, 16, 59)), TimeSegment.afternoon);
      expect(segmentFor(DateTime(2026, 6, 15, 17)), TimeSegment.evening);
      expect(segmentFor(DateTime(2026, 6, 15, 21, 59)), TimeSegment.evening);
      expect(segmentFor(DateTime(2026, 6, 15, 22)), TimeSegment.lateNight);
      expect(segmentFor(DateTime(2026, 6, 15, 0)), TimeSegment.lateNight);
      expect(segmentFor(DateTime(2026, 6, 15, 4, 59)), TimeSegment.lateNight);
    });

    test('greeting candidates include a time-appropriate option', () {
      final morning =
          greetingCandidates(DateTime(2026, 6, 15, 8), isNewUser: false);
      expect(morning, contains('Good morning'));
      expect(morning, contains('Welcome back')); // any-time openers included
      final night =
          greetingCandidates(DateTime(2026, 6, 15, 1), isNewUser: false);
      expect(night, contains('Burning the midnight oil'));
    });

    test('new users get the welcome set only', () {
      final c = greetingCandidates(DateTime(2026, 6, 15, 8), isNewUser: true);
      expect(c, contains('Welcome'));
      expect(c, isNot(contains('Good morning')));
    });

    test('streak >= 2 adds the streak greeting for returning users', () {
      final c = greetingCandidates(DateTime(2026, 6, 15, 8),
          isNewUser: false, streak: 3);
      expect(c, contains('Keep the streak alive'));
    });
  });

  group('catalog integrity', () {
    test('every segment has lines and no line is empty', () {
      for (final segment in TimeSegment.values) {
        final lines = kEncouragements[segment];
        expect(lines, isNotNull, reason: '$segment missing');
        expect(lines!, isNotEmpty, reason: '$segment empty');
        for (final q in lines) {
          expect(q.text.trim(), isNotEmpty);
        }
      }
    });
  });

  group('nextQuoteIndex', () {
    test('never repeats the previous index (count >= 2)', () {
      final rng = Random(7);
      var prev = 0;
      for (var i = 0; i < 500; i++) {
        final next = nextQuoteIndex(prev, 6, rng);
        expect(next, isNot(prev));
        expect(next, inInclusiveRange(0, 5));
        prev = next;
      }
    });

    test('returns 0 when there is only one item', () {
      expect(nextQuoteIndex(null, 1, Random(1)), 0);
      expect(nextQuoteIndex(0, 1, Random(1)), 0);
    });

    test('first pick (previous == null) is in range', () {
      final next = nextQuoteIndex(null, 6, Random(3));
      expect(next, inInclusiveRange(0, 5));
    });
  });
}
