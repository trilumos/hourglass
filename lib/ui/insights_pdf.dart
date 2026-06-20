import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../app/billing_providers.dart';
import '../app/providers.dart';
import '../domain/analytics_calculator.dart';
import '../domain/focus_report.dart';
import '../domain/session_mode.dart';
import 'insights_copy.dart';
import 'session_format.dart';

// ── Brand palette (warm Sand gold on its own clean light surface) ─────────────
const _paper = PdfColor.fromInt(0xFFFBF8F1);
const _ink = PdfColor.fromInt(0xFF2B2722);
const _muted = PdfColor.fromInt(0xFF8C857A);
const _gold = PdfColor.fromInt(0xFFC2901C);
const _goldLight = PdfColor.fromInt(0xFFE7B84B);
const _goldSoft = PdfColor.fromInt(0xFFEAD7A6);
const _line = PdfColor.fromInt(0xFFEDE5D6);
const _white = PdfColors.white;

const _months = [
  'January', 'February', 'March', 'April', 'May', 'June', //
  'July', 'August', 'September', 'October', 'November', 'December'
];

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
    ? 'Elite focus - you train like an athlete.'
    : s >= 65
        ? 'Strong and steady. Your focus is compounding.'
        : s >= 45
            ? 'Real momentum. Keep showing up.'
            : s >= 20
                ? 'You are building the habit. It adds up.'
                : 'The beginning of something. One session at a time.';

// ── Public API ────────────────────────────────────────────────────────────────

/// Gathers the user\'s lifetime focus data, builds a detailed PDF report that
/// grows with their history, and opens the share sheet. Lives on Insights (the
/// story); raw CSV is on History.
Future<void> exportInsightsPdf(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final sessions = await ref.read(allSessionsProvider.future);
    if (sessions.every((s) => s.recordedFocus <= Duration.zero)) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Nothing to report yet.')));
      return;
    }
    final profile = await ref.read(profileProvider.future);
    final isPro = ref.read(entitlementsProvider).pro;
    final now = ref.read(clockProvider)();

    final data = FocusReportData.from(
      sessions: sessions,
      now: now,
      name: profile.name.trim(),
      isPro: isPro,
    );
    final bytes = await buildFocusReportBytes(data);

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/sustain-focus-report.pdf');
    await file.writeAsBytes(bytes);
    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path, mimeType: 'application/pdf')],
      subject: 'Sustain - Focus Report',
      text: 'My focus report from Sustain.',
    ));
  } catch (_) {
    messenger.showSnackBar(const SnackBar(
        content: Text("Couldn't build your report right now.")));
  }
}

/// Pure builder: turns the [FocusReportData] snapshot into PDF bytes. Context-
/// free so it can be unit-tested without a widget tree.
Future<Uint8List> buildFocusReportBytes(FocusReportData d) async {
  final doc = pw.Document(title: 'Sustain Focus Report', author: 'Sustain');
  doc.addPage(
    pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        // Full-bleed header + manually-padded body; the bottom margin is the
        // footer\'s room (a zero bottom margin breaks MultiPage pagination).
        margin: const pw.EdgeInsets.only(bottom: 40),
        buildBackground: (_) =>
            pw.FullPage(ignoreMargins: true, child: pw.Container(color: _paper)),
      ),
      footer: (ctx) => pw.Padding(
        padding: const pw.EdgeInsets.fromLTRB(28, 6, 28, 16),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Sustain - Train your focus like an athlete',
                style: const pw.TextStyle(fontSize: 8, color: _muted)),
            pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                style: const pw.TextStyle(fontSize: 8, color: _muted)),
          ],
        ),
      ),
      build: (ctx) => _content(d),
    ),
  );
  return doc.save();
}

// ── Page assembly ─────────────────────────────────────────────────────────────

