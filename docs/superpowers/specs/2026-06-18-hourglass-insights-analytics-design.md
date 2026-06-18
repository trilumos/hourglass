# Hourglass — Insights (Analytics) Page — Design

> Spec date: 2026-06-18. V1 roadmap item #2 (Analytics). Status: **design locked by founder 2026-06-18** (purpose, merge, range model, chart set, and final section order all confirmed).

## Summary

Build a single **Insights** page that **merges** today's Activity screen with the planned Analytics charts. One destination for "your focus data": a lifetime records scorecard, the consistency heatmap, and a curated set of period-scoped charts (focus over time, when-you-focus rhythm, by-mode split) governed by one Week/Month/All toggle.

Decision rationale (do not relitigate without founder):
- **Merge, not two pages.** Activity and Analytics are the same thing — "your focus over time." Splitting fragments the story and duplicates the records surface. Research is explicit: one clear purpose, one destination, minimum cognitive load.
- **Curated, not a dashboard wall.** The brand is calm / premium / focus-training, not feature-dense (`docs/design-language.md`, `docs/project-context.md`). A small set of beautiful charts that tell a story beats maximal coverage.
- **Numbers first, then pictures; lifetime above the toggle, period below it.** Final order decided by priority analysis (frequency checked × emotional weight × glanceability).

## Naming & entry point

- Page name: **"Insights"**.
- In `ProfileScreen` → **MORE** section, the two existing rows — **"Activity"** (→ `ActivityScreen`) and **"Analytics — Soon"** (disabled `_NavRow(soon: true)`) — are **replaced by one row**: `Insights · Charts of your focus` → `InsightsScreen`.
- `ActivityScreen` (`lib/ui/activity_screen.dart`) is **renamed/reworked** into `InsightsScreen` (`lib/ui/insights_screen.dart`); no dead file is left. Update every referrer (currently only `ProfileScreen`; verify during implementation).

## Final section order (locked)

Top → bottom:

1. **RECORDS** — lifetime scorecard, *first*. Internally ordered by weight: **Total focus** + **Current streak** lead, then **Best streak** · **Avg session** · **Longest** · **Sessions**; `Focusing since <date>` caption closes it. (Reuses existing `profileStatsProvider` + `StatTile`.)
2. **CONSISTENCY** — the existing `ContributionGraph` heatmap. Lifetime, fixed ~4-month view, **no toggle**. Sits second to cash in the visual payoff of the streak just read as a number above.
3. **Range toggle** — `[ Week · Month · All ]` segmented control. Governs **everything below it** (sections 4–6) and nothing above it, so its scope is never ambiguous.
4. **FOCUS OVER TIME** — bar chart of focus minutes over the selected range, with a `<total> this <period>` caption. Primary period chart.
5. **WHEN YOU FOCUS** — **Time of day** (6 buckets) first, **Day of week** (7 days) second. The signature self-knowledge insight.
6. **BY MODE** — donut of focus-time share across Flow Block / Pomodoro / Custom, with a small legend. Last (lowest priority, slowest-changing).

Layout is a single scrolling `ListView` inside `ScreenBackground` + `SafeArea`, `HgSpacing.screen` horizontal padding, `ScreenHeader(title: 'Insights')` — identical scaffolding to the current Activity/Profile screens. Each chart sits inside the existing `SurfaceTile`. Section labels use the existing all-caps muted `_Label` style.

## Data model & ranges

All charts derive from `List<SessionRecord>` already provided by `sessionRepositoryProvider.allSessions()`. Only sessions with `recordedFocus > Duration.zero` count (consistent with `StatsCalculator`). "Now" is injected via `clockProvider` for testability.

### Range windows (date-only, inclusive of today)

| Range | Window | Focus-over-time bucketing |
|---|---|---|
| **Week** | last 7 days `[today-6 .. today]` | 7 daily bars, labeled by weekday initial (M T W T F S S) |
| **Month** | last 30 days `[today-29 .. today]` | 30 daily bars; sparse axis labels (first / mid / last + tap-for-value); reads as a clean trend |
| **All** | first focused session → today | one bar per calendar month, labeled `MMM` (append `'yy` when the span crosses years) |

