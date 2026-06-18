import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../app/theme.dart';
import '../app/tokens.dart';
import '../domain/session_record.dart';
import 'session_format.dart';
import 'session_summary_screen.dart';
import 'widgets/screen_background.dart';
import 'widgets/screen_header.dart';

/// A reverse-chronological list of past sessions, grouped by day. Tapping a row
/// opens the per-session summary.
class SessionHistoryScreen extends ConsumerWidget {
  const SessionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final async = ref.watch(sessionHistoryProvider);
    final sessions = async.asData?.value ?? const <SessionRecord>[];

    Widget body;
    if (!async.hasValue) {
      body = const SizedBox.shrink();
    } else if (sessions.isEmpty) {
      body = _Empty();
    } else {
      body = ListView(children: _rows(context, sessions, now));
    }

    return Scaffold(
      body: ScreenBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: HgSpacing.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: HgSpacing.sm),
                const ScreenHeader(title: 'History'),
                const SizedBox(height: HgSpacing.lg),
                Expanded(child: body),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _rows(
      BuildContext context, List<SessionRecord> sessions, DateTime now) {
    final children = <Widget>[];
    String? lastHeading;
    for (final s in sessions) {
      final heading = dayHeading(s.startedAt, now);
      if (heading != lastHeading) {
        children.add(SizedBox(
            height: children.isEmpty ? 0 : HgSpacing.lg));
        children.add(_DayHeading(heading));
        children.add(const SizedBox(height: HgSpacing.xs));
        lastHeading = heading;
      }
      children.add(_HistoryRow(session: s));
    }
    children.add(const SizedBox(height: HgSpacing.xl));
    return children;
  }
}

class _DayHeading extends StatelessWidget {
  final String text;
  const _DayHeading(this.text);

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontFamily: HgFont.sans,
        fontSize: 11,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w600,
        color: hg.textMuted,
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final SessionRecord session;
  const _HistoryRow({required this.session});

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    final title = session.intention.trim().isNotEmpty
        ? session.intention.trim()
        : modeLabel(session.mode);
    final endedEarly = session.abandoned;

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => SessionSummaryScreen(session: session)),
      ),
      borderRadius: BorderRadius.circular(HgRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: HgSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: HgFont.sans,
                      fontSize: 15,
                      color: hg.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${modeLabel(session.mode)} · ${formatClock(session.startedAt)}'
                    '${endedEarly ? ' · ended early' : ''}',
                    style: TextStyle(
                      fontFamily: HgFont.sans,
                      fontSize: 12,
                      color: hg.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: HgSpacing.md),
            Text(
              formatFocusDuration(session.recordedFocus),
              style: TextStyle(
                fontFamily: HgFont.sans,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: hg.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: HgSpacing.xxl),
        child: Text(
          'Your focused time will appear here.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: HgFont.sans,
            fontSize: 15,
            color: hg.textMuted,
          ),
        ),
      ),
    );
  }
}