List<pw.Widget> _content(FocusReportData d) {
  final w = <pw.Widget>[];
  void gap([double h = 22]) => w.add(pw.SizedBox(height: h));
  void add(pw.Widget child) => w.add(_pad(child));

  // 1 - Cover + executive summary.
  w.add(_headerBand(d.name, d.now));
  gap();
  add(_execSummary(d));

  // 2 - Focus Score.
  if (d.focusScore != null) {
    gap(24);
    add(_focusScoreSection(d));
  }

  // 3 - At a glance / records.
  gap(24);
  add(_section('RECORDS', 'Your lifetime scorecard.'));
  gap(12);
  add(_recordsGrid(d));
  gap(8);
  add(_prose(_recordsInsight(d)));

  // 4 - Focus over time (monthly arc; needs ≥2 months).
  if (d.focusOverTime.length >= 2) {
    gap(24);
    add(_section('FOCUS OVER TIME', 'The shape of your practice.'));
    gap(12);
    add(_focusOverTime(d));
  }

  // 5 - Where your time goes (by mode).
  if (d.modeStats.isNotEmpty) {
    gap(24);
    add(_section('WHERE YOUR TIME GOES', 'Focus by session type.'));
    gap(12);
    add(_byModeSection(d));
  }

  // 6 - When you focus best.
  final whenLine = _whenInsight(d);
  if (d.totalSessions >= 3 && whenLine != null) {
    gap(24);
    add(_section('WHEN YOU FOCUS', 'Your natural rhythm.'));
    gap(12);
    add(_rhythm(d));
    gap(8);
    add(_prose(whenLine));
  }

  // 7 - Consistency + streaks.
  gap(24);
  add(_section('CONSISTENCY', 'Showing up is the whole game.'));
  gap(12);
  add(_consistencySection(d));

  // 8 - Follow-through.
  if (d.followThrough.sample >= 5) {
    gap(24);
    add(_section('FOLLOW-THROUGH', 'Doing what you decided to do.',
        flowOnly: true));
    gap(12);
    add(_followThroughSection(d));
  }

  // 9 - Focus Stamina (Pro).
  if (d.isPro && d.currentStaminaMinutes != null) {
    gap(24);
    add(_section('FOCUS STAMINA', 'How long you can hold.', flowOnly: true));
    gap(12);
    add(_staminaSection(d));
  }

  // 10 - Personal bests.
  gap(24);
  add(_section('PERSONAL BESTS', 'The bar you have already cleared.'));
  gap(12);
  add(_bestsBlock(d));
  gap(8);
  add(_prose(_bestsClose(d)));

  // 11 - Milestones.
  final spanDays = d.firstSessionDate == null
      ? 0
      : d.now.difference(d.firstSessionDate!).inDays;
  if (d.activeDaysTotal >= 30 || spanDays >= 60 || d.milestones.length >= 3) {
    gap(24);
    add(_section('MILESTONES', 'Moments along the way.'));
    gap(12);
    add(_milestones(d));
  }

  // 12 - Intention themes.
  if (d.intentionThemes != null) {
    gap(24);
    add(_section('WHAT YOU FOCUS ON', 'The work behind the numbers.'));
    gap(12);
    add(_intentions(d.intentionThemes!));
  }

  // 13 - Closing note.
  gap(26);
  add(_closingNote(d));

  // 14 - Glossary / methodology.
  gap(22);
  add(_glossary(d));

  return w;
}

pw.Widget _pad(pw.Widget child) =>
    pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 28), child: child);

// ── Section header ────────────────────────────────────────────────────────────

pw.Widget _section(String title, String sub, {bool flowOnly = false}) =>
    pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
        pw.Container(width: 16, height: 2.5, color: _gold),
        pw.SizedBox(width: 8),
        pw.Text(title,
            style: pw.TextStyle(
                fontSize: 11,
                color: _ink,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 1.5)),
        if (flowOnly) ...[
          pw.SizedBox(width: 8),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: pw.BoxDecoration(
                color: _modeColor(SessionMode.flowBlock).tint,
                borderRadius: pw.BorderRadius.circular(3)),
            child: pw.Text('FLOW ONLY',
                style: pw.TextStyle(
                    fontSize: 6, color: _gold, letterSpacing: 0.8)),
          ),
        ],
      ]),
      pw.SizedBox(height: 3),
      pw.Padding(
        padding: const pw.EdgeInsets.only(left: 24),
        child:
            pw.Text(sub, style: const pw.TextStyle(fontSize: 9.5, color: _muted)),
      ),
    ]);

pw.Widget _prose(String text) => pw.Text(_ascii(text),
    style: const pw.TextStyle(fontSize: 11, color: _ink, lineSpacing: 3));

/// The built-in PDF Helvetica uses WinAnsi encoding, which lacks the general-
/// punctuation glyphs (em/en dash, curly quotes, true minus) that the app\'s copy
/// generators use — they\'d render blank. Fold them to ASCII at the render edge
/// (this report deliberately ships fontless for total reliability).
String _ascii(String s) => s
    .replaceAll('’', "'")
    .replaceAll('‘', "'")
    .replaceAll('“', '"')
    .replaceAll('”', '"')
    .replaceAll('—', '-')
    .replaceAll('–', '-')
    .replaceAll('−', '-')
    .replaceAll('…', '...');

