import 'package:flutter/foundation.dart';

import '../domain/focus_phase.dart';
import '../domain/phase_engine.dart';
import '../domain/session_mode.dart';
import '../domain/session_record.dart';
import 'config_codec.dart';
import 'session_config.dart';
import 'session_cue.dart';
import 'session_plan.dart';
import 'session_state.dart';
import 'ticker.dart';

/// Owns the live session: runs the [SessionPlan]'s focus/rest segments via an
/// injectable [Ticker], tracks elapsed/recorded focus and the focus phase, and
/// finalizes into a [SessionRecord]. UI listens via [ChangeNotifier].
class SessionController extends ChangeNotifier {
  final SessionConfig config;
  final Ticker ticker;
  final DateTime Function() now;

  /// Optional ritual-transition hook (started / break boundaries / finished).
  /// The UI wires this to sound cues; null in tests and preview (no audio).
  final void Function(SessionCue cue)? onCue;

  /// Max manual pauses allowed this session; null = unlimited (Pro / tests).
  /// Not final: [applyProEntitlement] can widen it if Pro resolves late.
  int? pauseLimit;

  /// Whether a Pomodoro/Custom session may CONTINUE (append more blocks) past its
  /// planned end instead of finishing — a Pro feature; the UI passes the
  /// entitlement. Flow Block's keep-going is separate and always available.
  /// Not final: [applyProEntitlement] can enable it if Pro resolves late.
  bool allowContinue;

  SessionState _state = SessionState.initial();
  late final DateTime _startedAt;

  /// The working segment list — seeded from the plan, but APPENDABLE when a
  /// Pomodoro/Custom session is continued past its end (see [addBlock] /
  /// [repeatPlan]). The plan itself stays immutable (used for the planned total).
  late final List<SessionSegment> _segments = List.of(config.plan.segments);

  /// Whether this block runs open-ended (never auto-stops). Seeded from the
  /// config's pre-set toggle, but can be switched on mid-block by the user
  /// ("don't stop" near the end).
  bool _endless = false;
  bool get isEndless => _endless;

  /// Whether breaks auto-advance into the next focus block. Seeded from config,
  /// but changeable live (mid-session quick settings).
  bool _autoAdvanceBreaks = true;
  bool get autoAdvanceBreaks => _autoAdvanceBreaks;
  void setAutoAdvanceBreaks(bool v) {
    _autoAdvanceBreaks = v;
    notifyListeners();
  }

  SessionController({
    required this.config,
    required this.ticker,
    required this.now,
    this.onCue,
    this.pauseLimit,
    this.allowContinue = false,
  });

  /// Re-apply entitlement-derived limits when the user's Pro status resolves
  /// AFTER the session started (e.g. RevenueCat answers late on a cold start, or
  /// right after a purchase while offline). Only ever RELAXES the running
  /// session — widening the pause limit and enabling continue — never tightens
  /// it, so an in-progress block can't be penalised by a late entitlement read.
  void applyProEntitlement({required int? pauseLimit, required bool allowContinue}) {
    // Only relax, never tighten: unlimited (null) widens any finite limit; a
    // finite value applies only if it's larger than the current one.
    if (pauseLimit == null) {
      this.pauseLimit = null;
    } else if (this.pauseLimit != null && pauseLimit > this.pauseLimit!) {
      this.pauseLimit = pauseLimit;
    }
    if (allowContinue) this.allowContinue = true;
    notifyListeners();
  }

  /// Manual pauses used so far this session.
  int _pauseCount = 0;
  int get pauseCount => _pauseCount;

  /// Whether the user may pause right now — running, and within the pause limit.
  bool get canPause =>
      _state.status == SessionStatus.running &&
      (pauseLimit == null || _pauseCount < pauseLimit!);

  SessionState get state => _state;

  SessionPlan get plan => config.plan;

  SessionSegment get currentSegment => _segments[_state.segmentIndex];

  /// True when the current segment is the last of the working plan (used by the
  /// near-end "add a block" nudge for Pomodoro/Custom).
  bool get isLastSegment => _state.segmentIndex == _segments.length - 1;

