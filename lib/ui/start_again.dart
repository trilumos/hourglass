import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/billing_providers.dart';
import '../domain/session_record.dart';
import '../session/config_codec.dart';
import 'paywall_screen.dart';
import 'session_screen.dart';

/// Whether a session can be reused exactly (has a captured config).
bool canReuse(SessionRecord r) => decodeConfig(r.planJson) != null;

/// Replay the exact session (Pro). Free users are sent to the paywall instead,
/// so the action stays discoverable. No-op if the config can't be decoded.
void startAgain(BuildContext context, WidgetRef ref, SessionRecord r) {
  if (!ref.read(entitlementsProvider).pro) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const PaywallScreen()));
    return;
  }
  final config = decodeConfig(r.planJson, intention: r.intention);
  if (config == null) return;
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => SessionScreen(config: config)),
  );
}
