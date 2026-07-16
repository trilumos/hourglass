# Sustain Web — Design Spec

> **Status:** 🟡 Design locked (founder-approved via brainstorm 2026-07-11), not yet built.
> **Handoff (2026-07-17):** the Android APP launched on Product Hunt with a good response — the
> hourglass visual was the standout comment (validates the mascot thesis in §2; a separate PH launch
> for THIS website is planned post-build — PH's web-first audience suits it far better). Domain not
> yet purchased (`sustaintimer.com` $11/yr recommended, `sustain.zone` alt; all clean `sustain.*` are
> taken). **Next:** founder wants one more brainstorm pass on this design, then writing-plans → build.
> **What this is:** the canonical design for **sustain the *website*** — a separate product from the
> Android app, built as a marketing funnel, a feature playground, and a second revenue stream.
> **Relationship to the app:** two **completely separate ecosystems** (own accounts, own billing, own
> Firebase project, **no data sync between them, ever**). See [`../../project-context.md`](../../project-context.md)
> and [`../../feature-roadmap.md`](../../feature-roadmap.md) for the app itself.

---

## 1. Why build this

The Android app is published. This site exists to **funnel attention → installs** and to earn a
**second, independent revenue stream** — while doubling as a low-risk **lab** for features we may later
graduate into the app (v1.2/v2).

Three findings from competitor research (2026-07-11) shaped the whole design:

1. **The app's differentiator IS the web timer's wedge.** The two loudest complaints about every online
   timer are *"the big countdown is distracting"* and *"Pomodoro forces a break right when I hit flow."*
   Sustain was built to solve exactly those — a calm falling hourglass instead of a screaming number, and
   a Flow/endless mode that never forces a break. So Sustain-web isn't "another pomodoro site"; it's
   **"the calm one that doesn't yank you out of flow," backed by a real method.**
2. **There's an orphaned audience.** [lofi.co](https://lofi.co) — the aesthetic-ambient-timer product this
   is modelled on — **shut down (May 2024).** People still search "lofi.co alternative." Claimable SEO.
3. **What people actually pay for** (Flocus $99 lifetime, Pomofocus $54, lofi.co subs): **aesthetic
   customization** — extra scenes, custom/video backgrounds, sound mixing, personal music — **not "a
   better timer."** That's the lane Sustain is strong in, and it defines the paywall (§6).

**Honest caveat (kept front-of-mind):** monetizing an aesthetic web timer is *hard* — lofi.co died trying.
So the rule is: **the free tier carries the marketing** (it must feel complete and premium — it's the best
ad), and **paid is a bonus stream, not the plan.**

## 2. Positioning

> **Sustain — the calm focus timer that doesn't pull you out of flow.**
> A beautiful falling hourglass, three focus modes, ambient scenes and soundscapes. Free to use, nothing
> to install. Train your focus like an athlete.

The **hourglass is the mascot** (the Lofi-Girl lesson: a consistent, recognizable *character* + *feeling*
builds the brand). Every touchpoint — the site, the fullscreen stage, the YouTube channel — features the
same unmistakable falling sand.

## 3. Architecture principle: two separate ecosystems

| | 🌐 Web (this spec) | 📱 App (shipped) |
|---|---|---|
| Stack | Custom web (SEO-first) + Firebase | Flutter/Dart, offline-first |
| Accounts | Own Firebase project, own users | None yet (own Firebase planned for app v2) |
| Billing | Merchant-of-Record (web) | RevenueCat + Play Billing |
| Data sync between them | **Never** | **Never** |

**Why separate:** unifying would force account-linking across Play + web and touch the live, rated app —
and once the app grows cloud sync, keeping "same-and-different users" consistent across web+mobile is a
genuine distributed-systems headache for a solo founder. Separation deletes that entire class of problem.
The app stays **100% untouched**; web is a clean-room product. They share only **the brand + cross-promo
CTAs**.

**Web = funnel + feature lab.** It deploys instantly (no Play review, no risk to the live app), so we ship
experiments here, see what sticks, and graduate winners into the app. (Notably: the app doesn't even have
background soundscapes yet — the web will ship them first.)

## 4. What the web is (and deliberately is NOT)

The web is the **front door** (instant, beautiful, shareable). The app is the **home** (progress that
compounds). The web deliberately **lacks the progress system** — that absence *is* the reason to install.

| Capability | 🌐 Web | 📱 App |
|---|---|---|
| Hourglass, 3 modes, endless/open | ✅ | ✅ |
| Themes, soundscapes | ✅ | ✅ (app: v1.2) |
| Ambient scenes, circadian, PiP, share links, embed, `/stage`, hourglass customization | ✅ web-only | — |
| **Focus Score, Stamina, Insights, streaks, session history** | ❌ *(the install hook)* | ✅ |
| Notifications, protect-the-block, strict-session anti-abuse | ❌ | ✅ |
| Focus/session/behavioural data stored on a server | ❌ **never** | on-device only |

**One-line story:** *Web gives you the calm and the vibe for free; the app is where your focus actually
grows and gets tracked.*

## 5. Feature set (full — shipping complete)

### 5.1 Core timer
- **Three modes, all free:** Flow, Pomodoro, Custom — plus an **Endless / Open** mode (break whenever you
  want; directly answers the "Pomodoro forces breaks" complaint).
- **The hourglass**, the soul of the product:
  - **2.5D canvas** version (faithful port of the app's beloved painter — wave physics + fine grain spray)
    is the foundation and the default.
  - **True 3D (WebGL)** version as a **user-selectable** alternative (glassy refraction, 3D sand). *Biggest
    single build item; must stay calm/premium, never gimmicky.*
  - **User chooses 2D or 3D.**
- **The signature session view — `[min] · 🏺 · [secs]`:** the hourglass is the divider between minutes
  (left) and seconds (right); the numbers are **hidden by default and fade in calmly on hover / mouse-move.**
  This deletes the "distracting countdown" problem by design and is gorgeous on a stream. It is also the
  `/stage` fullscreen view.
- **Timer-visibility setting (user choice):** *always show* · *flash every N minutes* · *hidden, show on
  hover* (the fade view above).
- **Themes:** Sand + the premium moods (Obsidian, Sage, Rosé, Indigo, Dusk, Tide, Noir, Mocha, Aurora) —
  ported palettes.
- **Soundscapes + mixer:** ambient loops incl. the signature sand sound, with a layerable mixer (sand +
  rain + café, volume sliders). *Requires sourcing royalty-free/CC0 audio — a real work item (see §11).*

### 5.2 Ambient & aesthetic (the "make it yours" identity)
- **Ambient scenes:** swappable backdrops behind the hourglass — rain-on-window, café, fireplace, night sky.
- **Circadian / "god-mode" ambiance (FREE):** scene + theme drift with the user's real local clock —
  soft warm morning, bright afternoon, golden evening, and a genuinely **dim, low-blue, eye-easy night**.
  Deeply on-brand; kept **free** because it's a "whoa" that markets the site.
- **Hourglass customization:** shape, sand colour, glass design, particle density, and the 2D/3D toggle.
- **Custom background upload:** the user's own image behind the hourglass (a proven top paid driver).

### 5.3 Web-only power features
- **Floating PiP timer** (Document Picture-in-Picture): the live hourglass pops into a small always-on-top
  window that stays visible while the user works in other apps. Web-native; the app can't easily match it.
- **Shareable preset links:** a URL encodes mode + duration + theme + scene, e.g.
  `sustaintimer.com/?flow=50&theme=sage&scene=rain`. **Never paywalled** — every share is free marketing.
- **Embeddable widget:** an iframe others drop into Notion / blogs / study sites (a backlink surface).
- **`/stage` fullscreen:** clean, chrome-less full-screen focus view (the fade session view). Powers both
  aesthetic full-screen focus **and** OBS Browser-Source streaming (see §10).
- **Task "Focus Plan"** (FlowStack-style): add 4–5 tasks, give each a block + breaks between, flow through
  them one at a time behind the hourglass, end on a summary ("7 tasks · 170 min"). Basic checklist is free;
  saved/reorderable multi-block plans are a paid perk.
- **Local "focused today" counter** (localStorage, no account) — a light taste of progress; the *full*
  progress system stays app-only.
- **App-install CTA** — tasteful, present on every surface, never naggy.

## 6. Monetization

### 6.1 Free vs paid
**Free forever (the funnel — must feel premium on its own):** 3 modes + endless · the hourglass + fade
session view + timer-visibility modes · **circadian ambiance** · Sand + a few themes · a few ambient scenes
· a few soundscapes + basic 2-layer mixing · **floating PiP** · **shareable links** · **embeddable widget**
· `/stage` fullscreen · basic checklist · local "focused today" · optional account to **save preferences** ·
app CTA.

**Paid — "Sustain Web Plus" (make it deeply yours):** all themes · all ambient scenes (incl. animated) ·
**custom background upload** · **full soundscape mixer** (unlimited layers + premium sounds) · **deep
hourglass customization + true-3D** · **saved multi-task Focus Plans**. Stays **ad-free** either way.

### 6.2 Pricing (global USD)
| Tier | Price |
|---|---|
| Monthly | **$3.99** |
| Yearly | **$23.99** |
| **Lifetime** (hero) | **$49.99** |

- Positioned to **undercut Flocus ($99 lifetime)** and sit friendly beside Pomofocus ($54).
- **Lifetime includes every future cosmetic addition, free** (new themes, scenes, and true-3D as it evolves)
  — so a buyer is **never left behind. No disparity, by design.**
- India ₹ PPP overrides can mirror the app's strategy **later** — not worth building region pricing before
  there's meaningful traffic. One global USD price at launch.
- **Deferred (affordability-gated, NOT a committed feature):** live-streaming a session to the user's own
  YouTube. It carries per-use server cost, so it ships only if/when the economics work — and if it ever
  does, it's a **separate add-on for everyone** (even lifetime holders), disclosed plainly so no one feels
  misled.

### 6.3 Payments
A **Merchant-of-Record** (Lemon Squeezy / Paddle / Polar — final pick at billing-build time) rather than raw
Stripe, so **worldwide sales-tax/VAT compliance is handled for us** (critical for a solo founder; also
sidesteps Stripe-India business-registration + RBI e-mandate friction). The MoR webhooks a **Firebase
Function** that flips a single entitlement flag in Firestore.

### 6.4 Cross-promo (neutralize the only downside of separation)
The sole cost of separate billing is a superfan who owns the app *and* buys web feeling double-charged.
Handle it with **occasional cross-promo discount codes** (app → web, web → app) for existing customers —
goodwill, zero shared infrastructure.

## 7. Account model

**Auth is coupled to money and preferences, never to free *use*.** Three tiers:

| Tier | Sign in? | We store (server) | Gets |
|---|---|---|---|
| **Free, anonymous** | no | **nothing** (prefs in browser localStorage) | the full free timer, instant |
| **Free, signed in** | *optional* | email + a tiny **preferences** doc | their setup follows them across devices |
| **Paid, signed in** | yes (to buy) | email + prefs + **entitlement** + uploads | all Plus features, everywhere |

**Mechanics:** Firebase **Auth** (Google one-tap primary; identity is managed, we write no DB code for it),
a tiny **Firestore** doc per signed-in user (preferences + entitlement), Firebase **Storage** for custom
uploads.

**Guardrails (locked):**
- **Login is always optional** — the free timer *never* requires it (protects the funnel + SEO).
- Sign-in surfaces only at **"Save preferences," "Unlock/Buy," and "Restore."** No standalone nag.
- **The web never stores focus/session/progress data** — that stays exclusively the app's job.
- **Honest privacy line:** *"Use it free, no account, nothing stored. Sign in (optional) and we save your
  email + preferences — never your focus data."* Account deletion offered (GDPR-trivial).

## 8. Tech stack (proposed)

- **Frontend:** a lightweight, **SEO-first** framework (Astro / Next / SvelteKit — final pick at build
  time). **Public pages (landing, timer, `/stage`) are static/SSR** so Google can read them and they load
  instantly; the authenticated account/purchase UI is client-rendered behind login. **Explicitly NOT
  Flutter-web** (multi-MB payload, invisible to Google, non-native feel — fatal for a funnel).
- **Hourglass:** HTML5 **Canvas 2D** for the 2.5D version (port of `lib/hourglass/hourglass_painter.dart`
  logic); **WebGL / Three.js** for true-3D.
- **Audio:** Web Audio API (loops + mixer).
- **PiP:** Document Picture-in-Picture API (Chrome/Edge; graceful fallback elsewhere).
- **Backend:** Firebase (Auth + Firestore + Storage) — a **separate project** from the app. Hosting on
  Firebase Hosting / Vercel / Cloudflare Pages (free tier).
- **Payments:** Merchant-of-Record + a Firebase Function webhook.

## 9. SEO

- Real server-rendered HTML (the reason we avoid Flutter-web); fast Core Web Vitals; mobile-first.
- **Free timer usable with no login** — both a funnel and an SEO requirement.
- Target terms: *"online timer," "pomodoro timer," "focus timer," "aesthetic study timer," "hourglass
  timer,"* and the orphan **"lofi.co alternative."**
- Technical: `<title>`/meta/**OpenGraph** (rich link previews when shared), `sitemap.xml`, `robots.txt`,
  **Google Search Console** (verify via DNS, submit sitemap).
- **Backlink flywheel** (what most timer sites lack): shareable preset links + the embeddable widget +
  YouTube video descriptions all point back.

## 10. Content / YouTube strategy (context, not a build item)

- The `/stage` fullscreen page is pointed at by **OBS *Browser Source*** (NOT Window/Display Capture) — this
  fixes the founder's freeze/black-screen glitch at the root: Window Capture screen-scrapes a *throttled*
  background tab; a Browser Source renders the page *inside OBS*, immune to focus/throttling.
- **OBS → YouTube Live directly**; the livestream **auto-archives as a VOD** — no "record then upload" step.
- Quality: ~6000 Kbps @ 1080p, NVENC encoder if available.
- The stream is a **live demo of the exact hourglass** one click from the site — every viewer is a
  potential install. (We do *not* build in-app/in-web streaming; OBS + YouTube Live cover the founder's own
  channel for free.)

## 11. Scope, risks & founder actions

**Long poles (the reason this is ~a month, not "a week or two"):**
1. **True-3D WebGL hourglass** — a project on its own; the 2.5D canvas is far faster and already beautiful.
2. **Audio sourcing** — royalty-free/CC0 soundscape loops (esp. the signature "sand" sound). The *app*
   deferred soundscapes for exactly this reason; on web they're core and can't be skipped. Sourcing +
   licensing + a `CREDITS` file is real work, not just code.
3. **Firebase accounts + MoR payments + entitlements + upload storage** — done carefully (money + privacy).
4. **Faithful canvas port** of the complex hourglass painter.

**Everything else** (modes, themes, scenes, circadian, fade view, PiP, share links, embed, SEO) is
individually modest but adds up.

**Founder actions (outside the build):**
- Buy the domain — **`sustaintimer.com`** ($11/yr, best for the funnel: trusted `.com`, memorable in a
  video, "timer" aids ranking) or **`sustain.zone`** ($15/yr, more brandable). *All clean `sustain.*`
  domains (`.app/.co/.so`) are taken.*
- Create the **separate web Firebase project** + Google OAuth.
- Pick the **Merchant-of-Record**.
- Decide the **audio source** (library/commission) for soundscapes.

**Standing risks to hold:** monetizing aesthetic timers is hard (free tier must carry the marketing);
true-3D perf on low-end devices; keep the calm/no-gimmick brand (no bounce/sparkle/gradient-text per the
brand doc); the free timer must never require login.

## 12. Open decisions (deliberately deferred, not blockers)
- Final frontend framework, MoR provider, and audio source — pin at build/plan time.
- India ₹ pricing — mirror the app's PPP strategy once there's traffic.
- YouTube-streaming-for-users — revisit only if affordable.

---

*Next step: turn this into a phased implementation plan (writing-plans), which will give the honest
task-count and week-count.*
