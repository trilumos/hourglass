import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../app/tokens.dart';
import '../../domain/session_mode.dart';

/// Segmented control with a single accent pill that smoothly slides to the
/// selected segment (no per-chip flashing). Segments are equal width.
class ModeSelector extends StatelessWidget {
  final SessionMode selected;
  final ValueChanged<SessionMode> onChanged;

  const ModeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  static const _labels = {
    SessionMode.flowBlock: 'Flow',
    SessionMode.pomodoro: 'Pomodoro',
    SessionMode.custom: 'Custom',
  };

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    final modes = SessionMode.values;
    final index = modes.indexOf(selected);
    // Map index → Alignment.x across N equal slots (-1 .. 1).
    final x = modes.length == 1 ? 0.0 : (index / (modes.length - 1)) * 2 - 1;

    return Container(
      padding: const EdgeInsets.all(HgSpacing.xs),
      decoration: BoxDecoration(
        color: hg.surface,
        borderRadius: BorderRadius.circular(HgRadius.pill),
      ),
      child: Stack(
        children: [
          // The sliding accent pill.
          Positioned.fill(
            child: AnimatedAlign(
              duration: HgMotion.medium,
              curve: HgMotion.calm,
              alignment: Alignment(x, 0),
              child: FractionallySizedBox(
                widthFactor: 1 / modes.length,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: hg.accent,
                    borderRadius: BorderRadius.circular(HgRadius.pill),
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final mode in modes)
                Expanded(
                  child: GestureDetector(
                    onTap: () => onChanged(mode),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      alignment: Alignment.center,
                      padding:
                          const EdgeInsets.symmetric(vertical: HgSpacing.sm + 2),
                      child: AnimatedDefaultTextStyle(
                        duration: HgMotion.fast,
                        curve: HgMotion.calm,
                        style: TextStyle(
                          fontFamily: HgFont.sans,
                          fontSize: 13,
                          letterSpacing: 0.3,
                          color: mode == selected ? hg.onAccent : hg.textMuted,
                          fontWeight: mode == selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                        child: Text(_labels[mode]!),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
