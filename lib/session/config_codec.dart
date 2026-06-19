import 'dart:convert';

import '../domain/session_mode.dart';
import 'session_config.dart';
import 'session_plan.dart';

/// Serializes a [SessionConfig] to/from JSON so a session can be reproduced
/// exactly ("Start again", and later saved presets). The plan's resolved
/// segments ARE the exact session, so no builder parameters are stored.
/// Intention is NOT encoded (it's per-session; carried separately).
String encodeConfig(SessionConfig c) => jsonEncode({
      'v': 1,
      'mode': c.mode.name,
      'segments': [
        for (final s in c.plan.segments) {'k': s.kind.name, 's': s.duration.inSeconds}
      ],
      'autoContinue': c.autoContinue,
      'autoAdvanceBreaks': c.autoAdvanceBreaks,
      'soundscape': c.soundscape,
      'skinId': c.skinId,
    });

/// Rebuilds a [SessionConfig] from [json], or null if it's missing/corrupt.
/// [intention] is supplied by the caller (e.g. carried from the session record).
SessionConfig? decodeConfig(String? json, {String intention = ''}) {
  if (json == null || json.isEmpty) return null;
  try {
    final m = jsonDecode(json);
    if (m is! Map) return null;
    final mode = _enumByName(SessionMode.values, m['mode']);
    if (mode == null) return null;
    final rawSegs = m['segments'];
    if (rawSegs is! List || rawSegs.isEmpty) return null;
    final segs = <SessionSegment>[];
    for (final r in rawSegs) {
      if (r is! Map) return null;
      final kind = _enumByName(SegmentKind.values, r['k']);
      final secs = r['s'];
      if (kind == null || secs is! int || secs <= 0) return null;
      segs.add(SessionSegment(kind, Duration(seconds: secs)));
    }
    return SessionConfig(
      mode: mode,
      plan: SessionPlan(segs),
      autoContinue: m['autoContinue'] == true,
      intention: intention,
      soundscape: (m['soundscape'] as String?) ?? 'sand',
      skinId: (m['skinId'] as String?) ?? 'classic',
      autoAdvanceBreaks: m['autoAdvanceBreaks'] != false, // default true
    );
  } catch (_) {
    return null;
  }
}

T? _enumByName<T extends Enum>(List<T> values, Object? name) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return null;
}
