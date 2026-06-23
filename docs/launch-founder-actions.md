# Sustain v1 — Launch actions that need YOU

Everything here needs your accounts / device / hosting — I can't do it from code.
The answers are pre-filled to match how the app actually behaves, so most of this
is transcription.

## 1. Signing keystore (P0)
- Generate the upload keystore (see `android/key.properties.example` for the
  `keytool` command), put it outside the repo (or in `android/app/`, gitignored),
  and create `android/key.properties` from the example.
- In the Play Console, **enrol in Play App Signing** (recommended — Google holds the
  real key; your upload key only signs uploads).
- Back up the keystore + passwords somewhere safe. Losing the upload key (without
  Play App Signing) means you can't update the app.

## 2. Smoke-test the RELEASE build (P0 — important, R8 is on)
The release build now runs R8 (code shrink + obfuscation). R8 problems only show at
runtime, not in the build. Install the **release** build on a device and verify:
- A purchase + **restore purchases** works (RevenueCat/Billing under R8).
- Notifications fire (a scheduled reminder + an in-session grace alert).
- The foreground-service session notification + live timer work.
- Backup/restore (export then import) works.
If anything misbehaves, tell me and I'll widen the proguard keep rules (or we ship
v1 with R8 off).

## 3. Host the legal pages (P0)
- Host `docs/legal/privacy-policy.md` and `docs/legal/terms-of-service.md` at public
  URLs (GitHub Pages, a Notion page, or a one-pager site all work). Fill in the
  **effective date** and a **support email** in both first.
- Put the privacy-policy URL in the Play Console (App content → Privacy Policy).
- Optional but nice: link both from inside the app (Settings) — say the word.

## 4. Play Console → Data Safety form (P0)
Answer it like this (matches the app):
- **Does your app collect or share user data?** → *Yes* (only purchase data, via the
  payment processor).
- **Data collected:** *Purchase history* — collected, **not** shared, processed by
  Google Play + RevenueCat to deliver/restore purchases. Not used for tracking or
  ads. Not linked to identity (anonymous app user id).
- **Everything else** (personal info, location, photos, app activity/analytics,
  device ids) → **No / not collected.** (Focus data + profile never leave the device;
  the profile photo is picked via the system photo picker and stored locally only.)
- **Is all data encrypted in transit?** → *Yes* (purchase calls use HTTPS).
- **Can users request deletion?** → *Yes* — in-app (Settings → Your data → clear), and
  there's nothing server-side to delete.

## 5. Play Console → Content rating (IARC) (P0)
- Category: *Utility / Productivity*. No violence, sexual content, gambling, drugs,
  or user-to-user communication. Expected result: **Everyone / PEGI 3.**

## 6. Foreground-service declaration (P0)
- The app uses `FOREGROUND_SERVICE_SPECIAL_USE` for the live session timer. The Play
  Console will ask you to justify it: *"An ongoing user-initiated focus-session timer
  that keeps the countdown accurate and shows a return reminder while the app is
  backgrounded; the user starts and ends it."* (No `USE_EXACT_ALARM` declaration is
  needed — it's allowed for timer/alarm apps.)

## 7. Store listing (P1)
- App name **Sustain**, category Productivity, contact email.
- Short + full description (I can draft these — ask).
- Feature graphic + **phone screenshots** (premium ones — the app is the moat).
- Confirm the launcher icon is the branded one (no default Flutter icon).

## 8. Release process (P1)
- Build the publishable bundle: `flutter build appbundle --release` (with
  `key.properties` in place so it's signed for upload).
- Upload to an **internal testing** track first → dogfood → fix → **closed test** →
  production.
- Review the **pre-launch report** (Play runs it on real devices) and fix any
  crashes/ANRs.
- Ship as a **staged rollout** (10% → 50% → 100%) watching crashes/reviews.

## 9. At publish (your earlier request)
- Snapshot the whole v1 codebase into a frozen folder (e.g. `hourglass-v1-live/`) for
  live hotfixes; main repo continues as v1.2. (See `docs/feature-roadmap.md`.)
