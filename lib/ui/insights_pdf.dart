import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../app/providers.dart';
import '../domain/personal_bests.dart';
import '../domain/session_mode.dart';
import 'session_format.dart';

// ── Brand palette (warm Sand gold; the PDF is its own clean light surface) ────
const _paper = PdfColor.fromInt(0xFFFBF8F1);
const _ink = PdfColor.fromInt(0xFF2B2722);
const _muted = PdfColor.fromInt(0xFF8C857A);
const _gold = PdfColor.fromInt(0xFFC2901C);
const _goldLight = PdfColor.fromInt(0xFFE7B84B);
const _line = PdfColor.fromInt(0xFFEDE5D6);
const _white = PdfColors.white;

/// Per-mode accent + soft tint, so the report reads colourful but coherent.
({PdfColor color, PdfColor tint}) _modeColor(SessionMode m) => switch (m) {
      SessionMode.flowBlock =>
        (color: _gold, tint: const PdfColor.fromInt(0xFFF7EDD7)),
      SessionMode.pomodoro =>
        (color: const PdfColor.fromInt(0xFF2E8B7F),
            tint: const PdfColor.fromInt(0xFFE1EFEC)),
      SessionMode.custom =>
        (color: const PdfColor.fromInt(0xFF8A5A9B),
            tint: const PdfColor.fromInt(0xFFEEE6F2)),
    };

String _scorePhrase(int s) => s >= 85
    ? 'Elite focus — you train like an athlete.'
    : s >= 65
        ? 'Strong and steady. Your focus is compounding.'
        : s >= 45
            ? 'Real momentum. Keep showing up.'
            : s >= 20
                ? 'You are building the habit. It adds up.'
                : 'The beginning of something. One session at a time.';

/// Gathers the user's lifetime focus data, builds a polished PDF report, and
/// opens the share sheet. Lives on Insights (the story); raw CSV is on History.
Future<void> exportInsightsPdf(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final sessions = await ref.read(allSessionsProvider.future);
    final focused =
        sessions.where((s) => s.recordedFocus > Duration.zero).toList();
    if (focused.isEmpty) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Nothing to report yet.')));
      return;
    }
    final stats = await ref.read(profileStatsProvider.future);
    final score = await ref.read(focusScoreProvider.future);
    final daily = await ref.read(dailyFocusProvider.future);
    final profile = await ref.read(profileProvider.future);
    final now = ref.read(clockProvider)();

    // By mode (lifetime), highest focus first.
    final byMode = <SessionMode, Duration>{};
    for (final s in focused) {
      byMode[s.mode] = (byMode[s.mode] ?? Duration.zero) + s.recordedFocus;
    }

    // Last 14 days of focus (oldest → newest) for the consistency strip.
    final normalized = <DateTime, Duration>{};
    daily.forEach((k, v) =>
        normalized[DateTime(k.year, k.month, k.day)] = v.focus);
    DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);
    final last14 = [
      for (var i = 13; i >= 0; i--)
        normalized[dayOnly(now).subtract(Duration(days: i))] ?? Duration.zero
    ];
    var activeDays30 = 0;
    for (var i = 0; i < 30; i++) {
      if ((normalized[dayOnly(now).subtract(Duration(days: i))] ??
              Duration.zero) >
          Duration.zero) {
        activeDays30++;
      }
    }

    final bytes = await buildInsightsReportBytes(
      name: profile.name.trim(),
      now: now,
      score: score,
      stats: stats,
      bests: const PersonalBestsCalculator().compute(sessions),
      byMode: byMode,
      last14: last14,
      activeDays30: activeDays30,
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/sustain-focus-report.pdf');
    await file.writeAsBytes(bytes);
    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path, mimeType: 'application/pdf')],
      subject: 'Sustain — Focus Report',
      text: 'My focus report from Sustain.',
    ));
  } catch (_) {
    messenger.showSnackBar(const SnackBar(
        content: Text("Couldn't build your report right now.")));
  }
}

