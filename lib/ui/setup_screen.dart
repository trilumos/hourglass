import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../app/theme.dart';
import '../app/tokens.dart';
import '../domain/session_mode.dart';
import '../domain/stamina_calculator.dart';
import '../session/session_config.dart';
import '../session/session_plan.dart';
import 'session_screen.dart';
import 'widgets/primary_button.dart';
import 'widgets/screen_background.dart';

/// A Pomodoro work/break ratio preset.
class _Ratio {
  final int work;
  final int short;
  final int long;
  const _Ratio(this.work, this.short, this.long);
  String get label => '$work/$short';
}

const _ratios = [
  _Ratio(25, 5, 15),
  _Ratio(50, 10, 20),
  _Ratio(52, 17, 25),
  _Ratio(90, 15, 30),
];

enum _PomoEntry { duration, blocks }

enum _CustomMode { count, interval }

Duration _m(int min) => Duration(minutes: min);

String _fmt(Duration d) {
  final h = d.inHours;
  final mm = d.inMinutes % 60;
  if (h == 0) return '${mm}m';
  if (mm == 0) return '${h}h';
  return '${h}h ${mm}m';
}

/// Build a session plan for the chosen mode, then begin. Layout hierarchy:
/// total duration (big) → focus time (stepper) → configuration.
class SetupScreen extends ConsumerStatefulWidget {
  final SessionMode mode;
  const SetupScreen({super.key, required this.mode});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  // The ~90-min deep-work reference (shared with stamina). A soft guide, not a
  // hard limit — longer blocks are allowed (+5 / endless).
  static final _flowSoftCap = StaminaCalculator.referenceBlock.inMinutes;
  static const _longEvery = 4;

  final _intention = TextEditingController();
  bool _endless = false;

  // Flow
  int? _flowMinutes;

  /// Focus Stamina, refreshed from [staminaProvider] each build. [_staminaMin]
  /// is meaningful only once [_staminaEstablished]; until the first eligible
  /// Flow session the stamina chip is shown locked.
  bool _staminaEstablished = false;
  int _staminaMin = StaminaCalculator.defaultStart.inMinutes;

  /// The Flow length used before stamina is established (a plain starting block,
  /// not labelled as stamina).
  static const _defaultFlowMin = 25;

  /// The pre-selected Flow length: your stamina once earned, else the default.
  int get _flowDefault => _staminaEstablished ? _staminaMin : _defaultFlowMin;

  // Pomodoro
  _PomoEntry _pomoEntry = _PomoEntry.duration;
  int _ratioIndex = 0;
  int _blocks = 4; // by-blocks: explicit block count (fixed-length blocks)
  int _pomoTarget = 120; // by-duration: chosen focus time (min) — exact, never auto-changes
  int _durBlocks = 4; // by-duration: how many variable-length blocks to split into

  // Custom
  _CustomMode _customMode = _CustomMode.count;
  int _customWork = 120; // total focus minutes
  int _customBreaks = 3;
  int _customInterval = 30;
  int _customBreakLen = 10;

  SessionMode get _mode => widget.mode;

  static const _titles = {
    SessionMode.flowBlock: 'Flow',
    SessionMode.pomodoro: 'Pomodoro',
    SessionMode.custom: 'Custom',
  };

  void _tap(VoidCallback f) {
    HapticFeedback.selectionClick();
    setState(f);
  }

  /// One-line "what is this mode" under the title.
  String _modeDescription() => switch (_mode) {
        SessionMode.flowBlock =>
          'One unbroken block of deep focus — recovery comes after.',
        SessionMode.pomodoro => 'Focus in cycles with short breaks between.',
        SessionMode.custom => 'Design your own focus-and-break schedule.',
      };

  /// Helper under the Pomodoro entry toggle.
  String _pomodoroHint() => _pomoEntry == _PomoEntry.duration
      ? 'Set your exact focus time — we split it into blocks with rests.'
      : 'Pick a classic work/break length and how many blocks.';

  /// Helper under the Custom breaks toggle.
  String _customBreaksHint() => _customMode == _CustomMode.count
      ? 'Choose how many breaks — spread evenly through your focus.'
      : 'Take a break every set interval of focus.';