  Duration get segmentRemaining {
    final r = currentSegment.duration - _state.segmentElapsed;
    return r.isNegative ? Duration.zero : r;
  }

  /// Progress within the current segment, 0..1 (drives the hourglass).
  double get segmentProgress {
    final total = currentSegment.duration.inSeconds;
    if (total <= 0) return 0;
    return (_state.segmentElapsed.inSeconds / total).clamp(0.0, 1.0);
  }

  /// Overall session progress, 0..1 (over the working segments, which grow when
  /// a Pomodoro/Custom session is continued).
  double get progress {
    final total =
        _segments.fold(Duration.zero, (a, s) => a + s.duration).inSeconds;
    if (total <= 0) return 0;
    return (_state.elapsed.inSeconds / total).clamp(0.0, 1.0);
  }

  bool get _endlessSingleFocus => plan.isSingleFocus && _endless;

  void start() {
    if (_state.status != SessionStatus.idle) return;
    _endless = config.autoContinue;
    _autoAdvanceBreaks = config.autoAdvanceBreaks;
    _startedAt = now();
    _set(_state.copyWith(
      status: SessionStatus.running,
      currentKind: plan.segments.first.kind,
    ));
    ticker.start(_onTick);
    onCue?.call(SessionCue.started);
  }

  FocusPhase _phaseFor(Duration focusDuration, Duration inSegment) =>
      PhaseEngine.forBlock(focusDuration).phaseAt(inSegment);

  void _onTick(Duration delta) {
    // Endless single-focus: never auto-finish. The hourglass CYCLES — each time
    // it drains (segmentElapsed reaches the block length) it flips and refills
    // (a new lap), so the sand keeps falling instead of stopping at 0. Total
    // elapsed/recorded keep accumulating across laps.
    if (_endlessSingleFocus) {
      final focusDur = plan.segments.first.duration;
      final total = _state.elapsed + delta;
      var segEl = _state.segmentElapsed + delta;
      var lap = _state.lap;
      if (focusDur > Duration.zero) {
        while (segEl >= focusDur) {
          segEl -= focusDur; // drained → flip + refill, next lap
          lap += 1;
        }
      }
      _set(_state.copyWith(
        elapsed: total,
        segmentElapsed: segEl,
        recordedFocus: total,
        lap: lap,
        phase: _phaseFor(focusDur, segEl),
        goalReached: _state.goalReached || total >= focusDur,
      ));
      return;
    }

    final segs = _segments;
    var remaining = delta;
    var idx = _state.segmentIndex;
    var segElapsed = _state.segmentElapsed;
    var elapsed = _state.elapsed;
    var recorded = _state.recordedFocus;

    while (remaining > Duration.zero) {
      final seg = segs[idx];
      final room = seg.duration - segElapsed;
      if (remaining < room) {
        segElapsed += remaining;
        elapsed += remaining;
        if (seg.isFocus) recorded += remaining;
        remaining = Duration.zero;
      } else {
        // Segment completes; carry the rest into the next.
        elapsed += room;
        if (seg.isFocus) recorded += room;
        remaining -= room;
        if (idx == segs.length - 1) {
          ticker.stop();
          // A Flow Block (single focus) pauses at a "completed" decision point
          // so the user can collect it or keep going. Pomodoro/Custom pause there
          // too WHEN continue is allowed (Pro) so they can add more blocks;
          // otherwise they finish.
          final isFlowDecision =
              plan.isSingleFocus && config.mode == SessionMode.flowBlock;
          final canContinue = allowContinue &&
              (config.mode == SessionMode.pomodoro ||
                  config.mode == SessionMode.custom);
          final completable = isFlowDecision || canContinue;
          _set(_state.copyWith(
            status: completable
                ? SessionStatus.completed
                : SessionStatus.finished,
            segmentIndex: idx,
            currentKind: seg.kind,
            segmentElapsed: seg.duration,
            elapsed: elapsed,
            recordedFocus: recorded,
            phase: seg.isFocus
                ? _phaseFor(seg.duration, seg.duration)
                : _state.phase,
            goalReached: true,
          ));
          onCue?.call(SessionCue.finished);
          return;
        }
        // Tap-to-continue: a break just ended → wait for the user before the
        // next focus block (drop the tiny leftover delta).
        if (!seg.isFocus && !_autoAdvanceBreaks) {
          ticker.stop();
          final next = segs[idx + 1];
          _set(_state.copyWith(
            status: SessionStatus.awaitingResume,
            segmentIndex: idx + 1,
            currentKind: next.kind,
            segmentElapsed: Duration.zero,
            elapsed: elapsed,
            recordedFocus: recorded,
            phase: _phaseFor(next.duration, Duration.zero),
          ));
          onCue?.call(SessionCue.breakEnded);
          return;
        }
        // Auto-advancing across a boundary: a focus block ending starts a break;
        // a break ending resumes focus.
        onCue?.call(
            seg.isFocus ? SessionCue.breakStarted : SessionCue.breakEnded);
        idx += 1;
        segElapsed = Duration.zero;
      }
    }

    final cur = segs[idx];
    _set(_state.copyWith(
      segmentIndex: idx,
      currentKind: cur.kind,
      segmentElapsed: segElapsed,
      elapsed: elapsed,
      recordedFocus: recorded,
      phase: cur.isFocus ? _phaseFor(cur.duration, segElapsed) : _state.phase,
      // The planned goal is reached once focus reaches the ORIGINAL plan's total,
      // even if the session was extended past it (the near-end nudge) — so a
      // later-abandoned bonus block still counts the session as completed.
      goalReached: _state.goalReached || recorded >= plan.totalFocus,
    ));
  }

