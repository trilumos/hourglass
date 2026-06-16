import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../app/theme.dart';
import '../app/tokens.dart';
import '../domain/session_mode.dart';
import '../session/session_config.dart';
import 'widgets/primary_button.dart';
import 'widgets/screen_background.dart';

/// Set the intention and length for a block, then begin. Mode is fixed (chosen
/// on Home) and shown as the title; the length control differs per mode:
/// Flow Block = stamina-suggested presets (+5 can exceed 90 with a warning),
/// Pomodoro = a work-time stepper with an auto-derived break,
/// Custom = a free stepper for any length (up to 4h). The big duration readout
/// is the focal element.
class SetupScreen extends ConsumerStatefulWidget {
  final SessionMode mode;
  const SetupScreen({super.key, required this.mode});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  static const _maxMinutes = 240; // 4 hours
  static const _flowSoftCap = 90; // beyond this we warn

  final _intention = TextEditingController();
  int? _selectedMinutes;
  bool _endless = false;

  SessionMode get _mode => widget.mode;

  static const _titles = {
    SessionMode.flowBlock: 'Flow Block',
    SessionMode.pomodoro: 'Pomodoro',
    SessionMode.custom: 'Custom',
  };

  /// Pomodoro break auto-derived from work time (~5:1, kept sane).
  int _breakFor(int work) => (work / 5).round().clamp(5, 30);

  List<int> _flowPresets(int suggested) =>
      ({15, 25, 30, 45, 60, 90, suggested}.where((m) => m <= _flowSoftCap).toList()
        ..sort());

  int _defaultMinutes(int suggested) => switch (_mode) {
        SessionMode.flowBlock => suggested,
        SessionMode.pomodoro => 25,
        SessionMode.custom => 30,
      };

  void _set(int minutes) {
    HapticFeedback.selectionClick();
    setState(() => _selectedMinutes = minutes.clamp(5, _maxMinutes));
  }

  void _begin(int minutes) {
    HapticFeedback.lightImpact();
    final config = SessionConfig(
      mode: _mode,
      plannedDuration: Duration(minutes: minutes),
      autoContinue: _endless,
      intention: _intention.text.trim(),
      soundscape: 'sand', // soundscape picker lands with the audio task
      skinId: 'classic',
    );
    // TODO(Task 8): replace with SessionScreen(config: config).
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Session')),
          body: Center(
            child: Text(
              '${config.mode.name} · ${config.plannedDuration.inMinutes} min'
              '${config.autoContinue ? ' · endless' : ''}\n'
              '“${config.intention}”',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    final suggested =
        ref.watch(suggestedFlowLengthProvider).asData?.value.inMinutes ?? 25;
    final minutes = _selectedMinutes ?? _defaultMinutes(suggested);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: ScreenBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: HgSpacing.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: HgSpacing.sm),
                // Chrome: back + mode title.
                Row(
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
                const SizedBox(height: HgSpacing.xl),

                // Intention — the framing line.
                _Label('Intention'),
                const SizedBox(height: HgSpacing.sm),
                TextField(
                  controller: _intention,
                  style: TextStyle(
                    fontFamily: HgFont.sans,
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                    color: hg.textPrimary,
                  ),
                  cursorColor: hg.accent,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: 'What are you focusing on?',
                    hintStyle: TextStyle(
                      fontFamily: HgFont.sans,
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      color: hg.textMuted,
                    ),
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: HgSpacing.sm),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: hg.hairline),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: hg.accent),
                    ),
                  ),
                ),

                // Focal: big duration readout (steppers for Pomodoro/Custom).
                const Spacer(),
                Center(child: _focal(minutes)),
                const Spacer(),

                // Length band — differs per mode.
                ..._lengthBand(hg, suggested, minutes),
                const SizedBox(height: HgSpacing.xl),

                if (_mode != SessionMode.pomodoro)
                  _EndlessToggle(
                    value: _endless,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _endless = v);
                    },
                  ),

                const SizedBox(height: HgSpacing.lg),
                PrimaryButton(
                  label: 'Flip to begin',
                  onPressed: () => _begin(minutes),
                ),
                const SizedBox(height: HgSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _focal(int minutes) {
    switch (_mode) {
      case SessionMode.flowBlock:
        return _DurationReadout(minutes: minutes, endless: _endless);
      case SessionMode.pomodoro:
        return _StepperRow(
          minusEnabled: minutes > 5,
          plusEnabled: minutes < _flowSoftCap,
          onMinus: () => _set(minutes - 5),
          onPlus: () => _set(minutes + 5),
          center: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BigMinutes(minutes: minutes),
              const SizedBox(height: HgSpacing.sm),
              Text(
                '$minutes min work · ${_breakFor(minutes)} min break',
                style: TextStyle(
                  fontFamily: HgFont.sans,
                  fontSize: 13,
                  color: context.hg.accent,
                ),
              ),
            ],
          ),
        );
      case SessionMode.custom:
        return _StepperRow(
          minusEnabled: minutes > 5,
          plusEnabled: minutes < _maxMinutes,
          onMinus: () => _set(minutes - 5),
          onPlus: () => _set(minutes + 5),
          center: _endless
              ? _DurationReadout(minutes: minutes, endless: true)
              : _BigMinutes(minutes: minutes),
        );
    }
  }

  List<Widget> _lengthBand(HgTokens hg, int suggested, int minutes) {
    switch (_mode) {
      case SessionMode.flowBlock:
        final over = minutes > _flowSoftCap;
        return [
          _Label('Length'),
          const SizedBox(height: HgSpacing.md),
          Wrap(
            spacing: HgSpacing.sm,
            runSpacing: HgSpacing.sm,
            children: [
              for (final m in _flowPresets(suggested))
                _Chip(label: '$m min', active: m == minutes, onTap: () => _set(m)),
              _Chip(
                label: '+5',
                active: false,
                outline: true,
                onTap: () => _set(minutes + 5),
              ),
            ],
          ),
          const SizedBox(height: HgSpacing.sm),
          Text(
            over
                ? 'Past ~90 min, focus tends to fade and recovery gets harder — '
                    'a fresh block after a break often serves you better.'
                : 'Grows with your focus stamina. One unbroken block — a '
                    'phone-free recovery follows.',
            style: TextStyle(
              fontFamily: HgFont.sans,
              fontSize: 12,
              height: 1.4,
              color: over ? hg.warning : hg.textMuted,
            ),
          ),
        ];
      case SessionMode.pomodoro:
        return [
          Center(
            child: Text(
              'Set your work time — the break is auto-set (~5:1).',
              style: TextStyle(
                fontFamily: HgFont.sans,
                fontSize: 12,
                color: hg.textMuted,
              ),
            ),
          ),
        ];
      case SessionMode.custom:
        return [
          Center(
            child: Text(
              'Set any length, up to 4 hours.',
              style: TextStyle(
                fontFamily: HgFont.sans,
                fontSize: 12,
                color: hg.textMuted,
              ),
            ),
          ),
        ];
    }
  }
}