The same window (Week=7d, Month=30d, All=everything) scopes **Time of day**, **Day of week**, and **By mode**. The **caption total** under Focus-over-time is the summed focus across the window.

### Time-of-day buckets (6, fixed order)

Keyed off `startedAt.hour`. Boundaries cover all 24h:

| Bucket | Hours |
|---|---|
| Early | 05:00–07:59 |
| Morning | 08:00–11:59 |
| Midday | 12:00–13:59 |
| Afternoon | 14:00–16:59 |
| Evening | 17:00–20:59 |
| Night | 21:00–04:59 |

### Day of week (7, fixed order)

Monday → Sunday, keyed off `startedAt.weekday`. Labeled by initial.

### By mode (always 3 slices, fixed order)

`[flowBlock, pomodoro, custom]`, each with summed focus and a `fraction` of the range total (0 allowed). Fixed set keeps the donut + legend stable across ranges.

## Architecture

Follows the existing domain/data/providers/ui split.

### Domain: `lib/domain/analytics_calculator.dart` (pure Dart, TDD)

A sibling to `StatsCalculator`, keeping that class focused. Pure functions on `(AnalyticsRange range, DateTime now, List<SessionRecord> sessions)` → fully unit-testable, no Flutter imports.

```dart
enum AnalyticsRange { week, month, all }

/// One labeled bar (used by focus-over-time and both rhythm charts).
class TimeBar {
  final String label;
  final Duration focus;
  final bool highlight; // peak bar (rhythm) or current period (over-time)
}

class ModeSlice {
  final SessionMode mode;
  final Duration focus;
  final double fraction; // 0..1 of range total; 0 when total is 0
}

class AnalyticsData {
  final List<TimeBar> focusOverTime; // 7 | 30 | N months
  final List<TimeBar> timeOfDay;     // always 6
  final List<TimeBar> dayOfWeek;     // always 7
  final List<ModeSlice> byMode;      // always 3
  final Duration rangeTotal;         // caption
  final bool isEmpty;                // no focus in the selected range
}

class AnalyticsCalculator {
  const AnalyticsCalculator();

  AnalyticsData compute(AnalyticsRange range, DateTime now, List<SessionRecord> sessions);

  // Public sub-methods so each is unit-tested directly:
  List<SessionRecord> sessionsInRange(AnalyticsRange range, DateTime now, List<SessionRecord> sessions);
  List<TimeBar> focusOverTime(AnalyticsRange range, DateTime now, List<SessionRecord> sessions);
  List<TimeBar> timeOfDay(List<SessionRecord> inRange);
  List<TimeBar> dayOfWeek(List<SessionRecord> inRange);
  List<ModeSlice> byMode(List<SessionRecord> inRange);
}
```

Highlight rules: `focusOverTime` highlights the latest bucket (today / current month). Each rhythm chart highlights its single max bar when that max focus > 0 (ties → first). `isEmpty` is true when `rangeTotal == Duration.zero`.

### Providers: add to `lib/app/providers.dart`

```dart
/// Selected analytics window. Default: week.
final analyticsRangeProvider = StateProvider<AnalyticsRange>((ref) => AnalyticsRange.week);

/// All analytics series for the selected range.
final analyticsProvider = FutureProvider<AnalyticsData>((ref) async {
  final sessions = await ref.watch(sessionRepositoryProvider).allSessions();
  final now = ref.watch(clockProvider)();
  final range = ref.watch(analyticsRangeProvider);
  return const AnalyticsCalculator().compute(range, now, sessions);
});
```

Records reuse `profileStatsProvider`; the heatmap reuses `dailyFocusProvider` + `ContributionGraph`. No DB/schema changes.

### UI: chart widgets in `lib/ui/widgets/` (thin wrappers over `fl_chart`)

- `FocusTrendChart(bars)` — `fl_chart` `BarChart`. Rounded bars, no chart background, hairline baseline only (`gridData` mostly off). Today's/current bar uses full `accent`; the rest `accent` @ ~60% opacity. Tap shows a tooltip with the bucket's exact value (`BarTouchData`).
- `RhythmBars(bars)` — `BarChart`. Peak bar full `accent`; others `accent` @ ~30%. Used for both Time-of-day and Day-of-week.
- `ModeDonut(slices)` — `fl_chart` `PieChart` with `centerSpaceRadius` (donut). Flow = `accent`; Pomodoro = `accent` @ ~55%; Custom = `accent` @ ~30%. Legend rows: swatch + mode name + `NN%`.