  void pause() {
    if (!canPause) return;
    _pauseCount++;
    ticker.stop();
    _set(_state.copyWith(status: SessionStatus.paused));
  }

  bool _suspended = false;

  /// Freeze the clock WITHOUT consuming a pause or changing status — used while
  /// the app is backgrounded during the leave-grace window (no focus accrues
  /// while away). [unsuspend] resumes it if the block is still running.
  void suspend() {
    if (_state.status == SessionStatus.running && !_suspended) {
      _suspended = true;
      ticker.stop();
    }
  }

  void unsuspend() {
    if (!_suspended) return;
    _suspended = false;
    if (_state.status == SessionStatus.running) ticker.start(_onTick);
  }

  void resume() {
    if (_state.status != SessionStatus.paused) return;
    _set(_state.copyWith(status: SessionStatus.running));
    ticker.start(_onTick);
  }

  /// Start the next focus block after a break (tap-to-continue mode).
  void continueToNext() {
    if (_state.status != SessionStatus.awaitingResume) return;
    _set(_state.copyWith(status: SessionStatus.running));
    ticker.start(_onTick);
  }

  /// Skip the current break — advance straight to the boundary (which either
  /// starts the next block, or parks at the wait point in tap-to-continue mode).
  void skipRest() {
    if (_state.status != SessionStatus.running || !_state.isResting) return;
    _onTick(segmentRemaining);
  }

  /// Switch the running block to open-ended ("don't stop") — typically tapped
  /// near the end so the block flows past its length instead of stopping. If the
  /// block already hit its completed decision point, resume it seamlessly.
  void enableEndless() {
    if (!plan.isSingleFocus || _endless) return;
    _endless = true;
    if (_state.status == SessionStatus.completed) {
      _set(_state.copyWith(status: SessionStatus.running));
      ticker.start(_onTick);
    } else {
      notifyListeners();
    }
  }

  /// Turn endless back off before the goal (revert to stopping at the length).
  void disableEndless() {
    if (_endless && _state.status == SessionStatus.running && !_state.goalReached) {
      _endless = false;
      notifyListeners();
    }
  }

  /// Extend a completed Flow Block: drain the same block again (the hourglass
  /// refills and flips), accumulating focus. Overflow past the chosen length
  /// rewards the Focus Score. Reaching the length again returns to `completed`.
  void keepGoing() {
    if (_state.status != SessionStatus.completed) return;
    _set(_state.copyWith(
      status: SessionStatus.running,
      segmentElapsed: Duration.zero, // drain from full again
      phase: _phaseFor(currentSegment.duration, Duration.zero),
    ));
    ticker.start(_onTick);
  }