// ── 1. Header band + executive summary ────────────────────────────────────────

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
            pw.Text(_ascii(name.isEmpty ? 'Your focus' : name),
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

pw.Widget _execSummary(FocusReportData d) {
  final chips = <pw.Widget>[_heroStat('Total focus', formatFocusDuration(d.totalFocus))];
  if (d.weekFocus > Duration.zero) {
    chips.add(_heroStat('This week', formatFocusDuration(d.weekFocus)));
  }
  if (d.currentStreak > 0) {
    chips.add(_heroStat('Day streak', '${d.currentStreak}'));
  }
  return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
    pw.Text(_ascii(_execLines(d).join(' ')),
        style: const pw.TextStyle(fontSize: 12.5, color: _ink, lineSpacing: 3.5)),
    pw.SizedBox(height: 16),
    pw.Row(children: [
      for (var i = 0; i < chips.length; i++) ...[
        if (i > 0) pw.SizedBox(width: 30),
        chips[i],
      ],
    ]),
  ]);
}

List<String> _execLines(FocusReportData d) {
  final out = <String>[];
  // Opener (mandatory).
  if (d.totalSessions == 1) {
    out.add('This is where it begins - one session down, and a real number '
        'already on the board: ${formatFocusDuration(d.totalFocus)} of focus.');
  } else {
    out.add('${_sinceRelative(d.firstSessionDate, d.now)}, you\'ve turned focus '
        'into something you can see - ${formatFocusDuration(d.totalFocus)} of '
        'it, across ${d.totalSessions} sessions.');
  }
  // Focus Score.
  if (d.focusScore != null && out.length < 4) {
    out.add('Your Focus Score sits at ${d.focusScore}. ${_scorePhrase(d.focusScore!)}');
  }
  // Consistency.
  if (out.length < 4) {
    if (d.currentStreak >= 2 && d.activeDaysLast30 >= 1) {
      out.add('You\'re showing up - ${d.currentStreak} days running, and '
          '${d.activeDaysLast30} of the last 30 with focus on the board.');
    } else if (d.activeDaysLast30 >= 3) {
      out.add('You\'ve shown up ${d.activeDaysLast30} of the last 30 days. '
          'Consistency is the quiet engine, and yours is running.');
    }
  }
  // One flavour line.
  if (out.length < 4) {
    final flavour = _flavourLine(d);
    if (flavour != null) out.add(flavour);
  }
  return out;
}

String? _flavourLine(FocusReportData d) {
  final peak = InsightsCopy.timeOfDayInsight(d.timeOfDay);
  if (d.peakWindowCaption != null && peak != null) {
    return '$peak That\'s when your focus comes easiest.';
  }
  if (d.followThrough.sample >= 5) {
    return 'When you commit to a Flow block, you finish it '
        '${(d.followThrough.rate * 100).round()}% of the time - you do what '
        'you set out to do.';
  }
  if (d.longestSession > Duration.zero) {
    return 'Your longest unbroken block reached '
        '${formatFocusDuration(d.longestSession)}${_staminaMark(d.longestSession.inMinutes)} '
        '- proof of how far your focus can stretch.';
  }
  if (d.bestDayFocus != null) {
    return 'Your best day so far brought ${formatFocusDuration(d.bestDayFocus!)} '
        'of focus - a high bar you\'ve already cleared.';
  }
  return null;
}

String _sinceRelative(DateTime? first, DateTime now) {
  if (first == null) return 'So far';
  if (first.year == now.year && first.month == now.month) {
    return 'In your first days here';
  }
  final weeks = now.difference(first).inDays ~/ 7;
  if (weeks < 2) return 'In your first weeks here';
  if (weeks < 8) return 'Over the past $weeks weeks';
  return 'Since ${_months[first.month - 1]}';
}

String _staminaMark(int minutes) => minutes >= 90
    ? ' (past the 90-minute deep-work mark)'
    : minutes >= 75
        ? ' (nearing the 90-minute mark)'
        : '';

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

// ── 2. Focus Score ────────────────────────────────────────────────────────────