/// Pure builder: turns the gathered data into PDF bytes. Kept context-free so it
/// can be unit-tested without a widget tree.
Future<Uint8List> buildInsightsReportBytes({
  required String name,
  required DateTime now,
  required int score,
  required ProfileStats stats,
  required PersonalBests bests,
  required Map<SessionMode, Duration> byMode,
  required List<Duration> last14,
  required int activeDays30,
}) async {
  final doc = pw.Document(
    title: 'Sustain Focus Report',
    author: 'Sustain',
  );
  doc.addPage(
    pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        // Full-bleed header + manually-padded body (left/right/top = 0); the
        // bottom margin is the footer's room — without it MultiPage's content
        // height goes wrong and it paginates forever.
        margin: const pw.EdgeInsets.only(bottom: 40),
        buildBackground: (_) =>
            pw.FullPage(ignoreMargins: true, child: pw.Container(color: _paper)),
      ),
      footer: (ctx) => pw.Padding(
        padding: const pw.EdgeInsets.fromLTRB(28, 6, 28, 16),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Sustain · Train your focus like an athlete',
                style: const pw.TextStyle(fontSize: 8, color: _muted)),
            pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                style: const pw.TextStyle(fontSize: 8, color: _muted)),
          ],
        ),
      ),
      build: (ctx) => [
        _headerBand(name, now),
        _pad(pw.SizedBox(height: 22)),
        _pad(_hero(score, stats)),
        _pad(pw.SizedBox(height: 24)),
        _pad(_sectionTitle('RECORDS', 'Your lifetime scorecard.')),
        _pad(pw.SizedBox(height: 12)),
        _pad(_recordsGrid(stats)),
        _pad(pw.SizedBox(height: 24)),
        _pad(_sectionTitle('WHERE YOUR TIME GOES', 'Focus by session type.')),
        _pad(pw.SizedBox(height: 14)),
        _pad(_byMode(byMode)),
        _pad(pw.SizedBox(height: 24)),
        _pad(_sectionTitle('CONSISTENCY', 'Showing up is the whole game.')),
        _pad(pw.SizedBox(height: 12)),
        _pad(_consistency(last14, activeDays30, now)),
        _pad(pw.SizedBox(height: 24)),
        _pad(_sectionTitle('PERSONAL BESTS', 'The bar you have already cleared.')),
        _pad(pw.SizedBox(height: 12)),
        _pad(_bestsBlock(bests)),
        _pad(pw.SizedBox(height: 8)),
      ],
    ),
  );
  return doc.save();
}

pw.Widget _pad(pw.Widget child) =>
    pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 28), child: child);

pw.Widget _headerBand(String name, DateTime now) => pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(28, 22, 28, 22),
      decoration: const pw.BoxDecoration(
        gradient: pw.LinearGradient(
          begin: pw.Alignment.centerLeft,
          end: pw.Alignment.centerRight,
          colors: [_gold, _goldLight],
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('SUSTAIN',
                style: pw.TextStyle(
                    fontSize: 18,
                    color: _white,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 4)),
            pw.SizedBox(height: 3),
            pw.Text('Focus Report',
                style: const pw.TextStyle(
                    fontSize: 11, color: PdfColor.fromInt(0xF5FFFFFF))),
          ]),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text(name.isEmpty ? 'Your focus' : name,
                style: pw.TextStyle(
                    fontSize: 13,
                    color: _white,
                    fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 3),
            pw.Text(formatDate(now),
                style: const pw.TextStyle(
                    fontSize: 9.5, color: PdfColor.fromInt(0xF0FFFFFF))),
          ]),
        ],
      ),
    );

