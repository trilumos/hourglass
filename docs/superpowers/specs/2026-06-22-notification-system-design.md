# Notification System — Design

**Date:** 2026-06-22
**Status:** Founder-approved scope (2026-06-22). Builds on the session foreground
service (`lib/session/session_guard.dart`, shipped 2026-06-22).

## Goal

A full, on-device notification system on the FGS foundation, in two engines:

- **A. In-session (FGS):** the live, non-dismissable session notification +
  discrete buzzing alerts at each transition. Already ~80% built.
- **B. Scheduled engagement:** quotes/tips, a user-set focus reminder, streak
  reminders, achievement unlocks. **All opt-in, default OFF, positively framed.**

Everything is local — no servers, no telemetry. The offline/no-analytics stance
(LOCKED) is unchanged.

## Brand rule (LOCKED — reaffirmed, the reconciliation)

The brand promise — *"Sustain will never punish you for a missed day… no
guilt-trip notifications — only reminders you set yourself"* — is honored by
making **every** scheduled/engagement notification:

1. **Opt-in, default OFF.** Nothing fires unless the user enables it. The
   POST_NOTIFICATIONS prompt appears only when they turn on the first one.
2. **User-controlled.** A Settings → Notifications panel: a master switch, a
   per-type toggle, and the reminder time.
3. **Positively framed.** Encouragement, never failure/shame ("Keep your streak
   alive — a few minutes counts," not "You're about to lose your streak").

The streak **1-day grace** is itself forgiving (on-brand); only the optional
reminder about it is a nudge, and it follows the opt-in rules above.

## A. In-session notification (FGS)

One persistent, non-dismissable notification (the silent live countdown) + a
separate high-importance **alerts** channel for the discrete buzzes. Alerts are
fired from the **service isolate** (reliable under screen-off via the FGS
wakelock); the live countdown is the FGS notification updated each second.

| State | Notification (live) | Buzzing alert |
|---|---|---|
| Focusing | "Focusing — tap to return" (no countdown, calm) | — |
| Break | "Break · m:ss" (live) | start: "Break — rest your eyes"; end: "Back to focus" |
| Paused (in-app) | "Paused — tap to return" | — |
| Leave grace | "Come back · 0:ss" (live) | expiry: "Block ended" |
| Pause-away | "You're paused · m:ss" → cap | cap: "Your pause is up · 0:15"; expiry: "Block ended" |
| Session end | — | "Session complete" |

**Custom/beautiful:** branded hourglass status icon (done), brand-color accent
(`backgroundColor`), a **Return** action button. Richer native layouts (progress
bar, RemoteViews) are deferred — the plugin can't do them.

## B. Scheduled engagement (all opt-in, default OFF)

**Infra:** re-add `flutter_local_notifications`; a `NotificationService` wrapper
(init + channels + permission); a `NotificationPrefs` (persisted); a scheduler
for the daily items; Settings → Notifications panel.

1. **User-set focus reminder** — daily at a user-chosen time. "Time to train
   your focus." The brand-safe "reminder you set yourself."
2. **Streak 1-day grace + reminder**
   - **Grace logic:** a streak survives a *single* gap day; it breaks only after
     **two consecutive** no-focus days. Anchor = today if focused, else yesterday
     (the grace day). Pinned with unit tests; `homeStats`, Insights, and the
     guide copy update to match.
   - **Reminder (opt-in):** when a streak is at risk (yesterday focused, today
     not, evening), one gentle nudge.
3. **Daily quotes & tips** — one per day at a chosen time, rotating a curated
   library (reuse the home/session quote pool + focus tips).
4. **Achievements & milestones** — a catalog (streak lengths, total-focus hours,
   longest session, session counts, focus-score highs, completed counts).
   Detected on session save; persisted (unlocked + date); an **Achievements**
   screen (locked/unlocked); an in-app celebration + an opt-in unlock notification.

## Data / logic changes

- **Streak calc** gains the 1-day grace (one definition, reused by home + insights).
- **Achievements store** (Drift table: id, unlockedAt) + catalog + detector.
- **NotificationPrefs** (persisted toggles + reminder time).

## Deferred to v2

- Richer native notification layout (progress bar / custom RemoteViews).

## Build order (each an independent, tested commit)

1. `flutter_local_notifications` + `NotificationService` (channels, permission).
2. In-session alerts (service isolate) + live break timer + Return action.
3. Settings → Notifications panel + `NotificationPrefs` + permission prompt.
4. User-set focus reminder.
5. Streak 1-day grace (logic + tests + guide) + streak reminder.
6. Daily quotes & tips.
7. Achievements (store + detector + screen + unlock notification).