pw.Widget _focusScoreSection(FocusReportData d) {
  final score = d.focusScore!;
  final nonNull = d.scoreTrend.where((p) => p.value != null).length;
  final trendLine = InsightsCopy.scoreTrendInsight(d.scoreTrend);
  return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
    _section('FOCUS SCORE', 'The depth of your focus, distilled.',
        flowOnly: true),
    pw.SizedBox(height: 12),
    pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
      _scoreRing(score),
      pw.SizedBox(width: 20),
      pw.Expanded(
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(_scorePhrase(score),
              style: pw.TextStyle(
                  fontSize: 13,
                  color: _ink,
                  fontWeight: pw.FontWeight.bold,
                  lineSpacing: 2)),
          pw.SizedBox(height: 6),
          pw.Text(
              'A rolling read of your last 10 Flow sessions, scored on how '
              'fully you reach each block you choose. It moves gently, '
              'rewarding showing up over chasing one perfect block.',
              style: const pw.TextStyle(fontSize: 10, color: _muted, lineSpacing: 2.5)),
        ]),
      ),
    ]),
    if (nonNull >= 2) ...[
      pw.SizedBox(height: 14),
      _vBarChart(_fromTrend(d.scoreTrend, 100), height: 40),
      if (trendLine != null) ...[
        pw.SizedBox(height: 8),
        _prose(trendLine),
      ],
    ],
  ]);
}

pw.Widget _scoreRing(int score) => pw.Container(
      width: 84,
      height: 84,
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
                  fontSize: 31, color: _white, fontWeight: pw.FontWeight.bold)),
          pw.Text('/ 100',
              style: const pw.TextStyle(
                  fontSize: 8, color: PdfColor.fromInt(0xCCFFFFFF))),
        ]),
      ),
    );

// ── 3. Records ────────────────────────────────────────────────────────────────

pw.Widget _recordsGrid(FocusReportData d) {
  final cards = <pw.Widget>[
    _statCard('Total focus', formatFocusDuration(d.totalFocus), 'all modes'),
    _statCard('Sessions', '${d.totalSessions}', 'focused sessions'),
    _statCard('Completed', '${d.sessionsCompleted}', 'carried to the finish'),
    _statCard('Active days', '${d.activeDaysTotal}', 'with real focus'),
    if (d.completionRate != null)
      _statCard('Completion', '${(d.completionRate! * 100).round()}%',
          'of all sessions'),
    if (d.currentStreak >= 1)
      _statCard('Current streak', '${d.currentStreak} d', 'days in a row'),
    if (d.bestStreak >= 1)
      _statCard('Best streak', '${d.bestStreak} d', 'longest run'),
    if (d.isPro)
      _statCard('Avg session', formatFocusDuration(d.avgSession), 'per sit-down'),
    if (d.longestSession > Duration.zero)
      _statCard('Longest', formatFocusDuration(d.longestSession),
          d.longestSessionDate == null ? 'single block' : formatDate(d.longestSessionDate!)),
    if (d.firstSessionDate != null)
      _statCard('Focusing since', formatDate(d.firstSessionDate!), 'first session'),
  ];
  // Lay out in rows of 3, padding the last row to keep widths even.
  final rows = <pw.Widget>[];
  for (var i = 0; i < cards.length; i += 3) {
    final row = cards.sublist(i, (i + 3).clamp(0, cards.length));
    while (row.length < 3) {
      row.add(pw.SizedBox());
    }
    if (rows.isNotEmpty) rows.add(pw.SizedBox(height: 10));
    rows.add(_cardRow(row));
  }
  return pw.Column(children: rows);
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

pw.Widget _statCard(String label, String value, String sub) => pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 13, vertical: 11),
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
                fontSize: 16, color: _ink, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 2),
        pw.Text(sub, style: const pw.TextStyle(fontSize: 7, color: _muted)),
      ]),
    );

String _recordsInsight(FocusReportData d) {
  final avgClause = d.isPro
      ? ' - an average of ${formatFocusDuration(d.avgSession)} each time you sit down'
      : '';
  final first = 'Altogether that\'s ${formatFocusDuration(d.totalFocus)} of focus '
      'over ${d.totalSessions} sessions, ${d.sessionsCompleted} of them carried '
      'to the finish$avgClause.';
  if (d.firstSessionDate == null) return first;
  final dayWord = d.activeDaysTotal == 1
      ? '1 day with real focus on it'
      : '${d.activeDaysTotal} days with real focus on them';
  return '$first You\'ve been focusing since '
      '${formatDate(d.firstSessionDate!)} - $dayWord so far.';
}

// ── 4. Focus over time ────────────────────────────────────────────────────────

