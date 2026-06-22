import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../app/billing_providers.dart';
import '../app/providers.dart';
import '../app/sound_providers.dart';
import '../app/theme.dart';
import '../app/theme_controller.dart';
import '../app/theme_providers.dart';
import '../app/tokens.dart';
import '../domain/focus_phase.dart';
import '../domain/focus_score_calculator.dart';
import '../domain/session_mode.dart';
import '../domain/session_record.dart';
import '../hourglass/hourglass_view.dart';
import '../notifications/notification_coordinator.dart';
import '../notifications/notification_service.dart';
import '../session/session_config.dart';
import '../session/session_controller.dart';
import '../session/session_guard.dart';
import '../session/session_plan.dart';
import '../session/session_state.dart';
import '../session/strict_rules.dart';
import '../session/ticker.dart';
import 'paywall_screen.dart';
import 'themes_screen.dart';
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

  /// When true, this is a THEME PREVIEW run (started while previewing a locked
  /// theme). It shows the themed hourglass in motion but is capped at ~10s and
  /// persists NOTHING (no Focus Score, streak, Today, or history). It exists so
  /// a preview shows the hero moment without granting free themed usage.
  final bool previewMode;

  const SessionScreen({
    super.key,
    required this.config,
    this.ticker,
    this.now,
    this.previewMode = false,
  });

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late final SessionController _controller;
  late final AnimationController _flip;
  late final AnimationController _pulse;
  bool _finished = false;
  bool _showTime = false;
  bool _dimmed = false;
  bool _persisted = false;
  bool _autoRevealed = false;
  int? _recordId;
  int _flippedIndex = -1; // last focus-block index we played the flip for
  SessionRecord? _record;
  Timer? _revealTimer;
  Timer? _idleTimer;
  Timer? _checkpointTimer;
  Timer? _previewCapTimer;
  Timer? _guardStartTimer; // deferred foreground-service start (post-animation)
  bool _previewEnded = false;

  // Strict-session state: pause limits + the away/cap grace windows.
  late final StrictRules _rules;
  late final SessionGuard _guard;
  late final NotificationService _notifs;
  bool _wasResting = false; // tracks rest/focus transitions for break alerts
  bool _guardStarted = false; // the foreground service has been started once
  DateTime? _pausedAt; // when the current manual pause began
  Timer? _pauseWatch; // 1s check of the pause cap while paused
  bool _pauseCapHit = false; // inside the post-cap "return now" grace
  DateTime? _leftAt; // when the app was backgrounded mid-session
  bool _leftWhileRunning = false;

  static const _idleDelay = Duration(seconds: 45);

  DateTime _now() => (widget.now ?? DateTime.now)();

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
    // Gentle pulse for the "don't stop" nudge near the end of a block.
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _rules = StrictRules.forPro(ref.read(entitlementsProvider).pro);
    _guard = ref.read(sessionGuardProvider);
    _notifs = ref.read(notificationServiceProvider);
    _controller = SessionController(
      config: widget.config,
      ticker: widget.ticker ?? PeriodicTicker(),
      now: widget.now ?? DateTime.now,
      pauseLimit: widget.previewMode ? null : _rules.pauseLimit,
      // Ritual sound cues — never in a theme preview (records/plays nothing).
      onCue: widget.previewMode
          ? null
          : (cue) {
              if (!mounted || !ref.read(soundsEnabledProvider)) return;
              ref.read(soundCuePlayerProvider).play(cue);
            },
    )..addListener(_onChange);
    if (!widget.previewMode && ref.read(soundsEnabledProvider)) {
      ref.read(soundCuePlayerProvider).preload(); // warm so the start cue is snappy
    }
    _controller.start();
    _resetIdle();
    // Spin up the session foreground service only AFTER the Begin transition and
    // the hourglass hero have settled — starting its service + isolate mid-flight
    // janks the launch. ~600ms in it's invisible, and the app is still foreground
    // so Android's background-start restriction is satisfied.
    if (!widget.previewMode) {
      _guardStartTimer = Timer(const Duration(milliseconds: 600), () {
        if (mounted &&
            WidgetsBinding.instance.lifecycleState ==
                AppLifecycleState.resumed) {
          _ensureGuardStarted();
        }
      });
    }
    // Safety net: continuously checkpoint focus-so-far so a force-kill (or any
    // crash) can't lose the block — and force-killing counts as a give-up, just
    // like the button. Skipped under test (a fake ticker drives time).
    if (widget.ticker == null && !widget.previewMode) {
      _checkpointTimer = Timer.periodic(const Duration(seconds: 8), (_) {
        final s = _controller.state;
        if (s.status == SessionStatus.running &&
            s.recordedFocus.inSeconds >= 120) {
          _saveCheckpoint(_controller.finalize());
        }
      });
    }
    // Theme preview: a capped, non-recording taste of the themed session. After
    // ~10s it ends with a buy/exit prompt. It persists NOTHING (see
    // _saveCheckpoint / the lifecycle guard) so it can never be free themed usage.
    if (widget.previewMode) {
      _previewCapTimer = Timer(const Duration(seconds: 10), _endPreview);
    }
  }

  /// End a theme-preview session: freeze the hourglass and show the buy/exit
  /// prompt. Records nothing.
  void _endPreview() {
    if (!mounted || _previewEnded) return;
    final st = _controller.state.status;
    if (st == SessionStatus.running || st == SessionStatus.paused) {
      _controller.pause();
    }
    WakelockPlus.disable();
    setState(() => _previewEnded = true);
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
      // Show the time briefly when the session first begins, then let it fade.
      if (!_autoRevealed) {
        _autoRevealed = true;
        _revealTime(hold: const Duration(seconds: 4), haptic: false);
      }
    }

    // Drive the session notification + break alerts off the rest/focus phase.
    if (!widget.previewMode) {
      final resting = s.status == SessionStatus.running && s.isResting;
      if (resting != _wasResting) {
        _wasResting = resting;
        if (resting) {
          _guard.breakStarted(_now().add(_controller.segmentRemaining));
          _notifs.showSessionAlert(
              'Break — rest your eyes', 'A short rest; I\'ll call you back to focus.');
        } else if (s.status == SessionStatus.running) {
          _guard.focusing();
          _notifs.showSessionAlert(
              'Back to focus', 'Break\'s over — flip the hourglass and continue.');
        }
      }
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
      _guard.stop(); // session over → drop the foreground-service notification
      _notifs.showSessionAlert(
          'Session complete', 'Nicely done — your focus is logged.');
      HapticFeedback.mediumImpact();
    }
    if (mounted) setState(() {});
  }

  /// Persist on first completion, then REVISE the same record if the block is
  /// extended — one record per block. Refresh derived providers only after the
  /// write lands (invalidating early recomputes from stale data).
  Future<void> _saveCheckpoint(SessionRecord record) async {
    if (widget.previewMode) return; // a theme preview records nothing, ever
    final finalizer = ref.read(sessionFinalizerProvider);
    if (!_persisted) {
      _persisted = true; // claim synchronously so concurrent checkpoints don't double-insert
      final id = await finalizer.persist(record);
      if (id == null) {
        // Below the keep threshold (e.g. a sub-2-min Flow end) → nothing stored;
        // allow a later checkpoint to persist once there's real focus.
        _persisted = false;
        return;
      }
      _recordId = id;
    } else if (_recordId != null) {
      await finalizer.reviseRecordedFocus(
        _recordId!,
        recorded: record.recordedFocus,
        completed: record.completed,
        abandoned: record.abandoned,
      );
    } else {
      return; // a persist is in flight; this checkpoint can be skipped
    }
    if (!mounted) return;
    ref.invalidate(focusScoreProvider);
    ref.invalidate(homeStatsProvider);
    ref.invalidate(staminaProvider);
    ref.invalidate(profileStatsProvider);
    ref.invalidate(sessionHistoryProvider);
    ref.invalidate(dailyFocusProvider);
  }

  void _onKeepGoing() {
    _flippedIndex = -1; // force a fresh flip for the new drain
    _controller.keepGoing();
    _resetIdle();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (widget.previewMode) return; // a theme preview protects nothing
    if (state == AppLifecycleState.paused) {
      _onLeaveApp();
    } else if (state == AppLifecycleState.resumed) {
      _onReturnApp();
    }
  }

  /// Start the session foreground service once (idempotent). Normally fires from
  /// the post-animation timer; also called on return, in case the user
  /// backgrounded within that first 600ms (when an FGS can't be started from the
  /// background) and the timer therefore skipped it.
  void _ensureGuardStarted() {
    if (_guardStarted || widget.previewMode) return;
    _guardStarted = true;
    _guard.start();
  }

  /// Backgrounded mid-session: start the right grace window + push notification.
  void _onLeaveApp() {
    final status = _controller.state.status;
    if (status == SessionStatus.running) {
      _leftAt = _now();
      _leftWhileRunning = true;
      _controller.suspend(); // freeze the clock while away
      final end = _now().add(_rules.leaveGrace);
      _guard.leaveGrace(end); // FGS flips to a live 30s "come back" countdown
      if (!widget.previewMode) {
        // Immediate sounding "come back" push + a scheduled "session ended" if
        // they don't return in time (fires even with the app closed).
        _notifs.showGraceAlert(HgNotif.graceLeave, 'Come back to keep your block',
            'Return within ${_rules.leaveGrace.inSeconds}s or your block ends.');
        _notifs.scheduleGraceAlert(HgNotif.graceLeave, end, 'Session ended',
            'You were away too long.');
      }
    } else if (status == SessionStatus.paused && _pausedAt != null) {
      _leftAt = _now();
      _leftWhileRunning = false;
      _pauseWatch?.cancel();
      _pauseWatch = null;
      // The pause cap/grace pushes were already scheduled on pause and the FGS is
      // already counting down the cap — nothing more to arm here.
    }
  }

  /// Returned to the app: apply the grace decision (resume vs end).
  void _onReturnApp() {
    final leftAt = _leftAt;
    if (leftAt == null) return;
    _leftAt = null;
    if (_leftWhileRunning) {
      if (_rules.endAfterAwayRunning(_now().difference(leftAt))) {
        _controller.abandon(); // came back too late
        _guard.stop();
      } else {
        _controller.unsuspend(); // resume the clock
        _ensureGuardStarted(); // in case the 600ms start was skipped while away
        // Restore the right notification state — they may have left mid-break.
        if (_controller.state.isResting) {
          _guard.breakStarted(_now().add(_controller.segmentRemaining));
        } else {
          _guard.focusing();
        }
      }
      // The leave grace is resolved on return — clear its pushes either way.
      if (!widget.previewMode) _notifs.cancelGraceAlerts();
    } else if (_pausedAt != null) {
      final totalPaused = _now().difference(_pausedAt!);
      if (_rules.endAfterPaused(totalPaused)) {
        _clearPause();
        _controller.abandon();
        _guard.stop();
        if (!widget.previewMode) _notifs.cancelGraceAlerts(); // pause ended
      } else {
        // Still within the cap — the pause continues, so KEEP the scheduled cap/
        // grace pushes; just restore the live countdown + foreground watcher.
        _pauseCapHit = _rules.inCapGrace(totalPaused);
        _startPauseWatch(); // re-arm the foreground watcher
        _ensureGuardStarted(); // in case the 600ms start was skipped while away
        final capAt = _pausedAt!.add(_rules.pauseCap);
        _guard.pauseAway(capAt, capAt.add(_rules.capGrace));
      }
    }
    if (mounted) setState(() {});
  }

  // ── Manual pause (limited for free, lenient for Pro) ────────────────────────
  void _pauseSession() {
    if (_controller.canPause) {
      _controller.pause();
      // Bank focus-so-far so a force-kill while paused can't lose it.
      if (!widget.previewMode &&
          _controller.state.recordedFocus.inSeconds >= 120) {
        _saveCheckpoint(_controller.finalize());
      }
      final pausedAt = _now();
      _pausedAt = pausedAt;
      _pauseCapHit = false;
      _startPauseWatch();
      // FGS live cap countdown + sounding pushes (cap reached, then the 15s
      // grace) — these fire whether the user stays in-app or leaves.
      final capAt = pausedAt.add(_rules.pauseCap);
      final endAt = capAt.add(_rules.capGrace);
      _guard.pauseAway(capAt, endAt);
      if (!widget.previewMode) {
        _notifs.showGraceAlert(HgNotif.gracePauseUp, 'Paused',
            'You have ${_rules.pauseCap.inMinutes} min before your block is at risk.');
        _notifs.scheduleGraceAlert(HgNotif.gracePauseUp, capAt, 'Your pause is up',
            'Resume within ${_rules.capGrace.inSeconds}s to keep your block.');
        _notifs.scheduleGraceAlert(HgNotif.gracePauseEnd, endAt, 'Session ended',
            'Your pause ran out.');
      }
      if (mounted) setState(() {});
    } else {
      _openPaywall(); // out of free pauses → Pro
    }
  }

  void _resumeSession() {
    _controller.resume();
    _clearPause();
    _guard.focusing();
    if (!widget.previewMode) _notifs.cancelGraceAlerts(); // pause resolved
    _resetIdle();
    if (mounted) setState(() {});
  }

  void _startPauseWatch() {
    _pauseWatch?.cancel();
    _pauseWatch =
        Timer.periodic(const Duration(seconds: 1), (_) => _checkPauseCap());
  }

  void _clearPause() {
    _pauseWatch?.cancel();
    _pauseWatch = null;
    _pausedAt = null;
    _pauseCapHit = false;
  }

  /// Each second while paused: enforce the cap, then its 15 s grace.
  void _checkPauseCap() {
    if (_controller.state.status != SessionStatus.paused || _pausedAt == null) {
      _pauseWatch?.cancel();
      return;
    }
    final paused = _now().difference(_pausedAt!);
    if (_rules.endAfterPaused(paused)) {
      _clearPause();
      _controller.abandon(); // past the cap + grace → block ends
      _guard.stop();
    } else if (!_pauseCapHit && paused >= _rules.pauseCap) {
      _pauseCapHit = true; // entered the "return now" grace
    }
    if (mounted) setState(() {});
  }

  void _openPaywall() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      );

  /// The Pause/Resume control: a live "return now" countdown when a pause hits
  /// its cap, a locked Pro nudge when free pauses run out, else Pause + a quiet
  /// "N pauses left" line.
  Widget _pauseControl(bool paused, HgTokens hg) {
    if (paused) {
      final capTotal = _rules.pauseCap + _rules.capGrace;
      final remaining = _pausedAt == null
          ? 0
          : (capTotal - _now().difference(_pausedAt!)).inSeconds.clamp(0, 999);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_pauseCapHit) ...[
            Text(
              'Resume now — ${remaining}s to keep your block',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: HgFont.sans,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: hg.accent,
              ),
            ),
            const SizedBox(height: HgSpacing.sm),
          ],
          PrimaryButton(label: 'Resume', onPressed: _resumeSession),
        ],
      );
    }
    if (!_controller.canPause) {
      // Out of free pauses → a quiet, locked Pro nudge; the session keeps running.
      return GestureDetector(
        onTap: _openPaywall,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: hg.surfaceRaised,
                borderRadius: BorderRadius.circular(HgRadius.pill),
                border: Border.all(color: hg.hairline),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline_rounded,
                      size: HgSize.iconSm, color: hg.textMuted),
                  const SizedBox(width: HgSpacing.xs),
                  Text(
                    'Pause',
                    style: TextStyle(
                      fontFamily: HgFont.sans,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: hg.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: HgSpacing.xs),
            Text(
              'No pauses left — Pro gives unlimited',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: HgFont.sans, fontSize: 13, color: hg.accent),
            ),
          ],
        ),
      );
    }
    final remaining = _rules.remainingPauses(_controller.pauseCount);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PrimaryButton(label: 'Pause', onPressed: _pauseSession),
        if (remaining != null) ...[
          const SizedBox(height: HgSpacing.xs),
          Text(
            '$remaining pause${remaining == 1 ? '' : 's'} left',
            style: TextStyle(
                fontFamily: HgFont.sans, fontSize: 12, color: hg.textMuted),
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _flip.dispose();
    _pulse.dispose();
    _revealTimer?.cancel();
    _idleTimer?.cancel();
    _checkpointTimer?.cancel();
    _previewCapTimer?.cancel();
    _guardStartTimer?.cancel();
    _pauseWatch?.cancel();
    _guard.stop();
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

  void _revealTime({Duration hold = const Duration(seconds: 3), bool haptic = true}) {
    if (haptic) HapticFeedback.selectionClick();
    setState(() => _showTime = true);
    _revealTimer?.cancel();
    _revealTimer = Timer(hold, () {
      if (mounted) setState(() => _showTime = false);
    });
    _resetIdle();
  }

  Future<void> _confirmGiveUp() async {
    final isFlow = widget.config.mode == SessionMode.flowBlock;
    final mins = _controller.state.recordedFocus.inMinutes;
    // Ending after the goal (e.g. an endless block past its length) is a finish,
    // not a give-up — use positive copy.
    final reached = _controller.state.goalReached;
    final give = await _showGiveUpSheet(
      isFlow: isFlow,
      focusedMinutes: mins,
      reached: reached,
    );
    if (give == true) {
      HapticFeedback.selectionClick();
      _controller.end();
      if (!widget.previewMode) _notifs.cancelGraceAlerts(); // no stale pushes
    }
  }

  Future<bool?> _showGiveUpSheet({
    required bool isFlow,
    required int focusedMinutes,
    required bool reached,
  }) {
    final hg = context.hg;
    final String title = reached ? 'End this session?' : 'End this block?';
    final String confirmLabel = reached ? 'End session' : 'End block';
    final String body;
    if (reached) {
      body = "You've focused $focusedMinutes min — nicely done. It'll be saved.";
    } else if (isFlow) {
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
                title,
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
                  confirmLabel,
                  style: TextStyle(fontFamily: HgFont.sans, color: hg.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Quick mid-session settings — change theme and the controls relevant to THIS
  /// session's mode (endless for a Flow Block; auto-advance only when the plan
  /// has breaks). Changes apply to the live session immediately.
  void _openQuickSettings() {
    final hg = context.hg;
    final isFlow = widget.config.mode == SessionMode.flowBlock;
    final hasBreaks = widget.config.plan.segments.any((seg) => !seg.isFocus);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: hg.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(HgRadius.lg)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setSheet) {
          final mode = ref.read(themeControllerProvider).mode;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  HgSpacing.lg, HgSpacing.lg, HgSpacing.lg, HgSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Quick settings',
                      style: TextStyle(
                        fontFamily: HgFont.sans,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: hg.textPrimary,
                      )),
                  const SizedBox(height: HgSpacing.md),
                  Text('THEME',
                      style: TextStyle(
                        fontFamily: HgFont.sans,
                        fontSize: 11,
                        letterSpacing: 2,
                        color: hg.textMuted,
                      )),
                  const SizedBox(height: HgSpacing.xs),
                  Row(
                    children: [
                      for (final m in ThemeMode.values)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: HgSpacing.xs),
                            child: _ModeChip(
                              label: switch (m) {
                                ThemeMode.system => 'Auto',
                                ThemeMode.light => 'Light',
                                ThemeMode.dark => 'Dark',
                              },
                              selected: m == mode,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                ref
                                    .read(themeControllerProvider.notifier)
                                    .setMode(m);
                                setSheet(() {});
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                  // Flow Block → endless toggle (no breaks to auto-advance).
                  if (isFlow) ...[
                    const SizedBox(height: HgSpacing.lg),
                    _QuickToggle(
                      title: "Don't stop — run until I end",
                      subtitle: _controller.isEndless
                          ? 'This block keeps running until you tap End.'
                          : 'This block stops at its set length.',
                      value: _controller.isEndless,
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        if (v) {
                          _controller.enableEndless();
                        } else {
                          _controller.disableEndless();
                        }
                        setSheet(() {});
                      },
                    ),
                  ]
                  // Pomodoro/Custom with breaks → auto-advance.
                  else if (hasBreaks) ...[
                    const SizedBox(height: HgSpacing.lg),
                    _QuickToggle(
                      title: 'Auto-start next block',
                      subtitle: _controller.autoAdvanceBreaks
                          ? 'Next block begins on its own after a break.'
                          : 'You tap to start the next block after a break.',
                      value: _controller.autoAdvanceBreaks,
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        _controller.setAutoAdvanceBreaks(v);
                        setSheet(() {});
                      },
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _controller.state;
    // In preview, ANY ending (the ~10s cap, or give-up) shows the preview
    // prompt, never the real completion/score screen.
    final previewDone = widget.previewMode &&
        (_previewEnded ||
            s.status == SessionStatus.finished ||
            s.status == SessionStatus.completed);
    final terminal = previewDone ||
        s.status == SessionStatus.completed ||
        s.status == SessionStatus.finished;
    // Ending a session returns all the way to Home (not back to Setup).
    void goHome() => Navigator.of(context).popUntil((r) => r.isFirst);
    final Widget view = previewDone
        ? _previewEndView(goHome)
        : switch (s.status) {
            SessionStatus.finished => _Completion(
                key: const ValueKey('done'),
                record: _record,
                config: widget.config,
                canKeepGoing: false,
                onDone: goHome,
              ),
            SessionStatus.completed => _Completion(
                key: const ValueKey('completed'),
                record: _record,
                config: widget.config,
                canKeepGoing: true,
                onKeepGoing: _onKeepGoing,
                onDone: goHome,
              ),
            SessionStatus.awaitingResume => _awaitingView(s),
            _ => s.isResting ? _restView(s) : _focusView(s),
          };

    return PopScope(
      // Back is intercepted: mid-session it confirms (abandon = give up); on a
      // completion screen it returns to Home, never to Setup.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (terminal) {
          goHome();
        } else {
          _confirmGiveUp();
        }
      },
      child: Listener(
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
      ),
    );
  }

  // ── Theme preview ending ────────────────────────────────────────────────────
  /// Shown when a capped theme-preview session ends: the frozen themed hourglass
  /// plus a gentle buy/exit prompt. Nothing was recorded.
  Widget _previewEndView(VoidCallback goHome) {
    final hg = context.hg;
    final previewId = ref.watch(previewThemeProvider);
    final name = HgThemes.byId(previewId ?? 'sand').name;
    return Padding(
      key: const ValueKey('preview-end'),
      padding: const EdgeInsets.symmetric(horizontal: HgSpacing.screen),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 140,
            child: HourglassView(
              progress: 0.5,
              animate: false,
              skin: ref
                  .watch(activeThemeProvider)
                  .skinFor(Theme.of(context).brightness),
            ),
          ),
          const SizedBox(height: HgSpacing.xl),
          Text(
            'Enjoying $name?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: HgFont.serif,
              fontSize: 24,
              color: hg.textPrimary,
            ),
          ),
          const SizedBox(height: HgSpacing.sm),
          Text(
            'This was a quick preview, so nothing was recorded. Unlock the theme '
            'to focus in it for real.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: HgFont.sans,
              fontSize: 14,
              color: hg.textSecondary,
            ),
          ),
          const SizedBox(height: HgSpacing.xl),
          PrimaryButton(
            label: 'Get it',
            onPressed: () {
              goHome();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ThemesScreen()),
              );
            },
          ),
          const SizedBox(height: HgSpacing.sm),
          TextButton(
            onPressed: () {
              ref.read(previewThemeProvider.notifier).clear();
              goHome();
            },
            child: Text(
              'Exit preview',
              style: TextStyle(
                fontFamily: HgFont.sans,
                color: hg.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Focus ──────────────────────────────────────────────────────────────────
  Widget _focusView(SessionState s) {
    final hg = context.hg;
    final paused = s.status == SessionStatus.paused;
    final struggle = s.phase == FocusPhase.struggle && !paused;
    final isFlow = widget.config.mode == SessionMode.flowBlock;
    final score = ref.watch(focusScoreProvider).asData?.value;

    // Everything except the hourglass dims when idle (calm, ambient) — but a
    // paused session stays fully lit so "PAUSED" and the time read clearly.
    final chrome = (_dimmed && !paused) ? 0.18 : 1.0;

    // Center of the top bar: the overall Focus Score (flow) or the block label.
    final Widget topCenter = (isFlow && score != null)
        ? Text(
            'FOCUS · $score',
            style: TextStyle(
              fontFamily: HgFont.sans,
              fontSize: 12,
              letterSpacing: 1,
              fontWeight: FontWeight.w600,
              color: hg.textMuted,
            ),
          )
        : Text(
            _segmentLabel(),
            style: TextStyle(
              fontFamily: HgFont.sans,
              fontSize: 12,
              letterSpacing: 1,
              color: hg.textMuted,
            ),
          );

    return Padding(
      key: const ValueKey('focus'),
      padding: const EdgeInsets.symmetric(horizontal: HgSpacing.screen),
      child: Column(
        children: [
          const SizedBox(height: HgSpacing.sm),
          AnimatedOpacity(
            opacity: chrome,
            duration: HgMotion.medium,
            // Stack so the center label is TRULY screen-centered regardless of
            // the (unequal) widths of the gear and the give-up button.
            child: SizedBox(
              height: 44,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: _openQuickSettings,
                      icon: const Icon(Icons.tune_rounded),
                      iconSize: HgSize.iconSm,
                      color: hg.textMuted,
                      tooltip: 'Quick settings',
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  Align(alignment: Alignment.center, child: topCenter),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _confirmGiveUp,
                      child: Text(
                        _controller.isEndless ? 'End' : 'Give up',
                        style: TextStyle(
                            fontFamily: HgFont.sans, color: hg.textMuted),
                      ),
                    ),
                  ),
                ],
              ),
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
                // Struggle reframe, or a bold, unmissable "PAUSED" while paused.
                SizedBox(
                  height: 48,
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: (struggle || paused) ? 1 : 0,
                      duration: HgMotion.slow,
                      child: Text(
                        paused
                            ? 'PAUSED'
                            : 'The first few minutes are the hard part — stay with it.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: HgFont.sans,
                          fontSize: paused ? 28 : 13,
                          fontWeight:
                              paused ? FontWeight.w700 : FontWeight.normal,
                          fontStyle:
                              paused ? FontStyle.normal : FontStyle.italic,
                          letterSpacing: paused ? 5 : 0,
                          color: hg.accent,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Glanced time — large readout ABOVE the hourglass. Normally fades
          // after a tap; while PAUSED it stays on constantly (reverts on resume).
          SizedBox(
            height: 56,
            child: AnimatedOpacity(
              opacity: (_showTime || paused) ? 1 : 0,
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
                        skin: ref
                            .watch(activeThemeProvider)
                            .skinFor(Theme.of(context).brightness),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // "Don't stop" nudge — appears in the last stretch of a fixed Flow
          // Block so the user can flow past the mark instead of stopping.
          _endlessNudge(s, hg),
          const SizedBox(height: HgSpacing.lg),
          AnimatedOpacity(
            opacity: chrome,
            duration: HgMotion.medium,
            child: _pauseControl(paused, hg),
          ),
          const SizedBox(height: HgSpacing.xl),
        ],
      ),
    );
  }

  /// A gently pulsing "let it run / don't stop" affordance shown only in the
  /// final stretch of a fixed Flow Block (turns the block open-ended).
  Widget _endlessNudge(SessionState s, HgTokens hg) {
    final isFlow = widget.config.mode == SessionMode.flowBlock;
    final remaining = _controller.segmentRemaining.inSeconds;
    final show = isFlow &&
        !_controller.isEndless &&
        s.status == SessionStatus.running &&
        remaining > 0 &&
        remaining <= 60;
    if (!show) return const SizedBox(height: HgSpacing.sm);
    return Padding(
      padding: const EdgeInsets.only(bottom: HgSpacing.sm),
      child: FadeTransition(
        opacity: Tween(begin: 0.55, end: 1.0).animate(_pulse),
        child: OutlinedButton(
          onPressed: () {
            HapticFeedback.selectionClick();
            _controller.enableEndless();
            setState(() {});
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: hg.accent,
            side: BorderSide(color: hg.accent.withValues(alpha: 0.6)),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(
                horizontal: HgSpacing.lg, vertical: HgSpacing.sm),
          ),
          child: const Text("Don't stop — keep flowing"),
        ),
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

/// Human focused-time label with seconds precision: "25m", "2m 1s", "45s".
String _focusedLabel(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;
  final parts = <String>[
    if (h > 0) '${h}h',
    if (m > 0) '${m}m',
    if (s > 0 || (h == 0 && m == 0)) '${s}s',
  ];
  return parts.join(' ');
}

/// A small selectable theme-mode chip for the quick-settings sheet.
class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(HgRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: HgSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? hg.accentMuted : Colors.transparent,
          borderRadius: BorderRadius.circular(HgRadius.pill),
          border: Border.all(
            color: selected ? hg.accent : hg.hairline,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: HgFont.sans,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? hg.accent : hg.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// A labelled switch row for the quick-settings sheet.
class _QuickToggle extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _QuickToggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                    fontFamily: HgFont.sans,
                    fontSize: 15,
                    color: hg.textPrimary,
                  )),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(
                    fontFamily: HgFont.sans,
                    fontSize: 12,
                    color: hg.textMuted,
                  )),
            ],
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: hg.accent,
          onChanged: onChanged,
        ),
      ],
    );
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
    final focused = record?.recordedFocus ?? Duration.zero;
    final hasFocus = focused.inSeconds > 0;
    final isFlow = config.mode == SessionMode.flowBlock;
    // A Flow block only counts (score, streak, average) once it reaches 2 min.
    final flowCounts = isFlow && focused.inSeconds >= 120;
    final subTwoMinFlow = isFlow && hasFocus && focused.inSeconds < 120;
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
            child: SizedBox(
              width: 140,
              child: HourglassView(
                progress: 1,
                animate: false,
                skin: ref
                    .watch(activeThemeProvider)
                    .skinFor(Theme.of(context).brightness),
              ),
            ),
          ),
          const SizedBox(height: HgSpacing.xl),
          if (flowCounts) ...[
            // Hero = THIS session's score (it visibly changes block to block).
            Text(
              'SESSION SCORE',
              style: TextStyle(
                fontFamily: HgFont.sans,
                fontSize: 11,
                letterSpacing: 2,
                color: hg.textMuted,
              ),
            ),
            const SizedBox(height: HgSpacing.xs),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: sessionPoints.toDouble()),
              duration: const Duration(milliseconds: 900),
              curve: HgMotion.calm,
              builder: (_, v, _) => Text(
                '${v.round()}',
                style: TextStyle(
                  fontFamily: HgFont.sans,
                  fontSize: 64,
                  fontWeight: FontWeight.w600,
                  color: hg.accent,
                ),
              ),
            ),
            const SizedBox(height: HgSpacing.sm),
            Text(
              '${_focusedLabel(focused)} focused',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: HgFont.sans,
                fontSize: 15,
                color: hg.textSecondary,
              ),
            ),
            const SizedBox(height: HgSpacing.xs),
            // The overall Focus Score (your standing) — updates on Home.
            Text(
              score != null
                  ? 'Focus Score · $score'
                  : 'Focus Score · …',
              style: TextStyle(
                fontFamily: HgFont.sans,
                fontSize: 13,
                color: hg.textMuted,
              ),
            ),
          ] else ...[
            Text(
              hasFocus
                  ? '${_focusedLabel(focused)} focused'
                  : (canKeepGoing ? 'Block complete' : 'Session ended'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: HgFont.sans,
                fontSize: 26,
                fontWeight: FontWeight.w400,
                color: hg.textPrimary,
              ),
            ),
            if (subTwoMinFlow) ...[
              const SizedBox(height: HgSpacing.lg),
              Container(
                padding: const EdgeInsets.all(HgSpacing.md),
                decoration: BoxDecoration(
                  color: hg.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(HgRadius.md),
                  border: Border.all(color: hg.accent.withValues(alpha: 0.28)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 18, color: hg.accent),
                        const SizedBox(width: HgSpacing.xs),
                        Text(
                          'Under 2 minutes',
                          style: TextStyle(
                            fontFamily: HgFont.sans,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: hg.accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: HgSpacing.sm),
                    const _SummaryPoint(
                        "This block won't count toward your Focus Score."),
                    const _SummaryPoint(
                        "It won't count toward your average focus either."),
                    const _SummaryPoint(
                        'Stay a few minutes longer next time and it will.'),
                  ],
                ),
              ),
            ],
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

/// A single prominent bullet in the completion screen's "why this didn't count"
/// callout — a small accent dot + readable line.
class _SummaryPoint extends StatelessWidget {
  final String text;
  const _SummaryPoint(this.text);

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return Padding(
      padding: const EdgeInsets.only(bottom: HgSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: hg.accent, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: HgSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: HgFont.sans,
                fontSize: 14,
                height: 1.4,
                color: hg.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
