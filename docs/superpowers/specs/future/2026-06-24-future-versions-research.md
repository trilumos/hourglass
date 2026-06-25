# Sustain — Future-Versions Research & Feature Spec (Brainstorming Input)

**Created:** 2026-06-24 · **Status:** research + options, NOT decisions. This is the brief for a future brainstorming session. Nothing here is committed.
**Scope:** (1) the coins/currency + rewarded-ads economy you proposed, and (2) a competitor study (Regain + the top focus / study / timer apps) to mine features that would make Sustain better in later versions.

---

## 0. Read this first — the brand tension (must resolve before anything else)

Sustain's identity is **locked** around promises that the proposed economy directly contradicts:

- The in-app FAQ literally says: **"Are there ads? No. Sustain has no ads, and it will not send guilt-trip or 'come back' notifications."**
- Sustain 101 and the privacy copy promise **fully offline, zero analytics, no accounts, "your data is yours."**
- The brand is "train your focus like an athlete" — calm, honest, no dark patterns, "no manufactured guilt."

**Ads + a coin economy are the single biggest strategic decision here**, because:

1. **Ads break a written promise.** Shipping ads after we shipped "No ads" reads as a bait-and-switch and will draw 1-star reviews quoting our own FAQ. If we add ads, it likely needs to be a **major version (2.0) with explicit, upfront framing** — never a silent 1.x addition.
2. **Most ad SDKs (AdMob etc.) collect data and need network** — which breaks "fully offline, zero analytics" and complicates the Play Data Safety form we already submitted. A rewarded-ad SDK is an analytics/identifier vector.
3. **A focus app that shows ads is tonally self-contradictory** — we ask users to escape attention-harvesting apps, then show them attention-harvesting ads. Forest, Opal, and most premium focus apps deliberately **don't** run ads for exactly this reason; the ad-supported ones (lower-tier timers) are the ones we want to beat, not imitate.

**Recommended stance for the brainstorm:** keep the **coin/gamification layer** (it's on-brand — it rewards focus, like Forest's leaf coins) but **decouple it from ads**. Coins are earned by focusing; spending them on themes/Pro is a *loyalty* mechanic, not an ad funnel. If ads are still wanted, gate them behind a single, **opt-in, rewarded-only** surface introduced in a clearly-marked 2.0, never interstitials, never forced. Decision options are enumerated in §3.4. **This question should be answered before designing the economy.**

---

## 1. Competitor study

### 1.1 Regain (`ai.regainapp`, "Study Timer for Focus", Android) — the app to beat
Feature inventory (from store listings + reviews):
- **Focus timer** in three modes: Timer, Stopwatch, **Pomodoro** with breaks.
- **Screen-time tracking & reports**: productive vs distracted time, daily/weekly stats, focus insights, **tag distribution** (focus by category/tag).
- **App blocking / distraction control**: app limits, **block addictive features specifically** — Instagram Reels, YouTube Shorts, Snapchat Spotlight, Facebook Reels; "strict blocking"; scheduled auto-blocks (work hours, bedtime).
- **YouTube Study Mode**: block irrelevant channels/videos so learning isn't derailed.
- **Calming / science-backed music** + premium themes.
- **Gamified mascot "Rega"** (a screen-time buddy) + streaks for consistency.
- **Focus schedules** in a weekly calendar (repeating).
- **Social / multiplayer**: live **focus rooms** to study with friends/strangers, **global leaderboards**.

**What Sustain already does better:** the focus *method* (struggle→flow→recover, Focus Score, Focus Stamina), honest anti-cheat mechanics, calm design, privacy (offline). **Where Regain is ahead:** app/distraction blocking, screen-time analytics, social/leaderboards, tagging, music. These are the gaps to consider closing.

### 1.2 Forest (`cc.forestapp`) — the gold standard for on-brand gamification
- **Coins per session, length-scaled** (e.g. 10 min ≈ 3 coins, 30 min ≈ 10). Spend coins to **unlock new tree/plant species** (cost escalates ~+100 each unlock).
- **Real-world payoff**: pool coins to fund a real planted tree (~2,500 coins) via a partner — a meaningful, non-pay-to-win sink.
- **Daily missions**, monthly arcs/streaks, a large cosmetic collection, **global leaderboards**, shareable achievements.
- Lesson: gamification works best when the reward is **cosmetic/meaningful, not power**, and earning is tied directly to focus time.

### 1.3 Flora — accountability via stakes
- "Money-on-the-line": users can **stake real money** that they lose if they fail a session. A harder-core accountability mechanic; off-brand for Sustain's gentle ethos but worth noting as a contrast.