pw.Widget _focusOverTime(FocusReportData d) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _vBarChart(
          [
            for (final b in d.focusOverTime)
              (
                label: b.label,
                frac: b.focus.inSeconds /
                    d.focusOverTime
                        .fold(1, (m, x) => x.focus.inSeconds > m ? x.focus.inSeconds : m),
                hi: b.highlight,
              )
          ],
          height: 64,
        ),
        pw.SizedBox(height: 8),
        _prose('Each bar is a month of focus; the current month is highlighted. '
            'The arc is the long view of your practice - the months you went '
            'deep, and the rhythm you are building.'),
      ],
    );

// ── 5. By mode ────────────────────────────────────────────────────────────────

pw.Widget _byModeSection(FocusReportData d) {
  final used = d.modeStats.where((m) => m.totalFocus > Duration.zero).toList()
    ..sort((a, b) => b.totalFocus.compareTo(a.totalFocus));
  final total = used.fold(0, (s, m) => s + m.totalFocus.inSeconds);
  return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
    for (final m in used)
      _bar(
        modeLabel(m.mode),
        '${formatFocusDuration(m.totalFocus)}  -  ${total == 0 ? 0 : (m.totalFocus.inSeconds / total * 100).round()}%',
        '${m.count} session${m.count == 1 ? '' : 's'} - avg ${formatFocusDuration(m.avg)}',
        total == 0 ? 0 : m.totalFocus.inSeconds / total,
        _modeColor(m.mode).color,
      ),
    pw.SizedBox(height: 4),
    _prose(_byModeInsight(d, used)),
  ]);
}

String _byModeInsight(FocusReportData d, List<ModeStat> used) {
  String meaning(SessionMode m) => switch (m) {
        SessionMode.flowBlock =>
          'the deep, single-block work that builds your Focus Score and Stamina',
        SessionMode.pomodoro => 'steady, paced work in fixed intervals',
        SessionMode.custom => 'focus shaped to your own rhythm',
      };
  if (used.length == 1) {
    return 'All your focus has been ${modeLabel(used.first.mode)} so far - '
        '${meaning(used.first.mode)}.';
  }
  final top = used.first;
  return '${modeLabel(top.mode)} is where you spend most of your focus - '
      '${meaning(top.mode)}.';
}

pw.Widget _bar(
    String label, String value, String? sub, double frac, PdfColor color) {
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
      pw.SizedBox(height: 5),
      pw.ClipRRect(
        horizontalRadius: 5,
        verticalRadius: 5,
        child: pw.Row(children: [
          pw.Expanded(flex: filled, child: pw.Container(height: 10, color: color)),
          if (rest > 0)
            pw.Expanded(flex: rest, child: pw.Container(height: 10, color: _line)),
        ]),
      ),
      if (sub != null) ...[
        pw.SizedBox(height: 3),
        pw.Text(sub, style: const pw.TextStyle(fontSize: 8, color: _muted)),
      ],
    ]),
  );
}

// ── 6. When you focus ─────────────────────────────────────────────────────────

pw.Widget _rhythm(FocusReportData d) => pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            _miniLabel('TIME OF DAY'),
            pw.SizedBox(height: 8),
            _vBarChart(_fromTimeBars(d.timeOfDay), height: 42),
          ]),
        ),
        pw.SizedBox(width: 22),
        pw.Expanded(
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            _miniLabel('WEEKDAY'),
            pw.SizedBox(height: 8),
            _vBarChart(_fromTimeBars(d.dayOfWeek), height: 42),
          ]),
        ),
      ],
    );

String? _whenInsight(FocusReportData d) {
  final peak = InsightsCopy.timeOfDayInsight(d.timeOfDay);
  final day = InsightsCopy.dayOfWeekInsight(d.dayOfWeek);
  final parts = [?peak, ?day];
  if (parts.isEmpty) return null;
  return '${parts.join(' ')} Knowing your own rhythm is half of protecting it.';
}

pw.Widget _miniLabel(String s) => pw.Text(s,
    style: const pw.TextStyle(fontSize: 8, color: _muted, letterSpacing: 1));

// ── 7. Consistency ────────────────────────────────────────────────────────────

