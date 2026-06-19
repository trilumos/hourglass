import 'package:flutter/material.dart';

import '../domain/session_record.dart';
import '../session/config_codec.dart';
import 'session_screen.dart';

/// Whether a session can be reused exactly (has a captured config).
bool canReuse(SessionRecord r) => decodeConfig(r.planJson) != null;

/// Rebuild the exact config from a past session and start it again. Carries the
/// original intention as the default. No-op if the config can't be decoded.
/// (Pro feature — the entry points are wrapped in the Pro gate when the
/// entitlement engine lands.)
void startAgain(BuildContext context, SessionRecord r) {
  final config = decodeConfig(r.planJson, intention: r.intention);
  if (config == null) return;
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => SessionScreen(config: config)),
  );
}
