import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../app/tokens.dart';

/// "Train your focus " followed by a phrase that types in, holds, deletes, and
/// cycles to the next — a calm typewriter. The rotating phrase is accent-colored.
class TypewriterTagline extends StatefulWidget {
  const TypewriterTagline({super.key});

  static const _prefix = 'Train your focus ';
  static const _phrases = <String>[
    'like an athlete',
    'one block at a time',
    'and recover like one',
    "until it's effortless",
    "like it's training",
    'one rep at a time',
  ];

  @override
  State<TypewriterTagline> createState() => _TypewriterTaglineState();
}

enum _Mode { typing, holding, deleting }

class _TypewriterTaglineState extends State<TypewriterTagline> {
  static const _typeMs = 55;
  static const _deleteMs = 30;
  static const _holdMs = 1900;

  Timer? _timer;
  Timer? _caret;
  int _phrase = 0;
  int _chars = 0;
  _Mode _mode = _Mode.typing;
  bool _caretOn = true;

  @override
  void initState() {
    super.initState();
    _schedule(_typeMs);
    _caret = Timer.periodic(const Duration(milliseconds: 530), (_) {
      if (mounted) setState(() => _caretOn = !_caretOn);
    });
  }

  void _schedule(int ms) {
    _timer = Timer(Duration(milliseconds: ms), _step);
  }

  String get _current => TypewriterTagline._phrases[_phrase];

  void _step() {
    if (!mounted) return;
    switch (_mode) {
      case _Mode.typing:
        if (_chars >= _current.length) {
          _mode = _Mode.holding;
          _schedule(_holdMs);
        } else {
          _chars++;
          _schedule(_typeMs);
        }
      case _Mode.holding:
        _mode = _Mode.deleting;
        _schedule(_deleteMs);
      case _Mode.deleting:
        if (_chars <= 0) {
          _phrase = (_phrase + 1) % TypewriterTagline._phrases.length;
          _mode = _Mode.typing;
          _schedule(_typeMs);
        } else {
          _chars--;
          _schedule(_deleteMs);
        }
    }
    setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    _caret?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    final typed = _current.substring(0, _chars);
    return Text.rich(
      textAlign: TextAlign.center,
      TextSpan(
        style: TextStyle(
          fontFamily: HgFont.sans,
          fontSize: 15,
          color: hg.textSecondary,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.2,
          height: 1.3,
        ),
        children: [
          const TextSpan(text: TypewriterTagline._prefix),
          TextSpan(
            text: typed,
            style: TextStyle(
              color: hg.accent,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
            ),
          ),
          TextSpan(
            text: '|',
            style: TextStyle(
              color: _caretOn ? hg.accent : Colors.transparent,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }
}