pw.Widget _consistencySection(FocusReportData d) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(children: [
          _heroStat('Active days (30d)', '${d.activeDaysLast30}'),
          if (d.currentStreak > 0) ...[
            pw.SizedBox(width: 30),
            _heroStat('Current streak', '${d.currentStreak} d'),
          ],
          if (d.bestStreak >= 1) ...[
            pw.SizedBox(width: 30),
            _heroStat('Best streak', '${d.bestStreak} d'),
          ],
        ]),
        pw.SizedBox(height: 14),
        _vBarChart(
          [
            for (final v in d.last14Strip)
              (
                label: '',
                frac: v.inSeconds /
                    d.last14Strip
                        .fold(1, (m, x) => x.inSeconds > m ? x.inSeconds : m),
                hi: false,
              )
          ],
          height: 48,
          labels: false,
        ),
        pw.SizedBox(height: 4),
        pw.Text('Daily focus - two weeks ending ${formatDate(d.now)}',
            style: const pw.TextStyle(fontSize: 8.5, color: _muted)),
        pw.SizedBox(height: 10),
        _prose(_consistencyInsight(d)),
      ],
    );

String _consistencyInsight(FocusReportData d) {
  if (d.activeDaysLast30 == 0) {
    return 'Your consistency picture fills in as the days add up - every '
        'focused day lengthens the strip and the run.';
  }
  final bestClause = d.bestStreak > d.currentStreak
      ? ', your best yet being ${d.bestStreak} days'
      : '';
  return 'You\'ve put focus on the board ${d.activeDaysLast30} of the last 30 '
      'days, and your current run is ${d.currentStreak} days$bestClause. '
      'Showing up is the part that compounds - the depth follows the days.';
}

// ── 8. Follow-through ─────────────────────────────────────────────────────────

pw.Widget _followThroughSection(FocusReportData d) {
  final pct = (d.followThrough.rate * 100).round();
  return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
    pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
      pw.Text('$pct%',
          style: pw.TextStyle(
              fontSize: 30, color: _gold, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(width: 10),
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 5),
        child: pw.Text('of Flow sessions reached their mark',
            style: const pw.TextStyle(fontSize: 10, color: _muted)),
      ),
    ]),
    pw.SizedBox(height: 8),
    pw.ClipRRect(
      horizontalRadius: 5,
      verticalRadius: 5,
      child: pw.Row(children: [
        pw.Expanded(
            flex: pct.clamp(1, 100),
            child: pw.Container(height: 9, color: _gold)),
        if (pct < 100)
          pw.Expanded(
              flex: (100 - pct).clamp(0, 99),
              child: pw.Container(height: 9, color: _line)),
      ]),
    ),
    pw.SizedBox(height: 8),
    _prose('Across ${d.followThrough.sample} Flow sessions. Follow-through is a '
        'quiet measure of doing what you decided to do - finishing the block '
        'you set, not just starting it.'),
  ]);
}

// ── 9. Focus Stamina ──────────────────────────────────────────────────────────

pw.Widget _staminaSection(FocusReportData d) {
  final mins = d.currentStaminaMinutes!;
  final nonNull = d.staminaGrowth.where((p) => p.value != null).length;
  final line = InsightsCopy.staminaInsight(d.staminaGrowth);
  final maxVal = d.staminaGrowth
      .where((p) => p.value != null)
      .fold(90.0, (m, p) => p.value! > m ? p.value! : m);
  return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
    pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
      pw.Text('$mins',
          style: pw.TextStyle(
              fontSize: 30, color: _gold, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(width: 6),
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 5),
        child: pw.Text('minutes of unbroken focus',
            style: const pw.TextStyle(fontSize: 10, color: _muted)),
      ),
    ]),
    pw.SizedBox(height: 6),
    pw.Text(
        'The length of deep focus you can hold in one unbroken block - the '
        'average of your recent qualifying Flow blocks. The 90-minute deep-work '
        'mark is a reference athletes train toward, not a line you must hit today.',
        style: const pw.TextStyle(fontSize: 10, color: _muted, lineSpacing: 2.5)),
    if (nonNull >= 3) ...[
      pw.SizedBox(height: 12),
      _vBarChart(_fromTrend(d.staminaGrowth, maxVal), height: 42),
    ],
    if (line != null) ...[
      pw.SizedBox(height: 8),
      _prose(line),
    ],
  ]);
}

// ── 10. Personal bests ────────────────────────────────────────────────────────

pw.Widget _bestsBlock(FocusReportData d) {
  final rows = <pw.Widget>[
    if (d.bestDayFocus != null)
      _bestRow('Best focus day', formatFocusDuration(d.bestDayFocus!),
          d.bestDayDate == null ? null : formatDate(d.bestDayDate!)),
    if (d.longestSession > Duration.zero)
      _bestRow('Longest single block', formatFocusDuration(d.longestSession),
          d.longestSessionDate == null ? null : formatDate(d.longestSessionDate!)),
    if (d.highestFocusScore != null)
      _bestRow('Highest Focus Score', '${d.highestFocusScore} / 100', null),
    if (d.bestStreak >= 1) _bestRow('Best streak', '${d.bestStreak} days', null),
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
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 11, color: _ink)),
          pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
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