**Token discipline (design mandate):** every color/size comes from `HgColors`/tokens via `context.hg` (`accent`, `accentMuted`, `hairline`, `textMuted`, `textSecondary`, `surface*`) and `HgSpacing`/`HgRadius`/`HgFont`. Mode/rhythm tints are opacity derivations of `accent` — **no new tokens, no hardcoded hex**. Restyles stay cheap.

**Motion:** keep `fl_chart`'s default draw-on animation (bars grow, donut sweeps) for the premium feel; respect the existing motion tokens for durations where applicable.

### Dependency

Add `fl_chart` (MIT, free) via `flutter pub add fl_chart` — pin whatever the resolved stable version is in `pubspec.yaml`.

## Empty / low-data states

New users must see something intentional, never a broken axis.

- **No focused sessions ever** (lifetime total is zero): the page shows the header + a single calm line — *"Your insights appear as you focus. Begin your first block."* No skeleton charts, no empty records grid.
- **Has lifetime data, but nothing in the selected range** (e.g. lifetime data but "Week" is empty): Records + heatmap still render (they're lifetime), and each toggled chart shows a quiet *"No focus in this period."* in place of an empty plot. The page is never blank.
- **Sparse data**: charts render with whatever exists; fixed-set charts (time-of-day 6, day-of-week 7, by-mode 3) always show their full set with zero-height bars where empty, so the layout is stable.

## Responsiveness & accessibility

New UI must be built responsive from the start (a full audit is a separate P0 in `docs/v1-launch-checklist.md`):
- Page is a `ListView` → scrolls; nothing relies on fixed viewport height.
- Charts size to available width via `LayoutBuilder`/`Expanded` (as `ContributionGraph` already does); fixed, modest chart heights that tolerate large `textScaler`.
- Honor `MediaQuery.textScaler` for all labels/captions; no clipped text, no `RenderFlex` overflow at text scale 0.85–1.5 and small widths.

## Testing

Keep the suite green (115 at last count) and `flutter analyze` clean.

- **`AnalyticsCalculator` unit tests (TDD, write first)** — for each public method:
  - empty sessions; single session; multi-day spread.
  - range-window boundaries: a session exactly at the window's first instant is included; one just before is excluded.
  - `focusOverTime`: Week → 7 bars in order; Month → 30 bars; All → correct month buckets from first session to now; highlight on latest bucket.
  - `timeOfDay`: bucket-boundary cases (07:59 → Early vs 08:00 → Morning; 21:00 and 04:59 → Night); always 6 in fixed order; peak highlight; ties → first.
  - `dayOfWeek`: weekday mapping Mon→Sun; always 7.
  - `byMode`: always 3 in fixed order; fractions sum to ~1 when total > 0; all-zero when total is 0.
  - `compute`: `isEmpty`/`rangeTotal` correctness; range filtering applied consistently across all series.
- **Widget smoke tests** — `InsightsScreen` builds with empty providers (shows the empty line) and with populated providers (shows records + charts); switching `analyticsRangeProvider` updates the displayed series. Chart widgets build with empty and populated inputs without throwing.

## Out of scope (this build)

- **Focus Score trend line** and **session-length distribution** (these were the "Rich Insights" extras; not chosen). A Focus-Score-over-time sparkline may later live on the existing Focus Score page, not here.
- Per-chart independent ranges, data export, goals/targets, comparisons vs previous period.
- Any cloud/sync work (V2). No schema changes here.

## Files touched (anticipated)

- **New:** `lib/domain/analytics_calculator.dart`; `lib/ui/insights_screen.dart`; `lib/ui/widgets/focus_trend_chart.dart`, `rhythm_bars.dart`, `mode_donut.dart`; matching tests under `test/`.
- **Modified:** `lib/app/providers.dart` (range + analytics providers); `lib/ui/profile_screen.dart` (replace the two rows with one "Insights" row + import); `pubspec.yaml` (`fl_chart`).
- **Removed:** `lib/ui/activity_screen.dart` (folded into `insights_screen.dart`).