### 1.4 Opal — premium screen-time control
- **Session Difficulty** tiers: *Normal* (snooze/cancel anytime), *Timeout* (escalating delays before you can snooze again), *Deep Focus* (no snooze, no early end). This maps beautifully onto Sustain's existing "Staying Honest" philosophy — a **difficulty/strictness setting** for sessions.
- Scheduled blocks, app limits, analytics, leaderboards, rewards. Priced premium ($99.99/yr) — validates a higher willingness-to-pay in this niche.

### 1.5 Cross-cutting patterns in the niche
- **Gamified focus = retention.** Coins, streaks, collections, missions all recur across the category and research links them to engagement.
- **Distraction blocking** is the table-stakes feature Sustain lacks.
- **Social/leaderboards** drive consistency but **conflict with Sustain's offline/no-account stance** — would require accounts/cloud (a major architectural shift).
- **Ambient sound/music** is near-universal and cheap to add on-brand.

---

## 2. Feature backlog (candidates, grouped) 

Each tagged: **[fit]** on-brand · **[tension]** needs a brand decision · **[arch]** needs accounts/cloud/network.

### A. Gamification & rewards (mostly on-brand)
- **Focus coins** earned from each completed session, **scaled to session score / focus minutes** (your idea). **[fit]**
- **Coin sinks:** buy individual **themes**, accumulate toward **Pro time** (e.g. a month of Pro for N coins), small cosmetics (hourglass skins, avatar frames). **[fit/tension]** — "buy Pro with coins" cannibalizes revenue; needs careful pricing (see §3).
- **Collections / cosmetic hourglass skins** beyond color themes (sand textures, particle effects) as coin sinks. **[fit]**
- **Daily/weekly missions** ("focus 25 min", "finish a Flow block") granting coins. **[fit]** — but keep gentle, never guilt-inducing.
- **Milestone/achievement medals** (already have personal bests; formalize as a collectible wall). **[fit]**
- **Real-world payoff** (Forest-style): donate pooled coins to a focus/education charity. **[fit]** — strong brand story, needs a partner + network.

### B. Distraction blocking (Regain's core; biggest competitive gap)
- **App blocker during sessions** (Android `UsageStatsManager` + an accessibility/overlay or `AppBlocker` approach). **[arch]** — heavy: needs sensitive permissions (Usage Access, possibly Accessibility), which complicate Play review + Data Safety. High value, high effort/risk.
- **Block short-form specifically** (Reels/Shorts/Spotlight) — Regain's headline feature. **[arch]**
- **Scheduled focus blocks** (calendar of recurring auto-start/auto-block windows). **[fit/arch]**
- **"Strict mode" session difficulty** (Opal-style: Normal / Timeout / Deep Focus) — extends our existing pause/leave rules into a user-chosen strictness. **[fit]** — low-arch, high-fit; strong early candidate.

### C. Analytics & insight depth (extend existing Pro Insights)
- **Tags / categories per session** (study, work, read) → focus-by-tag breakdowns (Regain has this). **[fit]**
- **Screen-time correlation** (optional): show focus vs distraction. **[arch]** (needs Usage Access).
- **Goals** (daily/weekly focus targets) with gentle progress. **[fit]**

### D. Audio / ambience (cheap, on-brand, universal)
- **Ambient focus sounds / soundscapes** during sessions (rain, café, brown noise), as a free or Pro pack. **[fit]** — pairs with existing sound-cue system.

### E. Social / accountability (highest arch cost; brand tension)
- **Focus rooms / study-with-friends**, **leaderboards** (Regain). **[arch/tension]** — requires accounts + cloud + moderation; breaks offline/no-account promise. Probably a 2.0+ "opt-in online layer," if ever.
- **Optional cloud sync** (already on the roadmap in Sustain 101) is the prerequisite and a gentler first step. **[arch]**

### F. Monetization (your ads/coins idea) — see §3.

---

## 3. The coins + ads economy (your proposal, designed against best practices)

### 3.1 Earning (on-brand core)
- **Each completed session grants coins ≈ its Focus Score contribution / focus minutes.** Forest scales ~3 coins / 10 min; size Sustain's so a typical day of focus feels rewarding but not inflationary. Only **completed, real** focus earns (mirrors our "no manufactured guilt / real-effort-only" rule). Sub-2-min and previews earn nothing (consistent with existing logic).
- **Streak / milestone bonuses** for consistency.

### 3.2 Spending (sinks)
- **Themes** (à-la-carte today) — let coins buy them. Natural, low-risk.
- **Cosmetics** (hourglass skins, avatar frames) — pure cosmetic, ideal sinks.
- **Pro time** (your idea: buy monthly/yearly with coins). **High-risk:** directly trades away subscription revenue. If done, price it so it's a *loyalty perk for very engaged free users*, not a bypass — e.g. coins only ever buy **short Pro passes** (a week), earned over many weeks of daily focus, never lifetime. Model the math before committing.