  /// Repeat the whole original plan again (Pomodoro/Custom continue) — appends a
  /// fresh copy of the plan's segments and resumes from the completed point.
  void repeatPlan() {
    if (_state.status != SessionStatus.completed) return;
    _segments.addAll(config.plan.segments);
    _resumeAppended();
  }

  /// Add one more focus block of [focus] (Pomodoro/Custom continue), optionally
  /// preceded by a [precedingRest] break, and resume from the completed point.
  void addBlock(Duration focus, {Duration precedingRest = Duration.zero}) {
    if (_state.status != SessionStatus.completed || focus <= Duration.zero) {
      return;
    }
    if (precedingRest > Duration.zero) {
      _segments.add(SessionSegment.rest(precedingRest));
    }
    _segments.add(SessionSegment.focus(focus));
    _resumeAppended();
  }

  /// Extend a still-RUNNING Pomodoro/Custom session (the near-end nudge): append
  /// another focus block, optionally after a [precedingRest] break, so the block
  /// flows straight on instead of stopping at the end. Pro only.
  void extendNow(Duration focus, {Duration precedingRest = Duration.zero}) {
    if (!allowContinue ||
        _state.status != SessionStatus.running ||
        focus <= Duration.zero) {
      return;
    }
    if (precedingRest > Duration.zero) {
      _segments.add(SessionSegment.rest(precedingRest));
    }
    _segments.add(SessionSegment.focus(focus));
    notifyListeners();
  }

  /// Resume running into the first appended segment after the completed point.
  void _resumeAppended() {
    final nextIdx = _state.segmentIndex + 1;
    final next = _segments[nextIdx];
    _set(_state.copyWith(
      status: SessionStatus.running,
      segmentIndex: nextIdx,
      currentKind: next.kind,
      segmentElapsed: Duration.zero,
      // The planned goal was already reached — bonus blocks keep the session
      // 'completed' on finalize even if a bonus block is later given up.
      goalReached: true,
      phase: next.isFocus
          ? _phaseFor(next.duration, Duration.zero)
          : _state.phase,
    ));
    ticker.start(_onTick);
  }

  /// User ends the session (e.g. an endless block, or stopping early).
  void end() {
    ticker.stop();
    _set(_state.copyWith(status: SessionStatus.finished));
    // Endless blocks never hit the natural-completion cue, so their deliberate
    // end is the "finished" moment. A non-endless early stop gets no cue.
    if (_endless) onCue?.call(SessionCue.finished);
  }

  /// Session abandoned before the goal (e.g. left the app, protect-the-block).
  void abandon() {
    ticker.stop();
    _set(_state.copyWith(status: SessionStatus.finished));
  }

  /// Builds the record to persist. `completed` iff the planned end was reached.
  ///
  /// Recording rule: EVERY mode records the actual focused length on every end
  /// (completed, given-up, or app-left) so it shows in Today's focus and the
  /// session history. Flow Block ignores sub-2-min ends (they never count toward
  /// the Focus Score, which is Flow-Block-only). Pomodoro/Custom record whatever
  /// focus was done — there's no score or penalty, but the time still counts.
  SessionRecord finalize() {
    final completed = _state.goalReached;
    // Record the actual focused time in every mode (for Today + history). The
    // Focus Score (Flow-Block-only) separately ignores sub-2-min blocks.
    final recorded = _state.recordedFocus;
    return SessionRecord(
      id: 0,
      startedAt: _startedAt,
      mode: config.mode,
      intention: config.intention,
      plannedDuration: plan.totalFocus,
      recordedFocus: recorded,
      completed: completed,
      abandoned: !completed,
      autoContinue: _endless,
      soundscape: config.soundscape,
      skinId: config.skinId,
      planJson: encodeConfig(config),
    );
  }

  void _set(SessionState s) {
    _state = s;
    notifyListeners();
  }

  @override
  void dispose() {
    ticker.stop();
    super.dispose();
  }
}
