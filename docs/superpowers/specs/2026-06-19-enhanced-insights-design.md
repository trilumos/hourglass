# Enhanced Pro Insights — Design Spec (Sustain)

> **Status:** scope LOCKED 2026-06-19 (brainstormed from
> `docs/references/insights-analytics-research-2026-06-19.md`). Implements the
> six v1 Pro Insights additions named in
> `docs/superpowers/specs/2026-06-19-monetization-and-v1-paid-tier-design.md` §3.4,
> plus a small **"Clear all data → re-onboard"** UX fix. Pure-calc first (TDD),
> then charts. **Built visible now; the Pro gate is wired when the entitlement
> engine lands** (build-now / gate-later, per the monetization plan).

---

## 1. The free vs Pro boundary (what this builds toward)

The Insights screen splits into two bands:
- **Free band:** **Records** (lifetime scorecard) + the **consistency heatmap**.
  (Unchanged; stays free — the motivating glance.)
- **Pro "depth" band:** everything below — the **existing** depth (Week/Month/All
  toggle, focus-over-time, when-you-focus, by-mode donut, period comparison,
  personalized copy) **+ the six additions below.**

**Gating approach:** build the whole depth band now, **visible to all**. A later
task (with the entitlement engine) wraps the depth band in a `ProGate` that shows
the content when `entitlementsProvider.pro` is true, else a calm upsell panel
("See your full focus story with Pro"). This spec only needs to keep the depth
band as **one cohesive, wrappable subtree** so that gate is a one-line wrap.

---

## 2. The six additions

All six use data we already record per session (`mode`, `plannedDuration`,
`recordedFocus`, `startedAt`, `completed`, `abandoned`) plus the existing pure
calculators. Each new series is added to `AnalyticsCalculator` (or a sibling pure
calculator) so it stays deterministic and unit-testable (`now` injected).

### 2.1 Focus Score trend
- **What:** a line of the Focus Score (0–100) over the selected range — the hero
  number's trajectory. (Opal gates exactly this: "Focus Score History".)
- **Calc:** replay Flow sessions oldest→newest (`mode == flowBlock`, `recordedFocus
  ≥ 2 min`), maintaining the list; after each, `FocusScoreCalculator().score(...)`
  over the sessions-so-far. Sample to the **same buckets as `focusOverTime`**
  (daily for week/month, monthly for all) using **carry-forward** of the last
  known score (a bucket with no new Flow session keeps the prior value; before the
  first scored session the line has no value). Returns `List<ScorePoint>`
  (`label`, `detail`, `value` 0–100, `hasValue`).
- **Viz:** `fl_chart` `LineChart`, y-axis 0–100, accent line, tap → readout
  (date + score). Same x-axis labels as focus-over-time for visual rhyme.
- **Empty/honesty:** if no scored Flow sessions in range, show "Your Focus Score
  trend appears once you've finished a few Flow sessions." (no fake line).

### 2.2 Focus Stamina growth
- **What:** a line of Focus Stamina (sustainable block length, minutes) climbing
  toward the 90-min ceiling — *unique to Sustain*.
- **Calc:** replay **completed, non-abandoned Flow blocks** oldest→newest; after
  each, `StaminaCalculator().currentStamina(blocks-so-far)` (minutes). Bucket
  with carry-forward like 2.1. Returns `List<StaminaPoint>` (minutes).
- **Viz:** `LineChart`, y in minutes (0–90, with a faint 90-min "ideal" guide
  line), tap → "Stamina: 32 min". 
- **Empty:** before any completed Flow block, show the default-start note.

