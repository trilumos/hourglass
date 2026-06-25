# Sustain — Play Console + RevenueCat Setup Guide
## For AI-assisted setup (hand this entire file to your AI assistant)

---

## Files & assets you will need (open these before you start)

All paths are relative to the project root: `d:\Dev\Trilumos\hourglass\`

| What | Path | Notes |
|---|---|---|
| **Signed release .aab** | `build\app\outputs\bundle\release\app-release.aab` | Upload this to Play Console. Re-build before final production release once the RevenueCat key is set. |
| **Upload keystore** | `android\app\upload-keystore.jks` | Do NOT share or commit this file. Back it up outside the repo. |
| **Key properties** | `android\key.properties` | Contains keystore path + passwords. Do NOT share or commit. |
| **Play Store icon (512×512)** | `icon images\android_icon\play_store_512.png` | Upload to Play Console store listing. |
| **Adaptive icon set** | `icon images\android_icon\res\` | The full Android adaptive icon set (foreground, background, monochrome, all densities). For reference only — the developer handles wiring these in. |
| **Privacy policy** | `docs\legal\privacy-policy.md` | Fill in effective date + support email, then host at a public URL before submitting. |
| **Terms of service** | `docs\legal\terms-of-service.md` | Same — fill in date + email, host publicly. |
| **This setup guide** | `docs\play-console-revenuecat-setup-guide.md` | The document you are reading. |
| **Founder action checklist** | `docs\launch-founder-actions.md` | Companion checklist with context on each action. |

### Before you start: two things to fill in

Open `docs\legal\privacy-policy.md` and `docs\legal\terms-of-service.md` and replace:
- `[FILL IN before publishing]` → today's date (e.g. "June 23, 2026")
- `[FILL IN — a support email you're happy to make public]` → `trilumos.app@gmail.com`

Then host both files at public URLs (GitHub Pages, Notion, a simple HTML page — anything
with a stable URL). You'll need the privacy policy URL for Play Console.

---

## Context for the AI reading this

You are helping the founder of **Sustain** — a calm focus-timer app for Android — set
up Google Play Console and RevenueCat billing so the app can be published. The app is
fully built and signed; this guide covers only account/console configuration. Follow
each section in order. The founder will do every step in the browser; you guide and
answer questions.

**Critical facts the AI must know:**

| Field | Value |
|---|---|
| App name | **Sustain** |
| Package name | `com.trilumos.sustain` |
| Version | `1.0.0+1` (version name 1.0.0, version code 1) |
| Category | Productivity |
| Contact / developer email | `trilumos.app@gmail.com` |
| Platform | Android only (v1) |
| Billing SDK | RevenueCat (`purchases_flutter`) |
| No server | All user data is local-only |
| No analytics | Zero telemetry, no crash reporting SDK |

---

## Part 1 — Google Play Console

### Step 1 · Create the app

1. Go to [play.google.com/console](https://play.google.com/console) and sign in with
   the Google account that will own this app.
2. Click **Create app**.
3. Fill in:
   - **App name:** `Sustain`
   - **Default language:** English (United States)
   - **App or game:** App
   - **Free or paid:** Free *(even though it has in-app purchases — the app itself is
     free to download)*
4. Confirm the declarations and click **Create app**.

---

### Step 2 · Upload the .aab to Internal testing (required before products activate)

Google Play products can only be tested and activated once an .aab has been uploaded
to at least one track.

1. Left sidebar → **Release** → **Testing** → **Internal testing**.
2. Click **Create new release**.
3. Upload the signed `.aab` file (the founder has this — it is the file built with
   `flutter build appbundle --release` and signed with the upload keystore).
4. **Release name:** `1.0.0 — internal` (or leave auto-filled).
5. **Release notes:** `Internal testing release.`
6. Click **Save** → **Review release** → **Start rollout to Internal testing**.

> **Why do this now?** Google will not activate in-app products until a valid .aab
> is in the system. Do this before creating products.

---

### Step 3 · Add internal testers

1. Still in Internal testing → **Testers** tab.
2. Create a list, add the founder's Gmail (and any other test devices).
3. Copy the opt-in URL and open it on the test device to join the track.

> This is also how RevenueCat sandbox purchases will work on the test device.

---

### Step 4 · Create in-app products (one-time purchases)

Go to: left sidebar → **Monetize** → **Products** → **In-app products**.

Create each product below. For each one:
- Click **Create product**
- Fill in the **Product ID** exactly as shown (case-sensitive, no spaces)
- **Name** and **Description** are store-facing (users see these)
- **Status:** Active
- Set a price (the founder decides — suggested prices are in brackets)
- **Pricing is USD-only (founder, 2026-06-25):** set the **USD** price below, then let
  Play **auto-convert** to local currencies for other countries (Play Console offers this when you
  set the price). Don't hand-set per-country (₹ etc.) tiers.
- Save + Activate

| Product ID | Name | Description | Price (USD) |
|---|---|---|---|
| `pro.lifetime` | Sustain Pro — Lifetime | Unlock all Pro features forever | **$59.99** |
| `theme.obsidian` | Obsidian Theme | Dark volcanic — deep black & amber | **$1.99** |
| `theme.sage` | Sage Theme | Earthy green calm | **$1.99** |
| `theme.rose` | Rosé Theme | Warm blush & rose gold | **$1.99** |
| `theme.indigo` | Indigo Theme | Deep blue focus | **$1.99** |
| `theme.dusk` | Dusk Theme | Warm amber twilight | **$1.99** |
| `theme.tide` | Tide Theme | Ocean teal & seafoam | **$1.99** |
| `theme.noir` | Noir Theme | Pure black & white contrast | **$1.99** |
| `theme.mocha` | Mocha Theme | Rich coffee browns | **$1.99** |
| `theme.aurora` | Aurora Theme | Flagship — deep cosmos, aurora shimmer | **$3.99** |

> **Important:** Product IDs use a **dot** separator (`theme.obsidian`). This must
> match exactly — the app derives the ID programmatically.

---

### Step 5 · Create subscriptions

Go to: left sidebar → **Monetize** → **Products** → **Subscriptions**.

Create 2 subscriptions:

#### Subscription 1: Monthly
- **Product ID:** `pro.monthly`
- **Name:** Sustain Pro — Monthly
- **Description:** Full Pro access, billed monthly. Cancel any time.
- Add a base plan:
  - **Base plan ID:** `monthly` (or any short ID)
  - **Billing period:** Monthly
  - **Price:** $4.99/month (USD; let Play auto-convert other countries)
  - **Free trial:** optional (7 days recommended for conversion)
- Save + Activate

#### Subscription 2: Annual
- **Product ID:** `pro.yearly`
- **Name:** Sustain Pro — Annual
- **Description:** Full Pro access for a full year. Best value.
- Add a base plan:
  - **Base plan ID:** `annual` (or any short ID)
  - **Billing period:** Yearly
  - **Price:** $29.99/year (USD; positions as "Best value" — shown with a savings badge vs monthly)
  - **Free trial:** optional (7 days recommended)
- Save + Activate

---

### Step 6 · Data Safety form

Left sidebar → **Policy** → **App content** → **Data safety**.

Answer every question exactly as follows:

**"Does your app collect or share any of the required user data types?"**
→ **Yes**

**Data types collected — check ONLY these:**

Under **Financial info:**
- ✅ **Purchase history** — check this one

Leave everything else unchecked:
- ❌ Personal info (name, email, address, phone, etc.) — NOT collected
- ❌ Health and fitness — NOT collected
- ❌ Messages — NOT collected
- ❌ Photos and videos — NOT collected
- ❌ Audio files — NOT collected
- ❌ Files and docs — NOT collected
- ❌ Calendar — NOT collected
- ❌ Contacts — NOT collected
- ❌ App activity (app interactions, search history, installed apps) — NOT collected
- ❌ Web browsing — NOT collected
- ❌ App info and performance (crash logs, diagnostics) — NOT collected
- ❌ Device or other IDs — NOT collected
- ❌ Location — NOT collected

**For "Purchase history" — fill in the sub-questions:**

| Question | Answer |
|---|---|
| Is this data collected, shared, or both? | **Collected** (not shared) |
| Is this data processed ephemerally? | No |
| Is collection required or can users opt out? | Required (needed to deliver the purchase) |
| Why is this data collected? | ✅ App functionality |
| Is this data used for your app's functionality? | Yes — to verify and restore purchases |
| Is this data linked to the user's identity? | **No** (RevenueCat uses an anonymous app user ID) |
| Is this data used for tracking? | **No** |

**Security practices:**

| Question | Answer |
|---|---|
| Is all user data encrypted in transit? | **Yes** (all purchase calls use HTTPS) |
| Do you provide a way for users to request deletion of their data? | **Yes** — in-app (Settings → Your data → Clear all data). There is no server-side data to delete; the in-app clear wipes the local database. |

Click **Save** → **Submit**.

---

### Step 7 · Content rating (IARC questionnaire)

Left sidebar → **Policy** → **App content** → **Content rating**.
Click **Start questionnaire**.

| Question | Answer |
|---|---|
| Category | **Utility** |
| Violence | No |
| Sexual content | No |
| Profanity | No |
| Controlled substances | No |
| Gambling | No |
| User-generated content or sharing | No |
| User interaction (messaging, chat) | No |
| Digital purchases | Yes (in-app purchases — note: this affects age rating for some regions, not the overall rating) |
| Location sharing | No |

Expected result: **Everyone (PEGI 3 / G)** — confirm and submit.

---

### Step 8 · App access declaration

Left sidebar → **Policy** → **App content** → **App access**.

- Select: **All or most functionality is accessible without special access**

(The app requires no login — all features are accessible without an account or credentials.)

---

### Step 9 · Ads declaration

Left sidebar → **Policy** → **App content** → **Ads**.

- **Does your app contain ads?** → **No**

---

### Step 10 · Foreground service (FGS) special-use justification

This is required because the app uses `FOREGROUND_SERVICE_SPECIAL_USE` for the live
session timer. Google requires a written justification at submission time.

When submitting the release, Google will show a form asking for the justification.
Copy-paste this exact text:

> **Use case:** An ongoing, user-initiated focus-session timer that maintains an
> accurate countdown and displays a live "return to session" notification while the
> app is in the background. The foreground service runs only for the duration of an
> active session that the user explicitly started; it stops immediately when the
> session ends or the user cancels. No location, microphone, camera, or other
> sensitive data is accessed. The service is equivalent to a stopwatch/timer app use
> case.

---

### Step 11 · Store listing

Left sidebar → **Grow** → **Store presence** → **Main store listing**.

Fill in:

**App name:** `Sustain`

**Short description (max 80 characters):**
```
A calm focus timer for deep work. Flow, Pomodoro, or custom blocks.
```

**Full description (max 4000 characters) — copy and paste:**
```
Sustain is a focus timer built around one idea: the session is sacred.

Whether you work in long, uninterrupted Flow sessions, structured Pomodoro 
cycles, or your own custom block schedule — Sustain holds the frame so your 
mind doesn't have to.

─── WHAT SUSTAIN DOES ───

• Focus modes — Flow (unbroken deep work), Pomodoro (25/5 classic), or 
  Custom (set your own work and break durations)
• A Focus Score that tracks your consistency and stamina over time, not 
  just today's session count
• Streak and average insights — weekly and all-time — so you can see the 
  discipline building
• Session sounds — optional ambient cues at the start, end, and break points
• Notifications that respect you — opt-in reminders and a live session 
  notification when you step away, so you always know where you are

─── BUILT PRIVATE BY DESIGN ───

Your focus data never leaves your device. No account required. No analytics. 
No crash reporting. No ads. Ever. Sustain has no server — we literally cannot 
see your data.

You can export or delete everything you've ever recorded, any time, from 
Settings → Your data.

─── SUSTAIN PRO ───

Pro unlocks the full experience:

• Unlimited session blocks and modes
• Full Insights — Focus Score breakdown, stamina curve, timing analysis, 
  completion patterns, and CSV export
• All premium themes (or buy them individually)
• Pro Pomodoro and Custom: continue a session with new blocks, no restart
• Near-end nudge: get prompted to add a block before your session ends

─── THEMES ───

Eight premium colour themes — Obsidian, Sage, Rosé, Indigo, Dusk, Tide, 
Noir, Mocha — each with a distinct mood. Buy Pro to unlock all of them, 
or purchase any theme individually.

─── NO NONSENSE ───

No social features. No gamification loops designed to pull you back. 
No subscription required to use the core app. Just a timer, a score, 
and the discipline you're building.

Start your first session. See where the streak goes.
```

**App icon:** Upload `play_store_512.png` from the `icon images/android_icon/` folder
(512×512 px PNG).

**Feature graphic:** A 1024×500 px graphic (the founder needs to create this — it
appears at the top of the Play Store listing). A clean, on-brand image with the
app name and a screenshot or the hourglass icon works well.

**Screenshots:** At minimum 2 phone screenshots are required. Recommended: 4–6
showing the home screen, a session in progress, the Insights page, the themes
selection, and the paywall.

**Category:** Productivity

**Tags:** focus, productivity, timer, pomodoro, deep work (Play lets you add a few
relevant tags)

**Email:** `trilumos.app@gmail.com`

**Privacy policy URL:** the URL where you hosted `docs/legal/privacy-policy.md`
(fill this in before submitting — required)

---

### Step 12 · Target audience

Left sidebar → **Policy** → **App content** → **Target audience and content**.

- **Target age group:** 18 and over (or "All ages" — both are correct; 18+ is safer
  for an app with paid IAP)
- **Does your app appeal primarily to children?** → No

---

### Step 13 · Google Play app signing (recommended)

Left sidebar → **Release** → **Setup** → **App signing**.

- Enrol in **Play App Signing** if not already done (recommended — Google holds the
  distribution key; your upload key only signs uploads, so you can reset it if lost)
- This is usually prompted automatically when you upload the first .aab

---

## Part 2 — RevenueCat

### Step 1 · Create a RevenueCat account

1. Go to [app.revenuecat.com](https://app.revenuecat.com) and sign up (the founder's
   email is fine).
2. Create a new **Project** — name it `Sustain`.

---

### Step 2 · Add the Android app

1. Inside the Sustain project, click **Add app** → **Google Play Store**.
2. **Package name:** `com.trilumos.sustain`
3. **App name:** `Sustain`

---

### Step 3 · Connect RevenueCat to Google Play (service account)

RevenueCat needs read access to your Play Console to verify purchases.

1. In RevenueCat, there will be a prompt to connect a **Google service account**.
   Click the link/button — it opens a RevenueCat help article with exact steps.
2. The short version:
   a. Go to [console.cloud.google.com](https://console.cloud.google.com)
   b. Select or create a project tied to your Play account
   c. Enable the **Google Play Android Developer API**
   d. Create a **Service account** (IAM & Admin → Service accounts → Create)
   e. Grant it the role **Service Account User** (basic)
   f. Download the JSON key file
   g. In **Play Console** → Setup → API access → Link the service account and grant
      it **Financial data + Orders + Cancellations** permissions
   h. Paste the JSON key content into RevenueCat

> **RevenueCat's own docs for this step are the most reliable source** — search
> "RevenueCat Google Play credentials" in their docs. The UI changes occasionally.

---

### Step 4 · Create entitlements in RevenueCat

Left sidebar in RevenueCat → **Entitlements** → **New entitlement**.

Create all 10 entitlements below. The **Identifier** must match exactly (these are
what the app checks in code):

| Identifier | Display name |
|---|---|
| `pro` | Sustain Pro |
| `theme_obsidian` | Obsidian Theme |
| `theme_sage` | Sage Theme |
| `theme_rose` | Rosé Theme |
| `theme_indigo` | Indigo Theme |
| `theme_dusk` | Dusk Theme |
| `theme_tide` | Tide Theme |
| `theme_noir` | Noir Theme |
| `theme_mocha` | Mocha Theme |
| `theme_aurora` | Aurora Theme |

> **Note the underscore:** entitlement IDs are `theme_obsidian` (underscore).
> Play Console product IDs are `theme.obsidian` (dot). Both are correct and
> intentional — they are different systems.

---

### Step 5 · Add products to RevenueCat

Left sidebar → **Products** → **New product**.

Add each Play Console product to RevenueCat. For each:
- Click **New product**
- **Store:** Google Play
- **Product identifier:** copy from the table below (must match Play Console exactly)
- **Type:** as specified

| Product identifier | Type |
|---|---|
| `pro.monthly` | Subscription |
| `pro.yearly` | Subscription |
| `pro.lifetime` | Non-subscription (one-time) |
| `theme.obsidian` | Non-subscription |
| `theme.sage` | Non-subscription |
| `theme.rose` | Non-subscription |
| `theme.indigo` | Non-subscription |
| `theme.dusk` | Non-subscription |
| `theme.tide` | Non-subscription |
| `theme.noir` | Non-subscription |
| `theme.mocha` | Non-subscription |
| `theme.aurora` | Non-subscription |

---

### Step 6 · Attach products to entitlements

Go back to each entitlement and attach the right products:

| Entitlement | Attach these products |
|---|---|
| `pro` | `pro.monthly`, `pro.yearly`, `pro.lifetime` |
| `theme_obsidian` | `theme.obsidian` |
| `theme_sage` | `theme.sage` |
| `theme_rose` | `theme.rose` |
| `theme_indigo` | `theme.indigo` |
| `theme_dusk` | `theme.dusk` |
| `theme_tide` | `theme.tide` |
| `theme_noir` | `theme.noir` |
| `theme_mocha` | `theme.mocha` |
| `theme_aurora` | `theme.aurora` |

For each entitlement: open it → **Attach** → select the matching product(s) → Save.

---

### Step 7 · Create the Offering

Left sidebar → **Offerings** → **New offering**.

- **Identifier:** `default` *(the app reads `offerings.current`, which RevenueCat
  resolves to the default offering)*
- **Description:** `Pro paywall — monthly, annual, lifetime`
- Make it the **current offering** (the default one shown to users)

Inside this offering, add 3 packages:

| Package identifier | Package type | Product to attach |
|---|---|---|
| `$rc_monthly` | Monthly | `pro.monthly` |
| `$rc_annual` | Annual | `pro.yearly` |
| `$rc_lifetime` | Lifetime | `pro.lifetime` |

For each package: click **Add package** → select type → attach product → Save.

> **The identifiers `$rc_monthly`, `$rc_annual`, `$rc_lifetime` are RevenueCat's
> reserved identifiers** for the standard package types. Select them from the
> dropdown — don't type them manually.

---

### Step 8 · Get the Android API key

1. In RevenueCat, go to **Project Settings** (gear icon, top right of the project)
   → **API keys**.
2. Copy the **Public SDK key** for Google Play — it looks like `goog_xxxxxxxxxxxxxxxx`.
3. **Give this key to the developer (Claude Code / your AI coding assistant).**
   They will paste it into one line in the app code (`kRevenueCatAndroidKey` in
   `lib/billing/billing_config.dart`) and rebuild.

> This is the only code change needed to enable live billing. Everything else is
> already wired up.

---

## Part 3 — After the key is set: test before publishing

Once the developer has updated the code and built a new signed .aab:

### Sandbox testing on Android

1. In Play Console → Setup → **License testing**, add the tester Gmail account as a
   **license tester**. License testers can make sandbox purchases that go through
   the full billing flow without real charges.
2. Install the new signed .aab on the test device (via internal testing track or
   direct install with `adb`).
3. Test:
   - [ ] Tap a Pro plan → purchase completes → Pro features unlock
   - [ ] Tap a theme → à la carte purchase completes → theme unlocks
   - [ ] Go to paywall → tap **Restore** → previous purchases restore (on same account)
   - [ ] Close app mid-session → session notification stays → tap it → return to session
   - [ ] Notifications fire (opt-in reminders, grace alerts)
   - [ ] Settings → Your data → Backup → Restore → data intact after restore

---

## Part 4 — Final submission checklist

Before clicking "Submit for review":

- [ ] Privacy policy hosted at a public URL (fill effective date + `trilumos.app@gmail.com` in the doc first)
- [ ] Privacy policy URL entered in Play Console (App content → Privacy policy)
- [ ] ToS hosted at a public URL (optional but good to have in Settings)
- [ ] Data Safety form complete and submitted (Part 1, Step 6)
- [ ] Content rating complete (Part 1, Step 7)
- [ ] Store listing complete with icon, feature graphic, screenshots, description (Part 1, Step 11)
- [ ] RevenueCat connected + products + entitlements + offering created (Part 2)
- [ ] API key set in code + new .aab built and signed
- [ ] New .aab uploaded (replace the internal-testing one, or create a production release)
- [ ] FGS justification text ready (Part 1, Step 10) — needed when submitting production release
- [ ] Sandbox purchase test passed on device

### Submit to production

1. Left sidebar → **Release** → **Production** → **Create new release**
2. Upload the final signed .aab
3. Fill in release notes (what's new in 1.0.0)
4. When prompted, paste the FGS justification text (Step 10)
5. **Staged rollout** recommended: start at 10% → monitor crash rate for 48h → expand
6. Review typically takes 3–7 days for a new app

---

## Pro benefits — exact feature list

### What every Pro plan includes (monthly, yearly, and lifetime are identical features)

All three plan types unlock the same complete set of features. The only difference
between them is the billing model. Use this list when writing product descriptions
in Play Console or RevenueCat, or when answering any question about what Pro does.

---

#### Free tier (what users get without Pro)

| Feature | Free |
|---|---|
| Session modes | Flow, Pomodoro, Custom — all three available |
| Manual pauses per session | **3 maximum** |
| Pause duration cap | **3 minutes** per pause |
| Session continuation (add blocks) | Not available — session ends when time is up |
| Insights — basic (today, streak, averages) | ✅ Available |
| Insights — deep analytics | ❌ Locked (Focus Score breakdown, stamina, timing, completion, personal bests) |
| PDF focus report export | ❌ Locked |
| CSV data export | ❌ Locked |
| Premium color themes | ❌ Locked (Sand theme only, free) |
| Near-end nudge (add a block before session ends) | ❌ Locked |

---

#### Pro tier — everything unlocked

**1 · Deep insights**
> Your Focus Score and Stamina traced over time, your best hours, and your
> follow-through. Six analytics sections: score breakdown, stamina curve, timing
> analysis, completion patterns, personal bests, and milestones.

**2 · Personal bests + PDF report**
> Records and milestones across your entire focus history, plus a detailed,
> multi-section PDF Focus Report you can export, save, and share.

**3 · Unlimited, longer pauses**
> Step away mid-session for up to **10 minutes** per pause (vs 3 min free),
> as many times as you need, without losing your block.
> Free users get 3 pauses max at 3 minutes each.

**4 · Keep any session going**
> Add more blocks to a Pomodoro or Custom session on the fly, right as it ends,
> without restarting from scratch. Also includes a near-end nudge — a prompt
> to add a block before the current one expires.

**5 · Every color theme**
> All premium themes — Obsidian, Sage, Rosé, Indigo, Dusk, Tide, Noir, Mocha,
> Aurora — unlocked instantly, plus any new themes added in future updates.
> (Each theme is also available individually à la carte.)

**6 · Everything new, automatically**
> Every Pro feature released in future updates is included in the plan
> at no additional cost.

---

#### Plan billing comparison

| Plan | Price | Billing | Cancellation | Notes |
|---|---|---|---|---|
| **Monthly** | $4.99/mo | Charged monthly, auto-renews | Cancel anytime in Google Play | Entry point — try before committing |
| **Yearly** | $29.99/yr | Charged once a year, auto-renews | Cancel anytime in Google Play | **Best value** — shown with savings badge vs monthly |
| **Lifetime** | $59.99 | One-time payment, no subscription | N/A — own it forever | **Hero offer** — own every theme and all Pro, forever |

---

### Theme catalog — descriptions

These are the exact in-app descriptions used in the Themes screen.
Use them for Play Console product descriptions, store listings, or any marketing copy.

| Theme ID | Display name | In-app description | Price | Mood / accent colour |
|---|---|---|---|---|
| `sand` | Sand | The default. Warm and grounded. | **FREE** | Warm golden sand tones |
| `obsidian` | Obsidian | Cool blue-black. Nocturnal and premium. | $1.99 | Deep blue-black with electric blue accent |
| `sage` | Sage | Quiet pine and forest green. | $1.99 | Dark forest green with bright sage accent |
| `rose` | Rosé | Soft, elegant warm rose. | $1.99 | Deep burgundy-rose with blush pink accent |
| `indigo` | Indigo | Deep sapphire jewel tones. | $1.99 | Midnight indigo with violet-blue accent |
| `dusk` | Dusk | Gentle lavender at twilight. | $1.99 | Soft purple-dark with orchid accent |
| `tide` | Tide | Deep luxe teal, like the ocean. | $1.99 | Near-black teal with cyan-teal accent |
| `noir` | Noir | True black and warm gold. | $1.99 | Almost pure black with molten gold accent |
| `mocha` | Mocha | Dark espresso and caramel. | $1.99 | Deep espresso brown with warm amber accent |
| `aurora` | Aurora | Deep cosmos lit by shifting aurora light. | **$3.99** | Cosmic dark with teal aurora accent + full spectrum shimmer on home screen |

**Aurora** is the flagship theme — it has a living aurora-spectrum shimmer on the
home screen sand (cycles through green, cyan, violet, magenta, mint). Position it
as the premium of the premiums.

---

### Copy for Play Console product descriptions

Use these when creating each product in Play Console (the "Description" field):

**`pro.lifetime`**
> Unlock everything in Sustain Pro with a single, one-time payment — no subscription,
> no renewal. Includes deep Insights analytics, unlimited pauses, session continuation,
> personal bests, PDF focus report export, CSV export, all premium themes, and every
> Pro feature added in future updates.

**`pro.yearly`**
> Full Sustain Pro access billed once a year. Includes deep Insights analytics,
> unlimited pauses, session continuation, personal bests, PDF focus report, CSV export,
> all premium themes, and every Pro feature added in future updates. Cancel anytime
> in Google Play.

**`pro.monthly`**
> Full Sustain Pro access billed monthly. Includes deep Insights analytics, unlimited
> pauses, session continuation, personal bests, PDF focus report, CSV export, all
> premium themes, and every Pro feature added in future updates. Cancel anytime
> in Google Play.

**`theme.obsidian`**
> The Obsidian theme for Sustain — cool blue-black with an electric blue accent.
> Nocturnal, premium, and focused. Unlocks this theme permanently.

**`theme.sage`**
> The Sage theme for Sustain — quiet pine and forest green tones with a bright sage
> accent. Calm and grounded. Unlocks this theme permanently.

**`theme.rose`**
> The Rosé theme for Sustain — soft, elegant warm rose tones with a blush pink accent.
> Warm and refined. Unlocks this theme permanently.

**`theme.indigo`**
> The Indigo theme for Sustain — deep sapphire jewel tones with a violet-blue accent.
> Rich and focused. Unlocks this theme permanently.

**`theme.dusk`**
> The Dusk theme for Sustain — gentle lavender at twilight with a soft orchid accent.
> Quiet and dreamlike. Unlocks this theme permanently.

**`theme.tide`**
> The Tide theme for Sustain — deep luxe teal tones with a cyan accent, like the
> ocean floor. Deep and immersive. Unlocks this theme permanently.

**`theme.noir`**
> The Noir theme for Sustain — true black with a warm molten gold accent.
> Maximum contrast, cinematic. Unlocks this theme permanently.

**`theme.mocha`**
> The Mocha theme for Sustain — dark espresso browns with a warm caramel amber accent.
> Rich and cosy. Unlocks this theme permanently.

**`theme.aurora`**
> The Aurora theme for Sustain — a deep cosmic dark with a luminous aurora teal accent
> and a full aurora-spectrum shimmer on the home screen. The flagship premium theme.
> Unlocks this theme permanently.

---

## Quick reference — exact IDs the app expects

These must never change without a code update:

```
RevenueCat entitlements (underscore):
  pro
  theme_obsidian, theme_sage, theme_rose, theme_indigo, theme_dusk
  theme_tide, theme_noir, theme_mocha, theme_aurora

Play Console / RevenueCat product IDs (dot for themes):
  pro.monthly       → subscription
  pro.yearly        → subscription
  pro.lifetime      → one-time
  theme.obsidian    → one-time
  theme.sage        → one-time
  theme.rose        → one-time
  theme.indigo      → one-time
  theme.dusk        → one-time
  theme.tide        → one-time
  theme.noir        → one-time
  theme.mocha       → one-time
  theme.aurora      → one-time

RevenueCat offering: default
RevenueCat packages: $rc_monthly, $rc_annual, $rc_lifetime

Package name: com.trilumos.sustain
```