pw.Widget _hero(int score, ProfileStats stats) => pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          width: 92,
          height: 92,
          decoration: const pw.BoxDecoration(
            shape: pw.BoxShape.circle,
            gradient: pw.LinearGradient(
              begin: pw.Alignment.topLeft,
              end: pw.Alignment.bottomRight,
              colors: [_goldLight, _gold],
            ),
          ),
          child: pw.Center(
            child: pw.Column(mainAxisAlignment: pw.MainAxisAlignment.center, children: [
              pw.Text('$score',
                  style: pw.TextStyle(
                      fontSize: 34,
                      color: _white,
                      fontWeight: pw.FontWeight.bold)),
              pw.Text('/ 100',
                  style: const pw.TextStyle(
                      fontSize: 9, color: PdfColor.fromInt(0xCCFFFFFF))),
            ]),
          ),
        ),
        pw.SizedBox(width: 22),
        pw.Expanded(
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('FOCUS SCORE',
                style: const pw.TextStyle(
                    fontSize: 9, color: _muted, letterSpacing: 1.5)),
            pw.SizedBox(height: 4),
            pw.Text(_scorePhrase(score),
                style: pw.TextStyle(
                    fontSize: 14,
                    color: _ink,
                    fontWeight: pw.FontWeight.bold,
                    lineSpacing: 2)),
            pw.SizedBox(height: 12),
            pw.Row(children: [
              _heroStat('Total focus', formatFocusDuration(stats.totalFocus)),
              pw.SizedBox(width: 28),
              _heroStat('This week', formatFocusDuration(stats.weekFocus)),
              pw.SizedBox(width: 28),
              _heroStat('Day streak', '${stats.streak}'),
            ]),
          ]),
        ),
      ],
    );

pw.Widget _heroStat(String label, String value) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 15, color: _gold, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 1),
        pw.Text(label, style: const pw.TextStyle(fontSize: 8.5, color: _muted)),
      ],
    );

pw.Widget _sectionTitle(String title, String sub) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
          pw.Container(width: 16, height: 2.5, color: _gold),
          pw.SizedBox(width: 8),
          pw.Text(title,
              style: pw.TextStyle(
                  fontSize: 11,
                  color: _ink,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1.5)),
        ]),
        pw.SizedBox(height: 3),
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 24),
          child: pw.Text(sub,
              style: const pw.TextStyle(fontSize: 9.5, color: _muted)),
        ),
      ],
    );

pw.Widget _recordsGrid(ProfileStats stats) {
  final cards = [
    _statCard('Total focus', formatFocusDuration(stats.totalFocus)),
    _statCard('Sessions', '${stats.totalSessions}'),
    _statCard('Completed', '${stats.sessionsCompleted}'),
    _statCard('Current streak', '${stats.streak} d'),
    _statCard('Best streak', '${stats.bestStreak} d'),
    _statCard('Avg session', formatFocusDuration(stats.avgSession)),
  ];
  return pw.Column(children: [
    _cardRow(cards.sublist(0, 3)),
    pw.SizedBox(height: 10),
    _cardRow(cards.sublist(3, 6)),
    pw.SizedBox(height: 10),
    _cardRow([
      _statCard('Longest session', formatFocusDuration(stats.longestSession)),
      _statCard('Focusing since',
          stats.firstDate == null ? '—' : formatDate(stats.firstDate!)),
      pw.SizedBox(),
    ]),
  ]);
}

pw.Widget _cardRow(List<pw.Widget> cards) => pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) pw.SizedBox(width: 10),
          pw.Expanded(child: cards[i]),
        ],
      ],
    );

pw.Widget _statCard(String label, String value) => pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: pw.BoxDecoration(
        color: _white,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: _line, width: 0.8),
      ),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(label.toUpperCase(),
            style: const pw.TextStyle(
                fontSize: 7.5, color: _muted, letterSpacing: 0.8)),
        pw.SizedBox(height: 6),
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 17, color: _ink, fontWeight: pw.FontWeight.bold)),
      ]),
    );

pw.Widget _byMode(Map<SessionMode, Duration> byMode) {
  final entries = byMode.entries
      .where((e) => e.value > Duration.zero)
      .toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  if (entries.isEmpty) {
    return pw.Text('No focus recorded yet.',
        style: const pw.TextStyle(fontSize: 10, color: _muted));
  }
  final total =
      entries.fold(Duration.zero, (s, e) => s + e.value).inSeconds.toDouble();
  return pw.Column(children: [
    for (final e in entries)
      _bar(
        modeLabel(e.key),
        '${formatFocusDuration(e.value)}  ·  ${total == 0 ? 0 : (e.value.inSeconds / total * 100).round()}%',
        total == 0 ? 0 : e.value.inSeconds / total,
        _modeColor(e.key).color,
      ),
  ]);
}