### 2.3 Peak focus window (recommendation)
- **What:** a one-line, honest recommendation derived from the existing
  `timeOfDay` series: *"You focus best in the Morning (8am–12pm)."* (Rize's move.)
- **Calc:** the peak `timeOfDay` bucket (already highlighted). Add a helper that
  maps the peak bucket → label + clock range string. **Only show when there's
  enough signal** — require the peak bucket to hold ≥ ~25% of range focus AND ≥ a
  few sessions; else hide (no spurious advice). Returns `String?`.
- **Viz:** a calm caption directly under the "when you focus" chart (accent-muted
  panel), not a new chart.

### 2.4 Follow-through (completion) rate
- **What:** what share of Flow sessions you finish vs end early — controllable,
  honest (not vanity). 
- **Calc:** over the range, among **Flow** sessions, `completed && !abandoned`
  ÷ total Flow sessions → 0–1. Also compute the **previous-window** rate (same
  pattern as `previousWindowTotal`) for a comparison line. Returns
  `({double rate, double? prevRate, int sample})`.
- **Viz:** a stat ("Follow-through · 82%") with a small period-comparison line
  ("+6% vs last week"), styled like the existing comparison. Hide for all-time if
  no previous window. **Empty:** hide when sample is 0.
- **Honesty:** describe plainly; never guilt ("only 40%!") — neutral framing
  ("82% of your Flow sessions reached their mark").

### 2.5 Personal-bests timeline
- **What:** a short list of real records with dates — warm, motivating, factual.
- **Calc (new pure helper `PersonalBests`):** from all focused sessions —
  **best focus day** (max focus in a single day) + date; **longest session** +
  date; **best streak** (already in `StatsCalculator`); **highest Focus Score
  reached** (max of the 2.1 series); **focusing since** (first session date). Each
  entry null-safe (omitted if no data).
- **Viz:** a simple list of rows (label · value · date), in the depth band.

### 2.6 CSV / data export
- **What:** export focus history to CSV (Pro power-user lever; Be Focused gates
  exactly this).
- **Calc:** serialize all sessions → CSV rows: `startedAt (ISO), mode,
  plannedMinutes, focusedMinutes, completed, abandoned, intention` (intention
  quoted/escaped). Pure function `sessionsToCsv(List<SessionRecord>)`.
- **Delivery:** write to a temp file + share sheet via **`share_plus`** (new dep)
  — also works as "save to Files/Drive." Button in the depth band ("Export CSV").
- **Privacy:** export is user-initiated, local; nothing auto-sent. Keep the
  "collect nothing" story intact.

---

## 3. "Clear all data → re-onboard" (bundled small fix)
Today `_clearAll` (settings) deletes avatar + sessions + profile and invalidates
providers, but leaves `onboardingComplete = true`, so a wiped app lands on a
name-less Home instead of re-running onboarding.
- **Change:** in `_clearAll`, also
  `settings.setBool(SettingsKeys.onboardingComplete, false)` and invalidate
  `onboardingCompleteProvider`. After the confirm + clear, **navigate to a fresh
  start** — `Navigator.pushAndRemoveUntil(RootGate())` (or `OnboardingScreen`) —
  since the launch-time gate doesn't re-run on in-app navigation.
- **Result:** "Clear all data" == factory reset → onboarding runs again (the best
  path to recreate the name/photo profile), consistent with a fresh install.
  Onboarding stays skippable, so it's never a trap.

---

## 4. Files (planned)
- **Modify** `lib/domain/analytics_calculator.dart` — add `focusScoreTrend`,
  `staminaGrowth`, `peakWindowLabel`, `followThrough` (+ point/result types), all
  pure, `now`-injected. (Or a sibling `lib/domain/insights_extras.dart` if
  `analytics_calculator.dart` grows unwieldy — split by responsibility.)
- **Create** `lib/domain/personal_bests.dart` — pure `PersonalBests` deriver.
- **Create** `lib/domain/session_csv.dart` — pure `sessionsToCsv`.
- **Modify** `lib/app/providers.dart` — extend `analyticsProvider`'s
  `AnalyticsData` (or add providers) for the new series.
- **Modify** `lib/ui/insights_screen.dart` — add the new widgets in the depth
  band (kept as one wrappable subtree for later gating); reuse `BarReadoutChart`
  patterns; add `LineChart`s.
- **Modify** `lib/ui/insights_copy.dart` — warm copy for the new sections
  (honest, no fabricated stats).
- **Modify** `lib/ui/settings_screen.dart` — the clear-data re-onboard fix.
- **Add dep** `share_plus` (CSV export). `fl_chart` already present.

---

## 5. Testing
- **Pure calc (TDD, the bulk):** `focusScoreTrend` (carry-forward; ramp matches
  `FocusScoreCalculator`; empty range), `staminaGrowth` (climbs, ceiling, empty),
  `peakWindowLabel` (returns null below threshold; correct bucket+range string),
  `followThrough` (rate + prevRate + zero-sample null), `PersonalBests`
  (null-safe; correct maxima + dates), `sessionsToCsv` (header, escaping commas/
  quotes/newlines in intention, ISO dates, minutes rounding).
- **Widget:** Insights renders the new sections with seeded data; empty states
  show the honest copy, not blank/zero; export button present.
- **Clear-data:** after clear, `onboardingComplete` is false and the app routes to
  onboarding (gate/route test).
- Run serial: `flutter test --concurrency=1`; `flutter analyze` clean.

---

## 6. Build order (for the plan)
1. Pure calcs + tests (`focusScoreTrend`, `staminaGrowth`, `peakWindowLabel`,
   `followThrough`, `PersonalBests`, `sessionsToCsv`).
2. Wire into providers / `AnalyticsData`.
3. Insights UI: the six sections in the depth band (charts + caption + bests list
   + export button) + warm copy + empty states.
4. `share_plus` CSV export.
5. Clear-data → re-onboard fix.
6. (Later, with the entitlement engine) wrap the depth band in `ProGate` + upsell.

---

## 7. Deferred (recorded, not built here)
- **Daily/weekly goal + progress** → v1.2 (pairs with reminders; needs a goal
  setting). **Intention breakdown** → needs intention tagging. **Achievements** →
  v1.2 with V2 Levels (monetization spec §3.6). The **Pro gate + paywall** →
  with the entitlement engine.
