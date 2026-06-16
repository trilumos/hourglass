import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../app/providers.dart';
import '../app/theme.dart';
import '../app/tokens.dart';
import '../domain/focus_phase.dart';
import '../domain/focus_score_calculator.dart';
import '../domain/session_mode.dart';
import '../domain/session_record.dart';
import '../hourglass/hourglass_view.dart';
import '../session/session_config.dart';
import '../session/session_controller.dart';
import '../session/session_plan.dart';
import '../session/session_state.dart';
import '../session/ticker.dart';
import 'widgets/primary_button.dart';
import 'widgets/screen_background.dart';

/// The running ritual. The hourglass IS the session and the only thing that
/// moves; time is felt (sand level), not read. The Struggle phase surfaces one
/// quiet line that fades for good; you can pause (freezes the sand) or give up
/// (behind a calm confirm); leaving the app ends the block (protect-the-block);
/// completion counts up the Focus Score. Screen stays awake, chrome dims when idle.
class SessionScreen extends ConsumerStatefulWidget {
  final SessionConfig config;

  /// Test seam: inject a fake ticker/clock. Production uses a real periodic
  /// ticker and the wall clock.
  final Ticker? ticker;
  final DateTime Function()? now;

  const SessionScreen({
    super.key,
    required this.config,
    this.ticker,
    this.now,
  });

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final SessionController _controller;
  late final AnimationController _flip;
  bool _finished = false;
  bool _showTime = false;
  bool _dimmed = false;
  bool _persisted = false;
  int? _recordId;
  int _flippedIndex = -1; // last focus-block index we played the flip for
  SessionRecord? _record;
  Timer? _revealTimer;
  Timer? _idleTimer;

