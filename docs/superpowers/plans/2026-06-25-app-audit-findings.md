# Sustain — App-Wide Audit Findings (2026-06-25)

**Run against:** [`2026-06-24-app-wide-audit-plan.md`](2026-06-24-app-wide-audit-plan.md).
**Scope of this pass:** everything I own under [[the iron rule]] — internal correctness:
code-safety, logic, edge cases, consistency, claims-vs-code, and release config. **On-device
verification (smoothness, FGS live timer, real billing, push delivery) remains the founder's job**
and is listed separately at the end.

**Verification:** `flutter analyze` clean · **284 tests pass** · all fixes below have tests or are
config/doc-only.

---

## TL;DR

The codebase is in **strong shape**. No P0/P1 blockers found in the logic. I fixed **6 real issues**
(1 correctness bug, 3 perf/UX, 2 hygiene) and confirmed a long list of risk areas are already correct.
Remaining items are founder device-checks and small P2 polish.

---

## Fixed this pass

| # | Severity | Area | Issue | Fix |
|---|----------|------|-------|-----|
| 1 | **P1 (bug)** | Stats / streak | `currentStreak`, `bestStreak`, `focusInWeekEnding` walked dates with `subtract(Duration(days: 1))`. A fixed 24h duration drifts off local midnight across a DST transition (a calendar day is 23 or 25h), so on the ~2 DST days/year a streak could break or miscount for US/EU users. (India — primary market — has no DST, so it never showed there.) | Calendar arithmetic: `_minusDays(d,n) = DateTime(y,m,d-n)` always lands on local midnight; `bestStreak` gap rounds to the nearest day so a ±1h DST shift can't miscount. Behaviour-identical on non-DST days (all 284 tests unchanged). Added month/year-boundary streak tests. [`stats_calculator.dart`](../../../lib/domain/stats_calculator.dart) |
| 2 | P2 (perf/UX) | Avatar | `ProfileAvatar` used a `FutureBuilder` whose future (`resolve(path)`, an async docs-dir lookup) was rebuilt **every frame**. Each rebuild reset to the loading state → flashed the fallback glyph, and re-ran the platform call. | New cached `resolvedImageProvider` family (keyed by path) — resolved once, no re-flash; a new avatar filename is a new key so updates still refresh. [`providers.dart`](../../../lib/app/providers.dart), [`profile_avatar.dart`](../../../lib/ui/widgets/profile_avatar.dart) |
| 3 | P2 (perf) | Edit profile | The 112px avatar preview decoded the full 512² bitmap (no `cacheWidth/Height`). | Decode to on-screen size (× devicePixelRatio). [`edit_profile_screen.dart`](../../../lib/ui/edit_profile_screen.dart) |
| 4 | P2 (consistency) | Themes | Swatch border used a hardcoded `Color(0x22000000)` instead of a token (invisible on dark). | `context.hg.hairline`. [`themes_screen.dart`](../../../lib/ui/themes_screen.dart) |
| 5 | P2 (hygiene) | Tooling | `tools/gen_guide.py` pointed `SRC` at a temp file from a *previous* session that no longer exists — the generator can never run, yet `guide_content.dart`'s header said "do not hand-edit." | Deleted the dead generator; reworded the header to "hand-maintained — keep in sync with the FAQ." [`guide_content.dart`](../../../lib/ui/guide_content.dart) |
| 6 | — | (covered by #5) | Misleading "regenerate via tools/gen_guide.py" instruction. | Reconciled. |

---

## Verified correct (no change needed)

**Code safety (§2)**
- `flutter analyze` clean → `use_build_context_synchronously` satisfied; the post-`await` `context`/
  `Navigator`/`ScaffoldMessenger` guards are in place across `lib/ui`.
- **No** `TODO`/`FIXME`/`HACK`/`XXX` anywhere in `lib`.
- `dispose()`/`cancel()`/`close()` discipline is thorough: every `AnimationController`, `Timer`,
  `PageController`, `TextEditingController`, `StreamSubscription`, `StreamController`, and the
  RevenueCat customer-info listener is torn down. The billing service is an app-lifetime singleton
  (created in `main`, overridden into the provider) so its non-disposal is intentional.
- `kDebugMode` branches (dev Pro unlock, dev theme products) are `const false` in release → provably
  compiled out; no debug UI can leak to a shipped build.

**Claims vs. code (§2)** — every user-facing claim I checked matches the implementation:
- FAQ "unlimited longer pauses (up to 10 minutes)" = `StrictRules.pro` (cap 10m, unlimited); free = 3
  pauses / 3-min cap / 15s grace / 30s leave-grace.
- FAQ "keeping a Pomodoro or Custom session going past its end" → really implemented
  (`SessionController.addBlock`/`repeatPlan`/`extendNow`, Pro-gated via `allowContinue`).
- FAQ "session reuse" → `canReuse`/`decodeConfig` exists; reuse button on the summary screen.
- "A Flow block under 2 minutes records nothing" → enforced in the finalizer/score filter.
- "90 minutes is shown as a reference, not a limit" → matches the stamina model.

**Billing / paywall (§1.7, §3)**
- Offline / key-less degradation is graceful everywhere: missing offering → paywall hides tiles;
  `themeProducts` empty → "In Pro"; `proStatus` null → generic status card; nothing blocks the free
  loop. Initial `getCustomerInfo` failure is caught and the listener still delivers later.
- Purchase/restore map cancelled/pending/alreadyOwned/error correctly and **never celebrate on an
  error alone** — `alreadyOwned` re-syncs from verified state and only returns owned if Pro is truly
  active.
- `_planOf` is a documented best-effort substring heuristic (`life`/`year`/`annual`/`p1y`/`month`/
  `p1m`) that returns null → generic card. Safe.
- `_perMonthLabel` is a clearly-marked "≈" approximation: strips digits/separators/spaces for the
  symbol, mirrors prefix vs suffix placement, handles space thousands-separators, and returns null
  when it can't parse cleanly.

**Backup / restore (§1.11)**
- Merge-by-uuid is correct and atomic: existing uuids gathered, incoming duplicates skipped, the rest
  inserted in one batch, count returned. Settings/prefs/profile overwrite (merge semantics).
- A malformed / wrong-format file is handled: `importData` throws `BackupException`, and the restore
  UI catches both `BackupException` and a catch-all → friendly message, no crash.
- Entitlements are deliberately **not** in the backup (restore via Play).

**Session engine (§3)** — read end-to-end; internally consistent and well-guarded:
- Keep-going / endless cycling / `addBlock` / `extendNow` / `repeatPlan` resume from the right index
  (incl. a preceding rest); `goalReached` latches on the original plan total so a later-abandoned
  bonus block still counts as completed; recording rule (every mode records real focus; Flow ignores
  sub-2-min; score is Flow-only) is centralized.
- Pause limit / suspend (leave-grace freeze, no focus accrual) / skip-rest are all status-gated.

**Notifications / release (§1.4, §1.12, §5)**
- `NotificationCoordinator.sync` is idempotent (cancels-off / schedules-on); `syncNotifications`
  never throws; past-time pushes are skipped; streak nudge only when a live streak isn't yet kept.
- `AndroidManifest`: `allowBackup="false"`; FGS `specialUse`; permissions
  (POST_NOTIFICATIONS, FOREGROUND_SERVICE[_SPECIAL_USE], RECEIVE_BOOT_COMPLETED,
  USE/SCHEDULE_EXACT_ALARM) are each justified by the notification/strict-session features.
- Version consistent: `pubspec 1.0.0+1`, `applicationId com.trilumos.sustain`.

---

## Open P2 polish (non-blocking; my recommendation noted)

- **App version is hardcoded** as `'1.0.0'` in two spots in `settings_screen.dart`. Correct for launch
  (matches `pubspec 1.0.0+1`), but it will **drift on the next version bump**. *Recommend:* read it
  from `package_info_plus` at runtime, or keep a single `kAppVersion` const. Left as-is for now
  because adding a dependency is a product call — confirm and I'll wire it.
- **Re-crop limitation:** editing an existing photo only re-crops the stored 512² square (can't
  reframe wider). Acceptable for v1; persisting originals would be the V2 fix. (Founder decision.)
- **Header affordance consistency (§4):** some screens use `ScreenHeader`, others a manual back-row
  (e.g. `faq_screen`). Cosmetic; standardize opportunistically.

## Founder device-checks (the founder's half of [[the iron rule]] — I can't verify these)

These are the §1/§5/§6 items that need a real device/Play track, not code review:
- Profile-mode trace for jank (the "SMOOTH" track) — confirm the avatar/edit-preview fixes above land
  and nothing else janks.
- Real billing: buy each plan, restore, change-plan, à-la-carte theme buy, lifetime path — against the
  live RevenueCat product/base-plan ids (validate `_planOf` reads them right).
- Notification / FGS on-device: opt-in, permission denied→granted, grace pushes, reboot reschedule,
  notification-tap routing, Android 16 (API 36) behaviour.
- Responsiveness/a11y sweep: XS→XL font + display-zoom on every screen; TalkBack on core flows.
- `.aab` cold-start, first-run-no-data, Play pre-launch report.

(Full release gating lives in [`v1-launch-checklist.md`](../../v1-launch-checklist.md).)
