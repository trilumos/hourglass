// A session is a sequence of timed segments — focus or rest. This pure model
// (no Flutter) lets Flow Block, Pomodoro cycles, and Custom interval sessions
// all be expressed the same way and driven by one controller.

enum SegmentKind { focus, rest }

class SessionSegment {
  final SegmentKind kind;
  final Duration duration;
  const SessionSegment(this.kind, this.duration);
  const SessionSegment.focus(Duration d) : this(SegmentKind.focus, d);
  const SessionSegment.rest(Duration d) : this(SegmentKind.rest, d);

  bool get isFocus => kind == SegmentKind.focus;
}

class SessionPlan {
  final List<SessionSegment> segments;
  const SessionPlan(this.segments);

  Duration get totalFocus => segments
      .where((s) => s.isFocus)
      .fold(Duration.zero, (a, s) => a + s.duration);

  Duration get totalDuration =>
      segments.fold(Duration.zero, (a, s) => a + s.duration);

  int get focusCount => segments.where((s) => s.isFocus).length;

  /// Exactly one focus segment and no rests (Flow / Custom-with-no-breaks).
  bool get isSingleFocus =>
      segments.length == 1 && segments.first.isFocus;

  // ── Builders ──────────────────────────────────────────────────────────────

  /// One unbroken focus block (recovery happens after, separately).
  factory SessionPlan.flowBlock(Duration work) =>
      SessionPlan([SessionSegment.focus(work)]);

  /// [blocks] focus periods; a rest sits between consecutive blocks (every
  /// [longEvery]-th break is [longBreak], else [shortBreak]). Ends on a focus
  /// block (no trailing rest).
  factory SessionPlan.pomodoro({
    required Duration work,
    required Duration shortBreak,
    required Duration longBreak,
    required int blocks,
    int longEvery = 4,
  }) {
    final segs = <SessionSegment>[];
    for (var i = 0; i < blocks; i++) {
      segs.add(SessionSegment.focus(work));
      final isLast = i == blocks - 1;
      if (!isLast) {
        final breakNumber = i + 1; // 1-based
        final isLong = longEvery > 0 && breakNumber % longEvery == 0;
        segs.add(SessionSegment.rest(isLong ? longBreak : shortBreak));
      }
    }
    return SessionPlan(segs);
  }

  /// Splits [totalWork] into `breaks + 1` even focus chunks (the last chunk
  /// absorbs any remainder so focus sums exactly to [totalWork]) with
  /// [breakDuration] rests between.
  factory SessionPlan.customByCount({
    required Duration totalWork,
    required int breaks,
    required Duration breakDuration,
  }) {
    final chunks = breaks + 1;
    // Whole-minute chunks (remainder into the last) so durations are clean and
    // the description can never disagree with the math.
    final baseMin = totalWork.inMinutes ~/ chunks;
    // Guard: too many breaks for the time → just one block (no zero-length focus).
    if (breaks <= 0 || baseMin <= 0) {
      return SessionPlan([SessionSegment.focus(totalWork)]);
    }
    final remainder = totalWork.inMinutes - baseMin * chunks;
    final segs = <SessionSegment>[];
    for (var i = 0; i < chunks; i++) {
      final isLast = i == chunks - 1;
      final mins = isLast ? baseMin + remainder : baseMin;
      segs.add(SessionSegment.focus(Duration(minutes: mins)));
      if (!isLast) segs.add(SessionSegment.rest(breakDuration));
    }
    return SessionPlan(segs);
  }

  /// Flowmodoro: split an exact [totalFocus] into [blocks] equal, variable-length
  /// focus chunks (whole minutes; remainder in the last) with auto rests ~5:1
  /// (rest ≈ block ÷ 5). Block length flexes so the focus time is always exact.
  factory SessionPlan.flowmodoro({
    required Duration totalFocus,
    required int blocks,
  }) {
    final totalMin = totalFocus.inMinutes;
    final base = blocks <= 0 ? 0 : totalMin ~/ blocks;
    if (blocks <= 1 || base <= 0) {
      return SessionPlan([SessionSegment.focus(totalFocus)]);
    }
    final remainder = totalMin - base * blocks;
    final restMin = (base / 5).round().clamp(1, 60);
    final segs = <SessionSegment>[];
    for (var i = 0; i < blocks; i++) {
      final isLast = i == blocks - 1;
      segs.add(SessionSegment.focus(Duration(minutes: isLast ? base + remainder : base)));
      if (!isLast) segs.add(SessionSegment.rest(Duration(minutes: restMin)));
    }
    return SessionPlan(segs);
  }

  /// Focus chunks of [intervalWork] with [breakDuration] rests between, repeated
  /// until [totalWork] is consumed (the final chunk is the remainder, no
  /// trailing rest).
  factory SessionPlan.customByInterval({
    required Duration totalWork,
    required Duration intervalWork,
    required Duration breakDuration,
  }) {
    final total = totalWork.inSeconds;
    final chunk = intervalWork.inSeconds;
    if (chunk <= 0 || total <= chunk) {
      return SessionPlan([SessionSegment.focus(totalWork)]);
    }
    final segs = <SessionSegment>[];
    var remaining = total;
    while (remaining > 0) {
      final take = remaining >= chunk ? chunk : remaining;
      segs.add(SessionSegment.focus(Duration(seconds: take)));
      remaining -= take;
      if (remaining > 0) segs.add(SessionSegment.rest(breakDuration));
    }
    return SessionPlan(segs);
  }
}
