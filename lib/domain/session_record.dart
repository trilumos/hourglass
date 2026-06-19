import 'session_mode.dart';

/// A focus session as the rest of the app sees it (ORM-independent).
class SessionRecord {
  final int id;
  final DateTime startedAt;
  final SessionMode mode;
  final String intention;
  final Duration plannedDuration;
  final Duration recordedFocus;
  final bool completed;
  final bool abandoned;
  final bool autoContinue;
  final String soundscape;
  final String skinId;

  /// Serialized config (segments + flags) to replay this session exactly via
  /// "Start again". Null for sessions recorded before this shipped.
  final String? planJson;

  const SessionRecord({
    required this.id,
    required this.startedAt,
    required this.mode,
    required this.intention,
    required this.plannedDuration,
    required this.recordedFocus,
    required this.completed,
    required this.abandoned,
    required this.autoContinue,
    required this.soundscape,
    required this.skinId,
    this.planJson,
  });
}
