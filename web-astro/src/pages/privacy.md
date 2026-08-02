---
layout: ../layouts/Doc.astro
title: Privacy Policy
description: Sustain stores your focus data only on your device. No analytics, no tracking, no advertising, no account.
---

# Sustain — Privacy Policy

**Effective date:** 25 June 2026
**Applies to:** the Sustain Android app (`com.trilumos.sustain`) and the Sustain website (sustaintimer.com)
**Contact:** trilumos.app@gmail.com

Sustain is built privacy-first. The short version: **your focus data never leaves
your device, and we don't run any analytics, tracking, or advertising.**

---

## 1. What Sustain stores, and where

Everything you create in Sustain is stored **only on your device** (in the app's
private storage):

- Your **focus sessions** (durations, modes, timestamps, your Focus Score, streaks).
- Your **profile** (the name and photo you optionally set).
- Your **settings** (theme, notification preferences, etc.).

We do **not** have a server. We never receive, see, or store this data. If you
uninstall the app (without backing up first), this data is gone.

You can export or back up this data yourself at any time from **Settings → Your
data**, and you can erase it all from the same place.

## 2. What we do NOT collect

- **No analytics or telemetry.** Sustain ships with no third-party analytics or
  crash-reporting SDKs. We do not measure how you use the app.
- **No advertising** and no ad identifiers.
- **No tracking** across apps or websites.
- **No location, contacts, microphone, SMS, or call data.**
- **No account.** Sustain v1 has no sign-in; there is no cloud profile.

## 3. Purchases

If you choose to buy Sustain Pro (or another in-app purchase), the transaction is
handled by **Google Play Billing**, and entitlements are managed by **RevenueCat**,
our purchase-management provider. To deliver and restore your purchase, these
services process purchase data (such as the purchase token and an anonymous,
randomly-generated app user identifier). This does **not** include your name,
email, or focus data.

- Google Play Privacy Policy: https://policy.google.com/privacy
- RevenueCat Privacy Policy: https://www.revenuecat.com/privacy

We use these only to unlock what you paid for and to let you restore purchases.

## 4. Permissions, and why

Sustain requests only what its features need:

- **Notifications** (`POST_NOTIFICATIONS`) — only if you turn on reminders or run a
  session; all notifications are generated locally on your device.
- **Foreground service / wake lock** — to keep your live session timer accurate and
  show the "come back" notification while the app is in the background.
- **Exact alarms** — so time-sensitive session alerts (pause cap, grace windows)
  fire on time, even in battery-saver/doze.
- **Run after restart** — to re-schedule any reminders you set after a reboot.
- **Internet / network state** — used **only** to process purchases (above). Sustain
  does not send your focus data anywhere.

Photo selection (for your profile picture) uses the system photo picker, so the app
never needs access to your whole photo library.

## 5. The website (sustaintimer.com)

The web timer follows the same rule as the app: **nothing you do is sent anywhere.**

- **No server.** The site is static files. There is no backend to receive your data,
  and no account to create.
- **No analytics, no cookies, no ad or tracking scripts.** We do not know who visits
  or what you do here beyond what our host records to serve the page.
- **Local storage only.** Your setup choices (mode, durations, sounds, number look,
  intention) and today's focus total are kept in your browser's own local storage on
  your device. Clearing your browser data erases them. They are never uploaded.
- **Your location is never requested.** To move the sky with your day, the site reads
  your browser's **timezone** (e.g. `Asia/Kolkata`) and computes sunrise and sunset
  mathematically. No GPS, no permission prompt, and the timezone is never sent anywhere.
- **Fonts.** The site currently loads its display fonts from Google Fonts, which means
  Google's servers see the request for those font files.
- **Outbound links.** The "Get it on Google Play" links go to Google Play, which has
  its own privacy policy.

## 6. Children

Sustain does not knowingly collect any personal data from anyone, including
children. It contains no ads and no data collection.

## 7. Data deletion

Because your data lives only on your device, you are always in control:

- **Erase everything:** Settings → Your data → clear data, or uninstall the app.
- **Export a copy:** Settings → Your data → back up.

## 8. Changes to this policy

If this policy changes, we'll update this page and the "Effective date" above.
Material changes will be noted in the app's release notes.

## 9. Contact

Questions about privacy? Email **trilumos.app@gmail.com**.