/// The large focal duration number (counts when it changes).
class _DurationReadout extends StatelessWidget {
  final int minutes;
  final bool endless;
  const _DurationReadout({required this.minutes, required this.endless});

  @override
  Widget build(BuildContext context) {
    if (endless) {
      return Text(
        '∞',
        style: TextStyle(
          fontFamily: HgFont.sans,
          fontSize: 84,
          fontWeight: FontWeight.w300,
          height: 1.0,
          color: context.hg.textPrimary,
        ),
      );
    }
    return _BigMinutes(minutes: minutes);
  }
}

/// A big number flanked by − / + stepper buttons.
class _StepperRow extends StatelessWidget {
  final Widget center;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final bool minusEnabled;
  final bool plusEnabled;
  const _StepperRow({
    required this.center,
    required this.onMinus,
    required this.onPlus,
    required this.minusEnabled,
    required this.plusEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _StepButton(icon: Icons.remove_rounded, onTap: minusEnabled ? onMinus : null),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: HgSpacing.sm),
            child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: center)),
          ),
        ),
        _StepButton(icon: Icons.add_rounded, onTap: plusEnabled ? onPlus : null),
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
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: hg.hairline),
        ),
        child: Icon(
          icon,
          size: HgSize.iconMd,
          color: enabled ? hg.textPrimary : hg.textMuted,
        ),
      ),
    );
  }
}

/// The shared big "NN min" readout, with a gentle count tween.
class _BigMinutes extends StatelessWidget {
  final int minutes;
  const _BigMinutes({required this.minutes});

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(end: minutes.toDouble()),
          duration: HgMotion.fast,
          curve: HgMotion.calm,
          builder: (_, value, _) => Text(
            value.round().toString(),
            style: TextStyle(
              fontFamily: HgFont.sans,
              fontSize: 72,
              fontWeight: FontWeight.w300,
              height: 1.0,
              letterSpacing: -2,
              color: hg.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: HgSpacing.sm),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'min',
            style: TextStyle(
              fontFamily: HgFont.sans,
              fontSize: 18,
              color: hg.textMuted,
            ),
          ),
        ),
      ],
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

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final bool outline;
  final VoidCallback onTap;
  const _Chip({
    required this.label,
    required this.active,
    required this.onTap,
    this.outline = false,
  });

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: HgMotion.fast,
        curve: HgMotion.calm,
        padding: const EdgeInsets.symmetric(
          horizontal: HgSpacing.md,
          vertical: HgSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: active ? hg.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(HgRadius.pill),
          border: Border.all(color: active ? hg.accent : hg.hairline),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: HgFont.sans,
            fontSize: 14,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active
                ? hg.onAccent
                : (outline ? hg.textMuted : hg.textSecondary),
          ),
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
              Text(
                'Endless flow',
                style: TextStyle(
                  fontFamily: HgFont.sans,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: hg.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Keep going past the goal until you stop.',
                style: TextStyle(
                  fontFamily: HgFont.sans,
                  fontSize: 13,
                  color: hg.textMuted,
                ),
              ),
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