  static const _idleDelay = Duration(seconds: 45);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable(); // keep the screen awake for the whole session
    // Starts upright; each new focus block plays a flip (forward from 0).
    _flip = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
      value: 1,
    );
    _controller = SessionController(
      config: widget.config,
      ticker: widget.ticker ?? PeriodicTicker(),
      now: widget.now ?? DateTime.now,
    )..addListener(_onChange);
    _controller.start();
    _resetIdle();
  }

  /// Flip the hourglass over to begin a (new) block. Skipped under test where a
  /// fake ticker drives discrete frames.
  void _playFlip() {
    if (widget.ticker != null) return;
    _flip.forward(from: 0);
  }

  void _onChange() {
    final s = _controller.state;
    // Flip the hourglass whenever a fresh focus block starts (begin, after a
    // break, after "keep going").
    if (s.status == SessionStatus.running &&
        s.currentKind == SegmentKind.focus &&
        _flippedIndex != s.segmentIndex) {
      _flippedIndex = s.segmentIndex;
      _playFlip();
    }

    if (s.status == SessionStatus.completed) {
      // Reached the planned length — checkpoint it so it's never lost, but stay
      // on screen offering "Keep going".
      _record = _controller.finalize();
      _saveCheckpoint(_record!);
      _idleTimer?.cancel();
      _dimmed = false;
      HapticFeedback.mediumImpact();
    } else if (s.status == SessionStatus.finished && !_finished) {
      _finished = true;
      _record = _controller.finalize();
      _saveCheckpoint(_record!);
      _idleTimer?.cancel();
      _dimmed = false;
      WakelockPlus.disable();
      HapticFeedback.mediumImpact();
    }
    if (mounted) setState(() {});
  }

  /// Persist on first completion, then REVISE the same record if the block is
  /// extended — one record per block. Refresh derived providers only after the
  /// write lands (invalidating early recomputes from stale data).
  Future<void> _saveCheckpoint(SessionRecord record) async {
    final finalizer = ref.read(sessionFinalizerProvider);
    if (!_persisted) {
      _persisted = true;
      _recordId = await finalizer.persist(record);
    } else if (_recordId != null) {
      await finalizer.reviseRecordedFocus(
        _recordId!,
        recorded: record.recordedFocus,
        completed: record.completed,
        abandoned: record.abandoned,
      );
    }
    if (!mounted) return;
    ref.invalidate(focusScoreProvider);
    ref.invalidate(homeStatsProvider);
    ref.invalidate(suggestedFlowLengthProvider);
  }

  void _onKeepGoing() {
    _flippedIndex = -1; // force a fresh flip for the new drain
    _controller.keepGoing();
    _resetIdle();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Protect the block: leaving the app ends the running session.
    if (state == AppLifecycleState.paused &&
        _controller.state.status == SessionStatus.running) {
      _controller.abandon();
    }
  }

  @override
  void dispose() {
    _flip.dispose();
    _revealTimer?.cancel();
    _idleTimer?.cancel();
    WakelockPlus.disable();
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onChange);
    _controller.dispose();
    super.dispose();
  }

  // Idle chrome dimming — only while a focus block is actively running.
  void _resetIdle() {
    _idleTimer?.cancel();
    if (_dimmed) setState(() => _dimmed = false);
    _idleTimer = Timer(_idleDelay, () {
      final s = _controller.state;
      if (mounted && s.status == SessionStatus.running && !s.isResting) {
        setState(() => _dimmed = true);
      }
    });
  }

  void _revealTime() {
    HapticFeedback.selectionClick();
    setState(() => _showTime = true);
    _revealTimer?.cancel();
    _revealTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showTime = false);
    });
    _resetIdle();
  }

  Future<void> _confirmGiveUp() async {
    final isFlow = widget.config.mode == SessionMode.flowBlock;
    final mins = _controller.state.recordedFocus.inMinutes;
    final give = await _showGiveUpSheet(isFlow: isFlow, focusedMinutes: mins);
    if (give == true) {
      HapticFeedback.selectionClick();
      _controller.end();
    }
  }

  Future<bool?> _showGiveUpSheet({
    required bool isFlow,
    required int focusedMinutes,
  }) {
    final hg = context.hg;
    final String body;
    if (isFlow) {
      body = focusedMinutes >= 2
          ? "You've focused $focusedMinutes min. Ending now records this block — "
              'but a short block lowers your Focus Score. Staying with it builds it.'
          : 'Less than 2 minutes counts as nothing. A few more and this block '
              'starts to build your Focus Score.';
    } else {
      body = "Ending now won't save this session's progress.";
    }

    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: hg.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(HgRadius.lg)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              HgSpacing.lg, HgSpacing.lg, HgSpacing.lg, HgSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'End this block?',
                style: TextStyle(
                  fontFamily: HgFont.sans,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: hg.textPrimary,
                ),
              ),
              const SizedBox(height: HgSpacing.sm),
              Text(
                body,
                style: TextStyle(
                  fontFamily: HgFont.sans,
                  fontSize: 14,
                  height: 1.4,
                  color: hg.textSecondary,
                ),
              ),
              const SizedBox(height: HgSpacing.lg),
              PrimaryButton(
                label: 'Keep going',
                onPressed: () => Navigator.of(sheetCtx).pop(false),
              ),
              const SizedBox(height: HgSpacing.xs),
              TextButton(
                onPressed: () => Navigator.of(sheetCtx).pop(true),
                child: Text(
                  'End block',
                  style: TextStyle(fontFamily: HgFont.sans, color: hg.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _controller.state;
    final Widget view = switch (s.status) {
      SessionStatus.finished => _Completion(
          key: const ValueKey('done'),
          record: _record,
          config: widget.config,
          canKeepGoing: false,
          onDone: () => Navigator.of(context).pop(),
        ),
      SessionStatus.completed => _Completion(
          key: const ValueKey('completed'),
          record: _record,
          config: widget.config,
          canKeepGoing: true,
          onKeepGoing: _onKeepGoing,
          onDone: () => Navigator.of(context).pop(),
        ),
      SessionStatus.awaitingResume => _awaitingView(s),
      _ => s.isResting ? _restView(s) : _focusView(s),
    };

    return Listener(
      onPointerDown: (_) => _resetIdle(),
      child: Scaffold(
        body: ScreenBackground(
          child: SafeArea(
            child: AnimatedSwitcher(
              duration: HgMotion.slow, // the "breath" between states
              switchInCurve: HgMotion.enter,
              switchOutCurve: HgMotion.exit,
              child: view,
            ),
          ),
        ),
      ),
    );
  }

  // ── Focus ──────────────────────────────────────────────────────────────────
  Widget _focusView(SessionState s) {
    final hg = context.hg;
    final paused = s.status == SessionStatus.paused;
    final struggle = s.phase == FocusPhase.struggle && !paused;

    // Everything except the hourglass dims when idle (calm, ambient).
    final chrome = _dimmed ? 0.18 : 1.0;

    return Padding(
      key: const ValueKey('focus'),
      padding: const EdgeInsets.symmetric(horizontal: HgSpacing.screen),
      child: Column(
        children: [
          const SizedBox(height: HgSpacing.sm),
          AnimatedOpacity(
            opacity: chrome,
            duration: HgMotion.medium,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _segmentLabel(),
                  style: TextStyle(
                    fontFamily: HgFont.sans,
                    fontSize: 12,
                    letterSpacing: 1,
                    color: hg.textMuted,
                  ),
                ),
                TextButton(
                  onPressed: _confirmGiveUp,
                  child: Text(
                    'Give up',
                    style:
                        TextStyle(fontFamily: HgFont.sans, color: hg.textMuted),
                  ),
                ),
              ],
            ),
          ),
          AnimatedOpacity(
            opacity: chrome,
            duration: HgMotion.medium,
            child: Column(
              children: [
                if (widget.config.intention.isNotEmpty) ...[
                  const SizedBox(height: HgSpacing.sm),
                  Text(
                    widget.config.intention,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: HgFont.sans,
                      fontSize: 16,
                      color: hg.textSecondary,
                    ),
                  ),
                ],
                // Struggle reframe (or a quiet "Paused") — single line, fades out.
                SizedBox(
                  height: 40,
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: (struggle || paused) ? 1 : 0,
                      duration: HgMotion.slow,
                      child: Text(
                        paused
                            ? 'Paused'
                            : 'The first few minutes are the hard part — stay with it.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: HgFont.sans,
                          fontSize: 13,
                          fontStyle:
                              paused ? FontStyle.normal : FontStyle.italic,
                          letterSpacing: paused ? 2 : 0,
                          color: paused ? hg.textMuted : hg.accent,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Glanced time — large readout ABOVE the hourglass; fades on tap.
          SizedBox(
            height: 56,
            child: AnimatedOpacity(
              opacity: _showTime ? 1 : 0,
              duration: HgMotion.fast,
              child: Center(
                child: Text(
                  _fmtClock(_controller.segmentRemaining),
                  style: TextStyle(
                    fontFamily: HgFont.sans,
                    fontSize: 46,
                    fontWeight: FontWeight.w200,
                    letterSpacing: 1,
                    color: hg.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          // Hero: the hourglass on a soft halo. Flips over to begin; tap to
          // glance the time; freezes when paused.
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: _revealTime,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Ambient glow — gives the plain field some depth.
                    IgnorePointer(
                      child: Container(
                        width: 240,
                        height: 240,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              hg.accent.withValues(alpha: paused ? 0.04 : 0.10),
                              hg.accent.withValues(alpha: 0.0),
                            ],
                            stops: const [0.0, 1.0],
                          ),
                        ),
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _flip,
                      builder: (context, child) {
                        final t = Curves.easeOutCubic.transform(_flip.value);
                        return Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.0012) // perspective
                            ..rotateX((1 - t) * math.pi),
                          child: child,
                        );
                      },
                      child: HourglassView(
                        progress: _controller.segmentProgress,
                        animate: !paused,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: HgSpacing.lg),
          AnimatedOpacity(
            opacity: chrome,
            duration: HgMotion.medium,
            child: PrimaryButton(
              label: paused ? 'Resume' : 'Pause',
              onPressed: () {
                if (paused) {
                  _controller.resume();
                  _resetIdle();
                } else {
                  _controller.pause();
                }
              },
            ),
          ),
          const SizedBox(height: HgSpacing.xl),
        ],
      ),
    );
  }

  // ── Break ───────────────────────────────────────────────────────────────────
  Widget _restView(SessionState s) {
    final hg = context.hg;
    final autoAdvance = widget.config.autoAdvanceBreaks;
    return Padding(
      key: const ValueKey('break'),
      padding: const EdgeInsets.symmetric(horizontal: HgSpacing.screen),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch, // full width → centered
        children: [
          Text(
            'BREAK',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: HgFont.sans,
              fontSize: 13,
              letterSpacing: 3,
              fontWeight: FontWeight.w600,
              color: hg.textMuted,
            ),
          ),
          const SizedBox(height: HgSpacing.md),
          Text(
            _fmtClock(_controller.segmentRemaining),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: HgFont.sans,
              fontSize: 56,
              fontWeight: FontWeight.w300,
              color: hg.textPrimary,
            ),
          ),
          const SizedBox(height: HgSpacing.sm),
          Text(
            autoAdvance
                ? 'Rest — the next block starts on its own.'
                : "Rest — you'll start the next block yourself.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: HgFont.sans,
              fontSize: 13,
              color: hg.textMuted,
            ),
          ),
          const SizedBox(height: HgSpacing.xs),
          Text(
            'Change this in Settings.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: HgFont.sans,
              fontSize: 11,
              color: hg.textMuted,
            ),
          ),
          const SizedBox(height: HgSpacing.xl),
          TextButton(
            onPressed: _controller.skipRest,
            child: Text('Skip break',
                style: TextStyle(fontFamily: HgFont.sans, color: hg.textMuted)),
          ),
          TextButton(
            onPressed: _confirmGiveUp,
            child: Text('End session',
                style: TextStyle(fontFamily: HgFont.sans, color: hg.textMuted)),
          ),
        ],
      ),
    );
  }

  // ── Awaiting next block (tap-to-continue) ────────────────────────────────────
  Widget _awaitingView(SessionState s) {
    final hg = context.hg;
    return Padding(
      key: const ValueKey('await'),
      padding: const EdgeInsets.symmetric(horizontal: HgSpacing.screen),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch, // full width → centered
        children: [
          Text(
            'BREAK OVER',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: HgFont.sans,
              fontSize: 13,
              letterSpacing: 3,
              fontWeight: FontWeight.w600,
              color: hg.textMuted,
            ),
          ),
          const SizedBox(height: HgSpacing.md),
          Text(
            _segmentLabel().isEmpty ? 'Ready for the next block?' : _segmentLabel(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: HgFont.sans,
              fontSize: 22,
              fontWeight: FontWeight.w400,
              color: hg.textPrimary,
            ),
          ),
          const SizedBox(height: HgSpacing.xl),
          PrimaryButton(
            label: 'Begin next block',
            onPressed: () {
              _controller.continueToNext();
              _resetIdle();
            },
          ),
          const SizedBox(height: HgSpacing.xs),
          TextButton(
            onPressed: _confirmGiveUp,
            child: Text('End session',
                style: TextStyle(fontFamily: HgFont.sans, color: hg.textMuted)),
          ),
        ],
      ),
    );
  }

  String _segmentLabel() {
    final plan = widget.config.plan;
    if (plan.focusCount <= 1) return '';
    var focusSeen = 0;
    for (var i = 0; i <= _controller.state.segmentIndex; i++) {
      if (plan.segments[i].isFocus) focusSeen++;
    }
    return 'BLOCK $focusSeen / ${plan.focusCount}';
  }

  String _fmtClock(Duration d) {
    final m = d.inMinutes;
    final sec = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }
}