String _bestsClose(FocusReportData d) {
  final parts = <String>[];
  if (d.longestSession > Duration.zero) {
    parts.add('your longest block at ${formatFocusDuration(d.longestSession)}');
  }
  if (d.bestDayFocus != null) {
    parts.add('your best day at ${formatFocusDuration(d.bestDayFocus!)}');
  }
  if (d.highestFocusScore != null) {
    parts.add('your highest Focus Score at ${d.highestFocusScore}');
  }
  if (d.bestStreak >= 1) parts.add('a best streak of ${d.bestStreak} days');
  if (parts.isEmpty) return 'Every record here really happened.';
  return 'These are the bars you\'ve already cleared - ${_joinList(parts)}. '
      'Each one really happened.';
}

String _joinList(List<String> parts) {
  if (parts.length == 1) return parts.first;
  return '${parts.sublist(0, parts.length - 1).join(', ')} and ${parts.last}';
}

// ── 11. Milestones ────────────────────────────────────────────────────────────

pw.Widget _milestones(FocusReportData d) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [for (final m in d.milestones) _milestoneRow(m)],
    );

pw.Widget _milestoneRow(Milestone m) {
  final date = m.date;
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 9),
    child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
      pw.Container(
          width: 7,
          height: 7,
          decoration:
              const pw.BoxDecoration(color: _gold, shape: pw.BoxShape.circle)),
      pw.SizedBox(width: 12),
      pw.Expanded(
        child: pw.Text(m.label,
            style: const pw.TextStyle(fontSize: 11, color: _ink)),
      ),
      date == null
          ? pw.SizedBox()
          : pw.Text(formatDate(date),
              style: const pw.TextStyle(fontSize: 9, color: _muted)),
    ]),
  );
}

// ── 12. Intention themes ──────────────────────────────────────────────────────

pw.Widget _intentions(IntentionThemes t) {
  final maxCount =
      t.topPhrases.fold(1, (m, p) => p.count > m ? p.count : m);
  return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
    _prose('You set an intention on ${t.sessionsWithIntention} of '
        '${t.totalSessions} sessions. These are the words you return to most:'),
    pw.SizedBox(height: 12),
    for (final p in t.topPhrases)
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
          pw.SizedBox(
            width: 110,
            child: pw.Text(p.phrase,
                style: pw.TextStyle(
                    fontSize: 11,
                    color: _ink,
                    fontWeight: p == t.topPhrases.first
                        ? pw.FontWeight.bold
                        : pw.FontWeight.normal)),
          ),
          pw.Expanded(
            child: pw.ClipRRect(
              horizontalRadius: 4,
              verticalRadius: 4,
              child: pw.Row(children: [
                pw.Expanded(
                    flex: (p.count / maxCount * 1000).round().clamp(2, 1000),
                    child: pw.Container(height: 8, color: _goldSoft)),
                pw.Expanded(
                    flex: (1000 - (p.count / maxCount * 1000).round()).clamp(0, 998),
                    child: pw.Container(height: 8, color: _line)),
              ]),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Text('${p.count}x',
              style: const pw.TextStyle(fontSize: 9, color: _muted)),
        ]),
      ),
  ]);
}

// ── 13. Closing note ──────────────────────────────────────────────────────────

pw.Widget _closingNote(FocusReportData d) {
  final spanDays = d.firstSessionDate == null
      ? 0
      : d.now.difference(d.firstSessionDate!).inDays;
  final String line;
  if (spanDays >= 90 || (d.focusScore ?? 0) >= 65) {
    line = 'You train your focus like an athlete. Keep going.';
  } else if (spanDays >= 25) {
    line = 'A month of practice, and it shows. Train on.';
  } else if (d.activeDaysTotal >= 3) {
    line = 'You\'re finding the rhythm. Keep it - it\'s already working.';
  } else {
    line = 'A real beginning. The next block is the only one that matters.';
  }
  return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
    pw.Container(height: 1.5, width: 40, color: _gold),
    pw.SizedBox(height: 12),
    pw.Text(line,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
            fontSize: 13,
            color: _ink,
            fontWeight: pw.FontWeight.bold,
            lineSpacing: 3)),
  ]);
}

// ── 14. Glossary ──────────────────────────────────────────────────────────────