  SessionPlan _buildPlan() {
    switch (_mode) {
      case SessionMode.flowBlock:
        return SessionPlan.flowBlock(_m(_flowMinutes ?? _flowDefault));
      case SessionMode.pomodoro:
        if (_pomoEntry == _PomoEntry.duration) {
          // Flowmodoro: exact focus time split into variable-length blocks.
          return SessionPlan.flowmodoro(
            totalFocus: _m(_pomoTarget),
            blocks: _durBlocks,
          );
        }
        final r = _ratios[_ratioIndex];
        return SessionPlan.pomodoro(
          work: _m(r.work),
          shortBreak: _m(r.short),
          longBreak: _m(r.long),
          blocks: _blocks,
          longEvery: _longEvery,
        );
      case SessionMode.custom:
        return _customMode == _CustomMode.count
            ? SessionPlan.customByCount(
                totalWork: _m(_customWork),
                breaks: _customBreaks,
                breakDuration: _m(_customBreakLen),
              )
            : SessionPlan.customByInterval(
                totalWork: _m(_customWork),
                intervalWork: _m(_customInterval),
                breakDuration: _m(_customBreakLen),
              );
    }
  }

  bool get _endlessAvailable =>
      _mode != SessionMode.pomodoro && _buildPlan().isSingleFocus;