### 3.3 Rewarded ads (the boost lever) — research-backed guardrails *if* we proceed
- **Rewarded only, never interstitial/banner.** Completion ~95%, engagement ~3.5× vs other formats; users opt in.
- **Sizing:** a rewarded view should grant ~**5–10% of the lowest IAP's value** in coins, or ~10–15 min of natural earning. Keep the "watch ad → coins" exchange meaningful but not economy-breaking.
- **Frequency caps:** this is a calm productivity app, so go **well below** game norms — e.g. **1–3 rewarded views/session, daily cap ~5** (games use 6–10/15–20). 
- **Golden rule:** a patient ad-watcher should progress at ~60–70% the pace of a payer — never match it, or subscriptions collapse.
- **Placement:** **only after a session is fully completed** (your instinct is right and matches the highest-converting, least-intrusive placement) — an optional "watch to earn bonus coins" card on the summary screen. Never mid-session, never on launch.

### 3.4 The decision matrix (resolve in the brainstorm)
- **Option A — Coins, no ads (recommended).** Pure loyalty/gamification. Keeps every brand promise. Coins buy themes/cosmetics/short Pro passes. No SDK, no privacy/offline compromise. Lowest risk.
- **Option B — Coins + opt-in rewarded ads, in a clearly-marked 2.0.** Update the "No ads" copy *ahead of* shipping; frame ads as "optional, only if you want to earn faster, only after a session." Accept the offline/Data-Safety implications. Medium risk, adds a revenue line.
- **Option C — Status quo** (subscriptions + à-la-carte only). No economy. Lowest effort, no new retention hook.

> Whatever we pick, the **"No ads" FAQ answer and the privacy copy must be reconciled first** — changing the product means changing those promises deliberately, not silently.

---

## 4. Open questions for the brainstorming session
1. Does adding ads at all fit the brand we've spent months locking — or is the coin economy enough on its own? (§0, §3.4)
2. Are we willing to take on **accounts + cloud** (the gate to social, leaderboards, sync, charity payoff)? That's the fork between "best private focus app" and "best social study app."
3. How aggressive on **distraction blocking** given the Play-review / permissions cost (Usage Access, Accessibility)?
4. Can coins ever buy **Pro**, and if so only short passes? What's the earn-rate math that protects subscription revenue?
5. Which one **flagship** later-version feature do we lead with — Strict-mode difficulty (cheap, on-brand) vs App-blocking (high value, high cost) vs Coins economy (retention)?

## 5. Suggested phasing (straw man, to react to — not decided)
- **v1.1 (on-brand, low-arch):** Strict-mode/session difficulty (Opal-style), ambient sounds, session tags + focus-by-tag insight.
- **v1.2:** Coins economy (earn from sessions; spend on themes + cosmetics), missions, achievement wall. **No ads.**
- **v2.0 (architectural):** optional cloud sync → then optionally social/leaderboards and/or distraction blocking; only here, if ever, consider opt-in rewarded ads with a deliberate brand-copy update.

---

## Sources
- [Regain on Google Play](https://play.google.com/store/apps/details?id=ai.regainapp) · [AppBrain](https://www.appbrain.com/app/regain-study-timer-for-focus/ai.regainapp) · [Uptodown](https://regain.en.uptodown.com/android)
- [Forest](https://forestapp.cc/) · [Forest on Google Play](https://play.google.com/store/apps/details?id=cc.forestapp) · [Forest coins how-to](https://www.thegoodlifewithamyfrench.com/post/forest-app-review-and-tips)
- [Best gamified productivity apps 2026 (Yu-kai Chou)](https://yukaichou.com/lifestyle-gamification/best-gamified-productivity-apps/) · [Best focus apps for students 2026 (FocusDown)](https://focusdownapp.com/blog/best-focus-apps-students-2026)
- [Opal: Screen Time Control](https://apps.apple.com/us/app/opal-screen-time-control/id1497465230) · [Opal alternatives 2026](https://habitdoom.com/blog/opal-alternatives)
- Rewarded-ads / economy best practices: [AdReact](https://adreact.com/blog/rewarded-video-ads-mobile-game-monetization/) · [Adjust](https://www.adjust.com/blog/understanding-rewarded-video-ads/) · [Mistplay offerwalls](https://business.mistplay.com/resources/offerwall-ads) · [ASO Mobile monetization 2025](https://asomobile.net/en/blog/mobile-market-money-app-monetization-in-2025/)