pw.Widget _glossary(FocusReportData d) {
  final terms = <({String term, String def})>[
    (
      term: 'Flow, Pomodoro & Custom',
      def: 'The three session modes. Flow is an open block you sustain as long '
          'as you can; Pomodoro is a fixed work/break rhythm; Custom is a length '
          'you set yourself. Focus Score, Stamina and Follow-through follow your '
          'Flow sessions only; everything else counts all three.'
    ),
    (
      term: 'Streak',
      def: 'Consecutive days with at least one focused session. Your current '
          'streak counts back from today; your best streak is the longest such '
          'run you have ever had.'
    ),
  ];
  if (d.focusScore != null) {
    terms.insert(0, (
      term: 'Focus Score',
      def: 'A 0-100 measure of how deep your recent focus runs - the rounded '
          'average of your last 10 Flow sessions, each scored on how fully you '
          'reached the block you chose. It counts Flow sessions of 2 minutes or '
          'more and ramps over your first ~10.'
    ));
  }
  if (d.isPro && d.currentStaminaMinutes != null) {
    terms.add((
      term: 'Focus Stamina',
      def: 'The length of deep focus you can hold in one unbroken block, in '
          'minutes - the average of your recent qualifying Flow blocks. The '
          '90-minute deep-work mark is a reference, not a cap.'
    ));
  }
  if (d.followThrough.sample >= 5) {
    terms.add((
      term: 'Follow-through',
      def: 'How often your Flow sessions reach the mark you set - the share you '
          'completed without abandoning. It reads most steadily past five Flow '
          'sessions.'
    ));
  }
  return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
    _section('HOW THESE NUMBERS WORK', 'So the report explains itself.'),
    pw.SizedBox(height: 12),
    for (final t in terms)
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 10),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(t.term,
              style: pw.TextStyle(
                  fontSize: 10, color: _ink, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 2),
          pw.Text(t.def,
              style: const pw.TextStyle(fontSize: 9, color: _muted, lineSpacing: 2.5)),
        ]),
      ),
  ]);
}

// ── Chart primitives ──────────────────────────────────────────────────────────

/// A row of vertical bars. [bars] carry a 0..1 height fraction; highlighted bars
/// render gold, present-but-low bars soft gold, empty bars a faint line. Labels
/// (optional) sit under each bar, the peak in bold ink.
pw.Widget _vBarChart(
  List<({String label, double frac, bool hi})> bars, {
  double height = 56,
  bool labels = true,
}) {
  final tight = bars.length > 18;
  pw.Widget bar(({String label, double frac, bool hi}) b) => pw.Container(
        height: (b.frac * (height - 2)).clamp(2, height - 2).toDouble(),
        decoration: pw.BoxDecoration(
          color: b.hi ? _gold : (b.frac > 0.001 ? _goldSoft : _line),
          borderRadius: pw.BorderRadius.circular(2.5),
        ),
      );
  return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
    pw.SizedBox(
      height: height,
      child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
        for (var i = 0; i < bars.length; i++) ...[
          if (i > 0) pw.SizedBox(width: tight ? 2 : 4),
          pw.Expanded(
              child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [bar(bars[i])])),
        ],
      ]),
    ),
    if (labels && bars.any((b) => b.label.isNotEmpty)) ...[
      pw.SizedBox(height: 4),
      pw.Row(children: [
        for (var i = 0; i < bars.length; i++) ...[
          if (i > 0) pw.SizedBox(width: tight ? 2 : 4),
          pw.Expanded(
            child: pw.Text(bars[i].label,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                    fontSize: 7,
                    color: bars[i].hi ? _ink : _muted,
                    fontWeight:
                        bars[i].hi ? pw.FontWeight.bold : pw.FontWeight.normal)),
          ),
        ],
      ]),
    ],
  ]);
}

List<({String label, double frac, bool hi})> _fromTimeBars(List<TimeBar> bars) {
  final maxS = bars.fold(1, (m, b) => b.focus.inSeconds > m ? b.focus.inSeconds : m);
  return [
    for (final b in bars)
      (label: b.label, frac: b.focus.inSeconds / maxS, hi: b.highlight)
  ];
}

List<({String label, double frac, bool hi})> _fromTrend(
    List<TrendPoint> pts, double maxVal) {
  final mx = maxVal <= 0 ? 1.0 : maxVal;
  return [
    for (final p in pts)
      (label: p.label, frac: p.value == null ? 0.0 : p.value! / mx, hi: false)
  ];
}