  Future<void> _begin() async {
    HapticFeedback.lightImpact();
    // Honor user preferences (break-advance + run-flow-until-ended default).
    final autoAdvanceBreaks = await ref.read(breakAutoAdvanceProvider.future);
    final flowRunUntilEnded = await ref.read(flowRunUntilEndedProvider.future);
    if (!mounted) return;
    final plan = _buildPlan();
    // Flow Blocks run open-ended if the per-session toggle is on OR the global
    // "run until I end" preference is on.
    final endless = (_endlessAvailable && _endless) ||
        (_mode == SessionMode.flowBlock && flowRunUntilEnded);
    final config = SessionConfig(
      mode: _mode,
      plan: plan,
      autoContinue: endless,
      autoAdvanceBreaks: autoAdvanceBreaks,
      intention: _intention.text.trim(),
      soundscape: 'sand',
      skinId: 'classic',
    );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SessionScreen(config: config)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    final info = ref.watch(staminaProvider).asData?.value;
    _staminaEstablished = info?.established ?? false;
    _staminaMin =
        info?.value.inMinutes ?? StaminaCalculator.defaultStart.inMinutes;
    final plan = _buildPlan();
    final topLabel = _mode == SessionMode.flowBlock ? 'BLOCK LENGTH' : 'TOTAL TIME';
    // Custom has the most controls — tighten its section gaps so it fits without
    // scrolling on a normal phone (the ListView still scrolls for large fonts).
    final sectionGap =
        _mode == SessionMode.custom ? HgSpacing.lg : HgSpacing.xl;

    return Scaffold(
      body: ScreenBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: HgSpacing.sm),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: HgSpacing.screen),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: hg.textSecondary,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(width: HgSpacing.sm),
                    Text(
                      _titles[_mode]!,
                      style: TextStyle(
                        fontFamily: HgFont.sans,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: hg.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(HgSpacing.screen,
                      HgSpacing.lg, HgSpacing.screen, HgSpacing.lg),
                  children: [
                    _Label('Intention'),
                    const SizedBox(height: HgSpacing.sm),
                    TextField(
                      controller: _intention,
                      style: TextStyle(
                          fontFamily: HgFont.sans,
                          fontSize: 22,
                          color: hg.textPrimary),
                      cursorColor: hg.accent,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        hintText: 'What are you focusing on?',
                        hintStyle: TextStyle(
                            fontFamily: HgFont.sans,
                            fontSize: 22,
                            color: hg.textMuted),
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: HgSpacing.sm),
                        enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: hg.hairline)),
                        focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: hg.accent)),
                      ),
                    ),
                    SizedBox(height: sectionGap),

                    // Hierarchy: TOTAL (big) → subline → focus time → config.
                    Center(child: _CenteredLabel(topLabel)),
                    const SizedBox(height: HgSpacing.sm),
                    Center(child: _BigDuration(plan.totalDuration)),
                    const SizedBox(height: HgSpacing.sm),
                    // Full width so a long cadence line wraps to 2 rows.
                    SizedBox(width: double.infinity, child: _subline(hg, plan)),
                    SizedBox(height: sectionGap),
                    ..._modeControls(hg),

                    if (_endlessAvailable) ...[
                      const SizedBox(height: HgSpacing.lg),
                      _EndlessToggle(
                        value: _endless,
                        onChanged: (v) => _tap(() => _endless = v),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    HgSpacing.screen, 0, HgSpacing.screen, HgSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _modeDescription(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: HgFont.sans,
                        fontSize: 13,
                        height: 1.35,
                        fontStyle: FontStyle.italic,
                        color: hg.textMuted,
                      ),
                    ),
                    const SizedBox(height: HgSpacing.md),
                    PrimaryButton(label: 'Begin', onPressed: _begin),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _modeControls(HgTokens hg) {
    switch (_mode) {
      case SessionMode.flowBlock:
        return _flowControls(hg);
      case SessionMode.pomodoro:
        return _pomodoroControls(hg);
      case SessionMode.custom:
        return _customControls(hg);
    }
  }

  List<Widget> _flowControls(HgTokens hg) {
    final minutes = _flowMinutes ?? _flowDefault;
    // Fixed presets, minus any that coincide with the (earned) stamina anchor.
    final fixed = ({15, 25, 30, 45, 60, 90}
          ..removeWhere((m) =>
              m > _flowSoftCap || (_staminaEstablished && m == _staminaMin)))
        .toList()
      ..sort();
    return [
      const _SectionHeading('Length'),
      const SizedBox(height: HgSpacing.sm),
      _Hint(_staminaEstablished
          ? 'Your stamina is ${_staminaMin}m. Finish a block to hold it; '
              'go past it (Endless, or +5 near the end) to grow it.'
          : 'Your stamina sets after your first recorded Flow session, '
              'then grows with you.'),
      const SizedBox(height: HgSpacing.md),
      Wrap(
        spacing: HgSpacing.sm,
        runSpacing: HgSpacing.sm,
        children: [
          // Shown always; locked (inaccessible) until stamina is established.
          _Chip(
            label: _staminaEstablished ? 'Stamina · ${_staminaMin}m' : 'Stamina',
            active: _staminaEstablished && minutes == _staminaMin,
            enabled: _staminaEstablished,
            icon: _staminaEstablished ? null : Icons.lock_outline_rounded,
            onTap: () => _tap(() => _flowMinutes = _staminaMin),
          ),
          for (final mm in fixed)
            _Chip(
              label: '$mm min',
              active: mm == minutes,
              onTap: () => _tap(() => _flowMinutes = mm),
            ),
          _Chip(
            label: '+5',
            active: false,
            outline: true,
            onTap: () => _tap(() => _flowMinutes = (minutes + 5).clamp(5, 240)),
          ),
        ],
      ),
    ];
  }

  List<Widget> _pomodoroControls(HgTokens hg) {
    return [
      _SubToggle(
        options: const ['By duration', 'By blocks'],
        selectedIndex: _pomoEntry.index,
        onChanged: (i) => _tap(() => _pomoEntry = _PomoEntry.values[i]),
      ),
      const SizedBox(height: HgSpacing.sm),
      _Hint(_pomodoroHint()),
      const SizedBox(height: HgSpacing.lg),
      if (_pomoEntry == _PomoEntry.duration) ...[
        // Exact focus time → split into N variable-length blocks (rests ~5:1).
        _LabeledStepper(
          label: 'Focus time',
          value: _fmt(_m(_pomoTarget)),
          onMinus: _pomoTarget > 30 ? () => _tap(() => _pomoTarget -= 15) : null,
          onPlus: _pomoTarget < 360 ? () => _tap(() => _pomoTarget += 15) : null,
        ),
        const SizedBox(height: HgSpacing.lg),
        _LabeledStepper(
          label: 'Blocks',
          value: '$_durBlocks',
          onMinus: _durBlocks > 1 ? () => _tap(() => _durBlocks--) : null,
          onPlus: _durBlocks < 12 ? () => _tap(() => _durBlocks++) : null,
        ),
      ] else ...[
        _LabeledStepper(
          label: 'Focus blocks',
          value: '$_blocks',
          onMinus: _blocks > 1 ? () => _tap(() => _blocks--) : null,
          onPlus: _blocks < 16 ? () => _tap(() => _blocks++) : null,
        ),
        const SizedBox(height: HgSpacing.lg),
        const _SectionHeading('Work / break per block'),
        const SizedBox(height: HgSpacing.md),
        Wrap(
          spacing: HgSpacing.sm,
          runSpacing: HgSpacing.sm,
          children: [
            for (var i = 0; i < _ratios.length; i++)
              _Chip(
                label: _ratios[i].label,
                active: i == _ratioIndex,
                onTap: () => _tap(() => _ratioIndex = i),
              ),
          ],
        ),
      ],
    ];
  }

  List<Widget> _customControls(HgTokens hg) {
    return [
      _LabeledStepper(
        label: 'Focus time',
        value: _fmt(_m(_customWork)),
        onMinus: _customWork > 15 ? () => _tap(() => _customWork -= 15) : null,
        onPlus: _customWork < 480 ? () => _tap(() => _customWork += 15) : null,
      ),
      const SizedBox(height: HgSpacing.xl),
      const _SectionHeading('Break schedule'),
      const SizedBox(height: HgSpacing.md),
      _SubToggle(
        options: const ['By count', 'By interval'],
        selectedIndex: _customMode.index,
        onChanged: (i) => _tap(() => _customMode = _CustomMode.values[i]),
      ),
      const SizedBox(height: HgSpacing.sm),
      _Hint(_customBreaksHint()),
      const SizedBox(height: HgSpacing.lg),
      if (_customMode == _CustomMode.count)
        _LabeledStepper(
          label: 'Number of breaks',
          value: '$_customBreaks',
          onMinus: _customBreaks > 0 ? () => _tap(() => _customBreaks--) : null,
          onPlus: (_customBreaks < 12 &&
                  _customWork ~/ (_customBreaks + 2) >= 5)
              ? () => _tap(() => _customBreaks++)
              : null,
        )
      else
        _LabeledStepper(
          label: 'Break every',
          value: _fmt(_m(_customInterval)),
          onMinus: _customInterval > 10
              ? () => _tap(() => _customInterval -= 5)
              : null,
          onPlus: _customInterval < 120
              ? () => _tap(() => _customInterval += 5)
              : null,
        ),
      const SizedBox(height: HgSpacing.lg),
      _LabeledStepper(
        label: 'Break length',
        value: _fmt(_m(_customBreakLen)),
        onMinus:
            _customBreakLen > 1 ? () => _tap(() => _customBreakLen -= 1) : null,
        onPlus:
            _customBreakLen < 30 ? () => _tap(() => _customBreakLen += 1) : null,
      ),
    ];
  }

  /// Accurate cadence description read back from the generated plan.
  Widget _subline(HgTokens hg, SessionPlan plan) {
    String text;
    Color color = hg.accent;
    switch (_mode) {
      case SessionMode.flowBlock:
        final minutes = _flowMinutes ?? _flowDefault;
        // Only caution past ~90 when reaching BEYOND proven stamina — if a long
        // block is the user's own demonstrated stamina, it isn't a stretch.
        final beyondProven = minutes > _flowSoftCap &&
            !(_staminaEstablished && minutes == _staminaMin);
        if (beyondProven) {
          text = 'Past ~90 min, focus tends to fade. A fresh block after a '
              'break often serves you better.';
          color = hg.warning;
        } else {
          text = 'One unbroken block, recovery after · finish it to hold your '
              'stamina, pass it to grow.';
          color = hg.textMuted;
        }
      case SessionMode.pomodoro:
        if (_pomoEntry == _PomoEntry.duration) {
          final focus = plan.segments.where((s) => s.isFocus).toList();
          final rests = plan.segments.where((s) => !s.isFocus).toList();
          if (rests.isEmpty) {
            text = 'One ${_fmt(plan.totalFocus)} block · no breaks';
          } else {
            final avg = (plan.totalFocus.inMinutes / focus.length).round();
            text = '${focus.length} × ~${avg}m focus + '
                '${rests.first.duration.inMinutes}m break';
          }
          break;
        }
        final r = _ratios[_ratioIndex];
        text = '${plan.focusCount} rounds of ${r.work}m focus + ${r.short}m break';
        if (plan.focusCount > _longEvery) {
          // Long-break note on its own row.
          text += '\n${r.long}m long break every ${_longEvery}th';
        }
      case SessionMode.custom:
        final focus = plan.segments.where((s) => s.isFocus).toList();
        final rests = plan.segments.where((s) => !s.isFocus).toList();
        if (rests.isEmpty) {
          text = 'One ${_fmt(plan.totalFocus)} block · no breaks';
        } else {
          final allEqual = focus.every((s) =>
              s.duration.inMinutes == focus.first.duration.inMinutes);
          final avg = (plan.totalFocus.inMinutes / focus.length).round();
          final focusPart = allEqual
              ? '${focus.length} × ${focus.first.duration.inMinutes}m focus'
              : '${focus.length} × ~${avg}m focus';
          text = '$focusPart · ${rests.length} × '
              '${rests.first.duration.inMinutes}m break';
        }
    }
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: HgFont.sans,
        fontSize: 13,
        height: 1.4,
        color: color,
      ),
    );
  }
}