/// Completion — a calm reveal: the settled hourglass glows, the Focus Score
/// counts up, the session's points are named. Persist already happened.
class _Completion extends ConsumerWidget {
  final SessionRecord? record;
  final SessionConfig config;
  final VoidCallback onDone;
  final bool canKeepGoing;
  final VoidCallback? onKeepGoing;
  const _Completion({
    super.key,
    required this.record,
    required this.config,
    required this.onDone,
    this.canKeepGoing = false,
    this.onKeepGoing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hg = context.hg;
    final mins = record?.recordedFocus.inMinutes ?? 0;
    final isFlow = config.mode == SessionMode.flowBlock;
    final score = ref.watch(focusScoreProvider).asData?.value;

    final sessionPoints = (isFlow && record != null)
        ? const FocusScoreCalculator().sessionScore(
            chosen: record!.plannedDuration,
            actual: record!.recordedFocus,
          )
        : 0;

    return Padding(
      key: const ValueKey('done-body'),
      padding: const EdgeInsets.symmetric(horizontal: HgSpacing.screen),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: hg.glow, blurRadius: 60, spreadRadius: 10),
              ],
            ),
            child: const SizedBox(
              width: 140,
              child: HourglassView(progress: 1, animate: false),
            ),
          ),
          const SizedBox(height: HgSpacing.xl),
          Text(
            mins > 0
              ? '$mins minutes focused'
              : (canKeepGoing ? 'Block complete' : 'Session ended'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: HgFont.sans,
              fontSize: 26,
              fontWeight: FontWeight.w400,
              color: hg.textPrimary,
            ),
          ),
          if (isFlow && mins > 0) ...[
            const SizedBox(height: HgSpacing.lg),
            Text(
              'FOCUS SCORE',
              style: TextStyle(
                fontFamily: HgFont.sans,
                fontSize: 11,
                letterSpacing: 2,
                color: hg.textMuted,
              ),
            ),
            const SizedBox(height: HgSpacing.xs),
            if (score != null)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: score.toDouble()),
                duration: const Duration(milliseconds: 900),
                curve: HgMotion.calm,
                builder: (_, v, _) => Text(
                  '${v.round()}',
                  style: TextStyle(
                    fontFamily: HgFont.sans,
                    fontSize: 48,
                    fontWeight: FontWeight.w600,
                    color: hg.accent,
                  ),
                ),
              ),
            const SizedBox(height: HgSpacing.xs),
            Text(
              sessionPoints > 0
                  ? 'This block scored $sessionPoints'
                  : 'This block was too short to score',
              style: TextStyle(
                fontFamily: HgFont.sans,
                fontSize: 13,
                color: hg.textMuted,
              ),
            ),
          ],
          const SizedBox(height: HgSpacing.xxl),
          if (canKeepGoing) ...[
            PrimaryButton(label: 'Keep going', onPressed: onKeepGoing),
            const SizedBox(height: HgSpacing.xs),
            TextButton(
              onPressed: onDone,
              child: Text('Done',
                  style: TextStyle(fontFamily: HgFont.sans, color: hg.textMuted)),
            ),
          ] else
            PrimaryButton(label: 'Done', onPressed: onDone),
        ],
      ),
    );
  }
}