pw.Widget _bar(String label, String value, double frac, PdfColor color) {
  final filled = (frac * 1000).round().clamp(2, 1000);
  final rest = (1000 - filled).clamp(0, 998);
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 12),
    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text(label,
            style: pw.TextStyle(
                fontSize: 11, color: _ink, fontWeight: pw.FontWeight.bold)),
        pw.Text(value, style: const pw.TextStyle(fontSize: 10, color: _muted)),
      ]),
      pw.SizedBox(height: 6),
      pw.ClipRRect(
        horizontalRadius: 5,
        verticalRadius: 5,
        child: pw.Row(children: [
          pw.Expanded(
              flex: filled, child: pw.Container(height: 10, color: color)),
          if (rest > 0)
            pw.Expanded(
                flex: rest, child: pw.Container(height: 10, color: _line)),
        ]),
      ),
    ]),
  );
}

pw.Widget _consistency(List<Duration> last14, int activeDays30, DateTime now) {
  final maxSecs = last14.fold(
      1, (m, d) => d.inSeconds > m ? d.inSeconds : m); // avoid /0
  return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
    pw.Row(children: [
      _heroStat('Active days (30d)', '$activeDays30'),
      pw.SizedBox(width: 32),
      _heroStat('Last 14 days', 'Daily focus'),
    ]),
    pw.SizedBox(height: 14),
    pw.Container(
      height: 60,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < last14.length; i++) ...[
            if (i > 0) pw.SizedBox(width: 5),
            pw.Expanded(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Container(
                    height:
                        (last14[i].inSeconds / maxSecs * 52).clamp(2, 52).toDouble(),
                    decoration: pw.BoxDecoration(
                      color: last14[i] > Duration.zero ? _gold : _line,
                      borderRadius: pw.BorderRadius.circular(2.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
    pw.SizedBox(height: 4),
    pw.Text('Two weeks ending ${formatDate(now)}',
        style: const pw.TextStyle(fontSize: 8.5, color: _muted)),
  ]);
}

pw.Widget _bestsBlock(PersonalBests b) {
  final rows = <pw.Widget>[
    if (b.bestDayFocus != null)
      _bestRow('Best focus day', formatFocusDuration(b.bestDayFocus!),
          b.bestDayDate == null ? null : formatDate(b.bestDayDate!)),
    if (b.longestSession != null)
      _bestRow('Longest session', formatFocusDuration(b.longestSession!),
          b.longestSessionDate == null ? null : formatDate(b.longestSessionDate!)),
    if (b.highestFocusScore != null)
      _bestRow('Highest Focus Score', '${b.highestFocusScore} / 100', null),
    _bestRow('Best streak', '${b.bestStreak} days', null),
  ];
  return pw.Container(
    decoration: pw.BoxDecoration(
      color: _white,
      borderRadius: pw.BorderRadius.circular(12),
      border: pw.Border.all(color: _line, width: 0.8),
    ),
    child: pw.Column(children: [
      for (var i = 0; i < rows.length; i++) ...[
        if (i > 0) pw.Container(height: 0.8, color: _line),
        rows[i],
      ],
    ]),
  );
}

pw.Widget _bestRow(String label, String value, String? when) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(label,
              style: const pw.TextStyle(fontSize: 11, color: _ink)),
          pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.center,
              mainAxisAlignment: pw.MainAxisAlignment.end, children: [
            if (when != null) ...[
              pw.Text(when, style: const pw.TextStyle(fontSize: 9, color: _muted)),
              pw.SizedBox(width: 10),
            ],
            pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 12, color: _gold, fontWeight: pw.FontWeight.bold)),
          ]),
        ],
      ),
    );