// ── Shared sub-widgets ──────────────────────────────────────────────────────

class _BigDuration extends StatelessWidget {
  final Duration d;
  const _BigDuration(this.d);

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    final h = d.inHours;
    final mm = d.inMinutes % 60;
    final numStyle = TextStyle(
      fontFamily: HgFont.sans,
      fontSize: 72,
      fontWeight: FontWeight.w300,
      height: 1.0,
      letterSpacing: -2,
      color: hg.textPrimary,
    );
    final unitStyle =
        TextStyle(fontFamily: HgFont.sans, fontSize: 18, color: hg.textMuted);
    final parts = <Widget>[];
    if (h > 0) {
      parts.addAll([Text('$h', style: numStyle), Text('h', style: unitStyle)]);
      if (mm > 0) {
        parts.add(const SizedBox(width: HgSpacing.sm));
        parts.addAll(
            [Text('$mm', style: numStyle), Text('m', style: unitStyle)]);
      }
    } else {
      parts.addAll([
        Text('$mm', style: numStyle),
        const SizedBox(width: HgSpacing.sm),
        Text('min', style: unitStyle),
      ]);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: parts,
    );
  }
}

class _SubToggle extends StatelessWidget {
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  const _SubToggle({
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return Container(
      padding: const EdgeInsets.all(HgSpacing.xs),
      decoration: BoxDecoration(
        color: hg.surface,
        borderRadius: BorderRadius.circular(HgRadius.pill),
      ),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: HgMotion.fast,
                  curve: HgMotion.calm,
                  padding:
                      const EdgeInsets.symmetric(vertical: HgSpacing.sm + 2),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == selectedIndex ? hg.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(HgRadius.pill),
                  ),
                  child: Text(
                    options[i],
                    style: TextStyle(
                      fontFamily: HgFont.sans,
                      fontSize: 13,
                      fontWeight: i == selectedIndex
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: i == selectedIndex ? hg.onAccent : hg.textMuted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LabeledStepper extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;
  const _LabeledStepper({
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
                fontFamily: HgFont.sans, fontSize: 16, color: hg.textPrimary),
          ),
        ),
        _StepButton(icon: Icons.remove_rounded, onTap: onMinus),
        SizedBox(
          width: 92,
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: HgFont.sans,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: hg.textPrimary,
            ),
          ),
        ),
        _StepButton(icon: Icons.add_rounded, onTap: onPlus),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: hg.hairline),
        ),
        child: Icon(
          icon,
          size: HgSize.iconMd,
          color: onTap != null ? hg.textPrimary : hg.textMuted,
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontFamily: HgFont.sans,
        fontSize: 11,
        letterSpacing: 2,
        fontWeight: FontWeight.w600,
        color: context.hg.textMuted,
      ),
    );
  }
}

/// A small muted helper line explaining a control/option.
class _Hint extends StatelessWidget {
  final String text;
  const _Hint(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: HgFont.sans,
        fontSize: 12,
        height: 1.35,
        color: context.hg.textMuted,
      ),
    );
  }
}

/// A descriptive, friendly section heading (matches the "Focus time" register).
class _SectionHeading extends StatelessWidget {
  final String text;
  const _SectionHeading(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: HgFont.sans,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: context.hg.textPrimary,
      ),
    );
  }
}

class _CenteredLabel extends StatelessWidget {
  final String text;
  const _CenteredLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: HgFont.sans,
        fontSize: 11,
        letterSpacing: 2,
        fontWeight: FontWeight.w600,
        color: context.hg.textMuted,
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final bool outline;

  /// When false the chip is shown but inaccessible (greyed, ignores taps).
  final bool enabled;

  /// Optional leading glyph (e.g. a lock on the not-yet-earned stamina chip).
  final IconData? icon;
  final VoidCallback onTap;
  const _Chip({
    required this.label,
    required this.active,
    required this.onTap,
    this.outline = false,
    this.enabled = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    final Color fg = !enabled
        ? hg.textMuted
        : active
            ? hg.onAccent
            : (outline ? hg.textMuted : hg.textSecondary);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: HgMotion.fast,
        curve: HgMotion.calm,
        padding: const EdgeInsets.symmetric(
            horizontal: HgSpacing.md, vertical: HgSpacing.sm + 2),
        decoration: BoxDecoration(
          color: active && enabled ? hg.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(HgRadius.pill),
          border: Border.all(color: active && enabled ? hg.accent : hg.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: fg),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: HgFont.sans,
                fontSize: 14,
                fontWeight: active && enabled
                    ? FontWeight.w600
                    : FontWeight.w400,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EndlessToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _EndlessToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Endless flow',
                  style: TextStyle(
                      fontFamily: HgFont.sans,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: hg.textPrimary)),
              const SizedBox(height: 2),
              Text('Keep going past the goal until you stop.',
                  style: TextStyle(
                      fontFamily: HgFont.sans,
                      fontSize: 13,
                      color: hg.textMuted)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: hg.onAccent,
          activeTrackColor: hg.accent,
          inactiveThumbColor: hg.textMuted,
          inactiveTrackColor: hg.surface,
        ),
      ],
    );
  }
}
