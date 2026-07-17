# Sustain — Platform Strategy & Design Spec (Web + App)

> **Status:** 🟢 Design locked (founder-approved via brainstorm 2026-07-17). Not yet built.
>
> **Supersedes** [`2026-07-11-sustain-web-design.md`](2026-07-11-sustain-web-design.md), which is kept as a
> design record. Where the two disagree, **this document wins**. The 07-11 spec's central architectural
> decision (§3, "two completely separate ecosystems, no sync between them, ever") is **reversed here** —
> see §4.
>
> **What this is:** the canonical strategy for **both products** — the Android app (shipped) and the
> website (unbuilt) — covering brand, the platform split, phased scope, and the money model for each.
> Pairs with [`../../feature-roadmap.md`](../../feature-roadmap.md) (version checklist) and
> [`../../project-context.md`](../../project-context.md) (locked rules).

---

## 1. What changed on 2026-07-17, and why

The 07-11 spec designed the website as a **separate, complete product** — its own ecosystem, its own
accounts, its own billing, shipped complete in one ~1-month launch, with a paywall from day one.

Three things forced a rethink:

1. **The app is the proven surface.** It's published, RevenueCat works, and it launched on Product Hunt
   with a good response — the hourglass visual was the standout comment. The website is unbuilt and
   unproven, and **monetizing an aesthetic web timer is the thing that killed lofi.co.** Putting the
   revenue bet on the unproven surface while the proven one waits is backwards.
2. **The retention centrepiece (Sediment, §7) needs permanent data.** Two separate ecosystems means one
   human ends up with two forked, unmergeable copies of their focus history — the emotional core of the
   product, split in half forever. Competitor research (§10) found that **not one competitor separates
   data.** Forest bills you twice and still syncs your forest. Things 3 charges $80 across three
   platforms and syncs for free.
3. **SEO is a ~6-month asset.** Every week the site isn't live is a week of ranking never recovered.
   A small, free web v1 starts that clock now.

**The result:** the app becomes the primary product and the revenue engine. The web becomes what the
07-11 spec always said its main job was — *"funnel attention → installs"* — and is **free at launch**,
with monetization deferred until the shared account infrastructure exists.

## 2. Brand & philosophy — final

| | |
|---|---|
| **Positioning** | *The calm focus timer that doesn't pull you out of flow.* |
| **Mascot** | The hourglass. Every surface, every platform, every video. Consistent character + feeling (the Lofi-Girl lesson). |
| **Retention** | **Accumulation, not anxiety.** |
| **Data** | Your focus lives on your device, free, forever. Sync is an optional service. Cancel and you keep everything local. |
| **Money** | The free tier is real, not crippled. Cosmetics are one-time. Service is recurring. **No ads, ever.** |
| **Craft** | Warm Precision (see [`../../design-language.md`](../../design-language.md)). No bounce, no sparkle, no gradient text. |

### 2.1 The retention rule (locked)

> **Come back because something beautiful is growing and it's yours — not because you're afraid to lose it.**

Research (§10) makes this a deliberate stance, not a compromise:

- **Forest works** because loss aversion is real — losses hurt ~2× equivalent gains, and that's enough to
  override the phone-check impulse in the moment it matters.
- **Duolingo is a documented dark pattern** (listed on deceptive.design): manufactured streak anxiety,
  escalating visual urgency, guilt notifications — and then it *sells streak freezes to monetize the
  anxiety it created*. The recurring finding across the literature: **gamification saps the intrinsic
  enjoyment of the underlying activity.**

We cannot ship "the calm timer" and then manufacture anxiety to retain people. It's the same self-defeating
move as paywalling Endless. So: **no streak flames, no "your streak is in danger", no guilt pushes, no
manufactured urgency.** In 2026, post-backlash, *"the focus app that doesn't manipulate you"* is a
**marketing position**. The app already leans this way — streaks ship with a 1-day grace.

**Consequence:** retention comes from **beauty and accumulation** (§7), not fear.

## 3. Never paywall these (locked)

| Never paid | Why |
|---|---|
| **Endless / Open mode** | It *is* the positioning (§2). §1 of the 07-11 spec identified "Pomodoro forces breaks" as the wedge. Paywalling Endless = paywalling the reason anyone chooses us. |
| Any timer mode | Same. |
| Share links / share cards / embed | Every share is free marketing. |
| `/stage` | It's the studio and the shop window. |
| Circadian ambiance | It's the "whoa" that markets the site. |
| Turning the hourglass *off* | Paywalling an accessibility preference reads as petty. |

## 4. Architecture: one account, one dataset, separate purchases

**This reverses 07-11 §3.** The two products share **one Firebase project, one identity, one dataset**.
They differ in **features** and in **what you buy**.

This is the **Forest model**, which the category leader has run at scale for years: purchases don't
transfer between platforms, but your data follows you everywhere. Things 3 does the same (separate
per-platform purchases, free sync). Nobody in the category separates data.

**Why the reversal is affordable:** the app needs cloud sync for its own sake anyway (it was already
roadmap V2), the Drift schema was built sync-ready by design, and `lib/data/backup_service.dart` already
exports versioned JSON and **restores by merging on uuid, never overwriting**. The groundwork exists.

**The double-charge trap, and how we avoid it:** Forest gets away with charging twice because Apple and
Google are separate islands that each take ~30% — a structural excuse users intuitively accept. We have no
store, no cut, no excuse. So the rule is:

> **You never pay twice for the same thing. You pay once for each thing you own.**

App Pro = app features. Web scenes/backgrounds/hourglass styles = **web cosmetics that don't exist in the
app**. Different things, one wallet, one account. RevenueCat already does cross-platform entitlements.

## 5. The platform split

| Capability | 🌐 Web | 📱 App | Why |
|---|---|---|---|
| Timer, all modes, **Endless** | ✅ | ✅ | The product. |
| Scenes, 3D glass, weather, custom upload | ✅ **only** | ❌ | Web deploys instantly (no store review) — it's the lab. Heavy GPU suits a desktop browser. |
| PiP, share links, embed, `/stage` | ✅ **only** | ❌ | Web-native. |
| Notifications, foreground service, strict sessions | ❌ | ✅ **only** | Needs a real OS. |
| **Sediment, Sync, Intention** | later (W2) | ✅ **first** | Permanence belongs where the data is permanent. |
| Home-screen widgets | ❌ | ✅ | OS-native. |

**Web = funnel + feature lab.** It deploys with no Play review and no risk to the live app, so experiments
ship there first and winners graduate into the app.

## 6. The money model — final

The 07-11 spec's `$3.99/mo · $23.99/yr · $49.99 lifetime` for a "Sustain Web Plus" tier is **withdrawn** —
web v1 is free, so web pricing is not a v1 decision (§13).

**The model is Obsidian's** (core app free forever — no restrictions, no signup, no ads, no tracking;
money from Sync at $4/mo and a $25 one-time Catalyst tier; profitable, no VC):

> **Cosmetics are a product — you buy a thing, you own it, once.**
> **Sync is a service — it is the only thing in the product that can honestly recur.**

**Do not tell the "sync costs real money to run" story — it isn't true** (see §6.2: the real figure is
~$0.0006/user/month). The honest reason Sync is the subscription is that cosmetics are one-time *by
nature*; a service is the only honest recurring candidate. That's sufficient, and it's exactly what
Obsidian does — their sync costs are equally trivial and nobody considers $4/mo a scam. **Users pay for
the guarantee, not the bytes.**

### 6.1 The two models

**Two separate money models, one shared service.** Cosmetics are bought where they live; Sync is bought
once and works everywhere. App themes are Flutter palettes; web scenes are 3D dioramas — **genuinely
different products with different renderers**, so buying both is buying two things, not paying twice. Sync
is the single cross-platform exception, and it should be: it's one service over one dataset.

**📱 App**

| Layer | What | Price | Rails |
|---|---|---|---|
| **Free** | Full timer, all modes, all local data, forever | $0 | — |
| **App Pro** *(shipped)* | Insights depth, Stamina, strict-session limits, continue, themes bundled | as shipped | RevenueCat + Play Billing |
| **App themes** *(shipped)* | À-la-carte `theme.<id>` | one-time | RevenueCat + Play Billing |
| **♻️ Sustain Sync** | Cloud backup + Sediment permanence + cross-device | ~$2.99/mo · ~$19.99/yr | see §6.3 |
| ~~Ads~~ | — | **never** | — |

**🌐 Web**

| Layer | What | Price | Rails |
|---|---|---|---|
| **W1 — everything** | Timer, all modes, hourglass, colours, circadian, sounds, PiP, share, embed, `/stage` | **$0** | **none — zero billing code** |
| **W2 — web cosmetics** | Scenes, 3D glass, weather, glass layer, custom upload, full mixer, hourglass shapes, sand flows | à-la-carte, or a **web lifetime bundle** | Merchant-of-Record + Firebase Function |
| **♻️ Sustain Sync** | The same one subscription | same price | Merchant-of-Record |
| ~~Ads~~ | — | **never** | — |

**YouTube** is not in either model. It is **customer acquisition at ~$0 CAC, never revenue** — see §10.

### 6.1.1 Themes vs Pro vs Sync — what a user actually gets

**Themes and Pro are deliberately entangled. Sync is deliberately not.** Verified against the shipped
source of truth, [`lib/domain/entitlements.dart:40-45`](../../../lib/domain/entitlements.dart) —
`if (pro) owned.addAll(catalogThemeIds);`.

**The rule (locked 2026-07-17):**

> **Subscriptions rent features. Only a one-time purchase owns one-time goods.**

| | Pro features | Themes |
|---|---|---|
| **Monthly / Yearly** | ✅ all, while active | ❌ **never** — buy à-la-carte, owned forever |
| **Lifetime** | ✅ forever | ✅ **every theme, forever** (incl. unmade ones) |
| **À-la-carte theme** | — | ✅ that theme, forever, independent of Pro |
| **☁️ Sync** | *(separate — see below)* | — |

**Why:** renting a theme is incoherent — themes are one-time goods. Under this rule **nobody ever rents a
theme**, themes keep their value, and **Lifetime is unambiguously the hero** (which is what this category
buys — Flocus $99 LT, Pomofocus $54 LT; and see **§6.4.1** for how badly Forest's move *away* from
one-time landed in Dec 2025). Monthly/Yearly subscribers are arguably better off: buy a theme you love and
it's yours even if you cancel, instead of losing it.

**Rejected: a "+ all themes" toggle on Pro** (founder's initial proposal). It doesn't solve the problem it
was for — Pro Monthly + toggle, then cancel: keep the themes (kills à-la-carte sales) or lose them (still
renting). And **the toggle already exists — it's the theme store**, which is more granular. It would have
cost a 4th–6th SKU across Play Console *and* RevenueCat to duplicate shipped functionality.

**Change required:** [`lib/domain/entitlements.dart:44`](../../../lib/domain/entitlements.dart) —
`if (pro) owned.addAll(catalogThemeIds);` → gate on **lifetime**, threading the flag into
`entitlementsFrom` (RevenueCat already derives it: `isLifetime = exp == null`). Small, but not zero. **Free
to do now at zero Pro buyers; expensive later.**

**Price consequence (open):** themes are now Lifetime-exclusive, so Lifetime is worth more than it was and
the subs are worth less. The current $19.99–24.99 Lifetime may be underpriced against that. Revisit when
pinning prices.

**Sync**: where your data *lives* — cloud backup, Sediment permanence, phone + web as one history.
Monthly · Yearly, **never lifetime**. Cancel → lose the cloud copy; **local data stays, free, forever**.

**Why Sync sits outside Pro** — one structural reason, not a revenue grab: *Pro Lifetime + Sync = a
perpetual service sold once = unbounded liability.* Secondarily: Pro is what the app does; Sync is where
data lives.

**Sync is separate on every plan, including Pro Yearly** — even though Yearly is already recurring and
bundling would cost ~$0.01/user/year. Bundling would make Lifetime the booby prize (contradicting §6.4)
and turn a clean two-product story into a matrix.

**UI rule (locked): Sync is never a tier on the Pro paywall.** Side by side they read as tiers, Sync
becomes "Pro+", and "Lifetime = everything forever" becomes a lie in the user's eyes — the same trap as the
Pro/Plus ladder. Separate surfaces: the Pro paywall sells Pro and *mentions* Sync in one neutral line; the
Sync screen (reached from Settings → Your data, and the Sediment view) sells Sync.

**Sync copy must never claim "servers cost money"** — it's false (§6.2), so it can't be told to users
either. We owe clarity, not justification. The line that does the real work is *"cancel anytime — your
focus stays on your phone, free, forever."*

### 6.1.2 Prices — REVISED 2026-07-17

**⚠️ Supersedes the prices locked in
[`2026-06-22-strict-sessions-and-monetization-design.md`](2026-06-22-strict-sessions-and-monetization-design.md)**
(₹149/$4.99 · ₹799/$29.99 · ₹1,499/$59.99). Per the doc-map rule, the latest dated spec wins.

| | Old | **New** | Why it moved |
|---|---|---|---|
| **Pro Monthly** | $4.99 · ₹149 | **$2.99 · ₹89** | Lost themes (§6.1.1) — buys strictly less than it did. At $4.99, 12 months = $59.88: the whole Lifetime price, for features only, owning nothing at the end. That's the deal that earns one-star reviews. |
| **Pro Yearly** | $29.99 · ₹799 | **$19.99 · ₹549** | Lost themes. Lifetime now pays back in ~2.5 years — steering toward the plan this category actually buys. |
| **Pro Lifetime** | $59.99 · ₹1,499 | **$49.99 · ₹1,299** | Founding price. Undercuts Flocus ($99) by half; sits just under Pomofocus ($54). |
| **Theme à-la-carte** | — | **$2.99 · ₹89** | The free-tier cosmetic path. |
| **☁️ Sync** | — | **$1.99/mo · $14.99/yr** | Must not collide with Pro Yearly. ~92% margin (§6.2). |

**The two forces, which cut opposite ways:** subs *lost* themes (→ cheaper); Lifetime *gained* exclusivity
(→ more defensible). But the app has **<100 installs, no reviews, and no web presence — i.e. no pricing
power yet.** $59.99 was top-of-category for an Android-only app nobody's heard of.

**Raise Lifetime to $59.99 / ₹1,499 when web + Sediment + Sync land.** Early buyers keep everything forever
at what they paid (§6.4). **Pomofocus proved exactly this mechanic** — research found the same product at
`$36` and later `$54`. They earned the raise; we haven't yet.

**Honest note on the size of this decision:** at ~$100–700/yr realistic revenue, $49.99 vs $59.99 is about
**two sales a year**. It is financial noise. It is **not** positioning noise — and positioning is the only
basis on which it should be decided.

**India ₹ stays PPP-aligned** at the existing ~₹26–30 per USD ratio (not the ~₹83 market rate). ₹89 lands
exactly on the low end of the ₹89–₹1,499 band already set.

### 6.2 Sync unit economics (costed 2026-07-17)

**Sync is profitable from subscriber #1. It is not volume-dependent.**

A session record (uuid, times, mode, score, theme, intention) is ~300 bytes. A heavy user at 3
sessions/day writes ~1,100/year ≈ **330 KB/year**; ten years of an entire focus life is ~3 MB. It's text.

| Per user / month (Firestore) | |
|---|---|
| Storage | ~$0.00003 |
| Writes (~90) | ~$0.00016 |
| Reads (~300) | ~$0.00018 |
| Egress (~2 MB) | ~$0.00024 |
| **Total** | **≈ $0.0006/mo** |

| At $19.99/yr | At $2.99/mo |
|---|---|
| MoR fee (~5% + $0.50): −$1.50 | MoR fee: −$0.65 — **22% gone** |
| Infra: −$0.01 | Infra: ~$0.00 |
| **Net ~$18.49 → ~92% margin** | **Net ~$2.34 → ~78% margin** |

Fixed costs are ~$0 (Firebase's free tier alone covers 1 GiB storage and 50k reads/day) plus $11/yr for
the domain. **Break-even ≈ one subscriber.** The annual price does the real work (7.5% to fees vs 22%).

**🔒 No lifetime Sync. Ever.** A perpetual service sold once is an unbounded liability. Monthly and annual
only.

**⚠️ The real cost centre is images, not sync.** Custom background upload: 1,000 users × 30 loads/mo × 4 MB
≈ **120 GB egress ≈ $14/mo** and climbing. That lives in **W2** and is solvable (Cloudflare R2 has zero
egress fees; CDN caching). Sync is free; pictures aren't.

### 6.3 Where Sync is sold — RESOLVED 2026-07-17

**Checked against current Play policy. The arbitrage doesn't exist, so don't build for it.**

Google opened external billing on **2026-06-30** (US, EEA, UK only — **India is not in the rollout**). But
the service fee applies **regardless of billing method**:

| Route | Google takes | We also pay | Total |
|---|---|---|---|
| **Play Billing** (US/UK/EEA) | 10% service + 5% billing | — | **~15%** |
| **External web link** | **10% service fee — still** | our MoR ~5% + $0.50 | **~15%+** |

External is a wash, and arguably *worse* once the MoR's fixed $0.50 lands on a $2.99 charge.

**Decision: Play Billing in-app, MoR on the web, no steering games.** Same entitlement either way;
RevenueCat already does cross-platform entitlements. A purchase made on the website by someone who never
touches the app carries no Google fee — that's the only real saving, and it needs no policy gymnastics.

> **Risk-model correction (recorded so it isn't repeated):** the downside of violating Play billing policy
> was never "a few percent" — it is **app removal**. Cost and existential risk are not the same units. This
> happens to be moot now that Google permits it, but "so what, it's some percent more" was the wrong frame.

**Re-verify at billing-build time** — this ground has moved repeatedly (Epic v. Google, the EU DMA, India's
CCI rulings) and the India rollout status in particular is likely to change.

### 6.4 The lifetime promise, kept

07-11 §6.2 promised *"lifetime includes every future cosmetic addition, free — never left behind, no
disparity, by design."* **That promise is kept**, and it's honest: cosmetics genuinely cost nothing to
serve, so "forever" is free to honour.

Sync isn't a cosmetic — it's a **service**, and a lifetime price on a perpetual service is an unbounded
liability (§6.2). That distinction is self-evident to a user rather than a betrayal, and it's the same
carve-out 07-11 §6.2 already made for YouTube streaming (*"a separate add-on for everyone, even lifetime
holders, disclosed plainly"*).

**A growing tier ladder and lifetime are mutually exclusive.** If someone buys "lifetime" and a higher tier
later appears, they *are* left behind. **So there is no tier ladder** — one paid line that grows, and
**founding prices raised as the product grows**. Early buyers keep everything forever at what they paid:
that's the reward, it creates honest urgency, and it needs no tiers. Pomofocus proved the mechanic —
research found the same product at both `$36` and `$54` lifetime at different times.

**Existing app Pro Lifetime holders get Sync free, forever.** The roadmap told them *"Pro Lifetime =
own-all bundle."* They are few, they bought before there was proof, and honouring them costs almost
nothing while letting us say "Sync is a service" cleanly from here on, breaking no promise to anyone.

**Sync is anti-churn by design:** two years of accumulated sediment is not something a person cancels. The
longer you use it, the more the service is worth — the best recurring dynamic available.

**Drop Monthly on cosmetics.** A Merchant-of-Record takes roughly 5% + $0.50 — on a $3.99/mo product
that's **~17% to fees**, plus churn, dunning, proration, and failed-payment support. Sync recurs;
cosmetics don't need to.

**Payments:** a **Merchant-of-Record** (Lemon Squeezy / Paddle / Polar — pin at billing-build time) for
worldwide sales-tax/VAT compliance, which also sidesteps Stripe-India registration + RBI e-mandate
friction. MoR webhooks a Firebase Function that flips an entitlement flag.

**India ₹ PPP** mirrors the app's existing strategy — later, once there's traffic. One global USD price at
launch.

### 6.4.1 ⚠️ CORRECTION — Forest abandoned the one-time model (researched 2026-07-17)

**An earlier claim in this brainstorm was wrong and is corrected here.** It was asserted that *"Forest,
the one app with a one-time purchase, is the only one that escapes the subscription-resentment complaint
almost entirely."* That describes a Forest **that no longer exists**:

> Forest launched in 2014 as a paid app. **In December 2025 Seekrtech moved it to a free download backed
> by a "Forest Plus" subscription** — and took precisely the backlash this spec predicts: longtime
> one-time buyers "suddenly facing a subscription requirement for premium features… perceived as a
> reversal of the app's original value proposition."

The 2026 article quoted was describing a model Forest had already left. **The category leader gave up on
one-time.** (Caught by the research-first rule in `project-context.md`, applied to this spec's own claim.)

**How Forest sustained one-time for 11 years — and why we can't copy it:**

1. **Volume.** Tens of millions of downloads × $1.99–3.99. One-time works only as a *treadmill*: revenue
   requires an endless supply of NEW users, forever. **We have <100 installs.**
2. **Consumables (coins).** The same user buys repeatedly — recurring revenue without a subscription.
3. **An in-app marketplace**, added late "to drive a unique revenue stream."
4. **Backend cost was never the problem.** Tree records are text — the same arithmetic as our sediment
   (~$0.0006/user/month, §6.2). **Salaries killed the one-time model, not servers.**

**What it means for us — it validates the design rather than threatening it:**

| Mechanism | Recurring? | Ours? |
|---|---|---|
| One-time × volume | ❌ treadmill, needs endless new users | ❌ no volume |
| Consumables (coins) | ✅ | ❌ cut — brand cost (§2.1, §11) |
| **Cosmetic drops** (scenes/themes, à-la-carte) | ✅ repeatable | ✅ **the model** |
| **Service subscription** (Sync) | ✅ honest, anti-churn | ✅ **the model** |
| Give up → subscription | ✅ | ← what Forest did in Dec 2025 |

**Sync + repeatable à-la-carte cosmetics is where Forest arrived after 11 years and a painful reversal.
We start there.** And the decisive difference: **Forest is a company with salaries; we are solo with ~$0
fixed cost.** One-time cannot fund a payroll — it can comfortably fund a founder. That is exactly why Pro
does **not** need to be recurring (§6.4) and Sync alone carries it.

### 6.5 Adding a subscription to a shipped app — the risks

- **🚨 THE LIVE ONE: the shipped paywall already promises Sync away.** Not a roadmap note — **in-app copy,
  shown at the point of sale, right now**:
  - [`lib/ui/paywall_screen.dart:472`](../../../lib/ui/paywall_screen.dart) — *"Everything new, included —
    Every Pro feature we ship lands in your plan automatically."*
  - [`lib/ui/paywall_screen.dart:664`](../../../lib/ui/paywall_screen.dart) — *"Yours forever — no renewal.
    **Every Pro feature we add later is included automatically.**"*

  As of 2026-07-17 there are **zero Pro buyers**, so the window to fix this cleanly is **open and closes on
  the first sale**. Disclose *before* anyone pays that Pro Lifetime covers every Pro **feature** and that
  optional **services** (cloud sync) are separate. Disclosed at purchase = honest; discovered after = a
  betrayal in writing, with a screenshot attached to the review. This is the same carve-out 07-11 §6.2
  already committed to for YouTube streaming (*"disclosed plainly so no one feels misled"*).
- **⚠️ Backlash.** The app was sold as *"Pro Lifetime = own-all bundle."* Adding a subscription invites
  one-star reviews. The mitigation is real and must be **said plainly in the release notes**: local data
  stays free forever, Sync is genuinely optional, and nothing anyone bought is removed.
- **🚩 Privacy posture changes.** v1 ships *"zero third-party analytics/telemetry"* and *on-device only*.
  The moment Sync exists, the **privacy policy and the Play Data Safety form must be updated.** That is
  compliance, not optional.
- **🚩 The v1 snapshot never happened.** [`../../feature-roadmap.md`](../../feature-roadmap.md) still has
  *"At publish: snapshot the v1 code into a frozen folder for live hotfixes"* unchecked, and the app is
  **already published** — so a hotfix today means shipping whatever is in `master`. This is a live risk
  **now**, independent of this spec.

## 7. 🏺 The Sediment — the centrepiece

**Your sand doesn't disappear when the session ends. It settles.**

Every completed session lays down a **layer** in a vessel you keep forever:

| Property | Encodes |
|---|---|
| **Thickness** | how long you focused |
| **Colour** | the theme/scene you focused in |
| **Texture** | your focus score — dense and clean, or coarse and broken |

After a year you own a **geological core sample of your focus life**. Scrub it, zoom it, tap a stratum →
that session. It never resets. It only grows.

**Why it's the answer:**

- **Native to the metaphor.** Forest bolted trees onto a timer. Sand already falls — this only asks where
  it goes. No foreign object in the brand.
- **It's four features at once:** progression, collection, the insights visualization, and the share card.
- **It's accumulation, not anxiety** (§2.1). Miss a week and you get a thin gap in the rock — honest, and
  beautiful rather than punishing. Geology has quiet periods.
- **It replaces Levels.** Accumulation *is* the progression (§11).
- **It rides data we already store.** The Drift schema records every session; this is a rendering layer.
- **It makes Sync worth paying for** (§6) and it's the reason the install hook works.

### 7.1 Supporting mechanics

| Mechanic | What | Where |
|---|---|---|
| **🔄 The flip** | Don't press a button to begin — **grab the glass and turn it over**. Humans have done exactly this for 800 years. The ritual, tactile and satisfying enough to want to repeat. The app already owns the flip animation from onboarding. | Both |
| **✍️ Intention** | Before you flip, one line: what is this for? Recorded with the stratum. Tap any layer → *"Oct 3 · 50 min · Zen Garden · 'finishing the thesis intro'."* Your focus autobiography — this is what makes the data **precious**, which is what makes Sync a real purchase. Absorbs the roadmap's *notes/journal*. | Both |
| **💨 The spill** | Abandon a session and the sand simply **doesn't settle** — no layer is laid. No cracked glass, no sad mascot, no guilt. Forest's loss aversion without Forest's cuteness or Duolingo's cruelty. | Both |
| **✨ Rare moments** | Occasionally — unannounced, never a popup — a grain glints, a bird crosses the garden, a petal lands on the glass. Variable reward as *delight*, not a slot machine. | Web W2 |
| **🌍 The Collective** | *"1,240 hourglasses are running right now."* lofi girl's real power was never the music — it was *you're not alone*. **Collective, not competitive**: no rank, so nothing to cheat; no comparison, so nothing to feel bad about. This is the leaderboard, done calm. | Web W3 |
| **🔗 Focus room** | One link, two people, same scene, both hourglasses running. Focusmate charges ~$10/mo for this feeling. A room ID and two timestamps. | Web W3 |

## 8. Web — phased

### W1 — the funnel *(next, ~1 month, FREE)*

Zero billing code. Its only jobs: **rank, and convert to install.**

- **Landing page** — scroll-driven narrative with **one persistent hourglass**: the hourglass is pinned and
  continuous while sections scroll past it (Framer-Motion-style). Never re-mounted per section.
- Timer: Flow / Pomodoro / Custom / **Endless**.
- **The current hourglass** — a faithful port of the 2.5D canvas painter (`lib/hourglass/hourglass_painter.dart`).
- Solid + gradient colours for background and sand.
- **Circadian colour drift** — follows the user's real local clock, including mid-session.
- Basic soundscapes.
- Session view `[min] · 🏺 · [secs]` — numbers hidden by default, fading in calmly on hover/mouse-move.
  Timer visibility setting: *always show* · *flash every N minutes* · *hidden, show on hover*.
- **PiP** (Document Picture-in-Picture) · **share preset links** · **embeddable widget** · **`/stage`**
  fullscreen · **`/stage?record=1`** quality preset for OBS.
- **Local "focused today"** counter (localStorage only — no history, no account, nothing to migrate later).
- Tasteful install CTA on every surface. SEO (§9).

### W2 — the scenic engine *(after app Sync ships)*

- **Photoreal scene dioramas** (§12) — Zen garden, ocean depths, rain, aurora, etc.
- **3D glass hourglass** (§12).
- **Weather modules** — rain/snow driven by the user's real local weather. *Your city rains, your garden rains.*
- Glass background layer · **custom background upload** · full soundscape mixer · hourglass shapes and
  sand-flow styles · **rare moments**.
- **Accounts** — shared with the app (§4). **Sediment appears on web here.**
- Money turns on: à-la-carte cosmetics + lifetime bundle.

### W3 — social

- **The Collective** · **Focus room**.

## 9. SEO (W1 — the whole point of shipping early)

- Real server-rendered HTML. **Explicitly NOT Flutter-web** (multi-MB payload, invisible to Google,
  non-native feel — fatal for a funnel). Public pages (landing, timer, `/stage`) static/SSR.
- Fast Core Web Vitals, mobile-first. **The persistent-hourglass scroll hero is the single easiest way to
  break this** — it must be built against a performance budget, not retrofitted.
- The free timer is usable with **no login** — both a funnel requirement and an SEO requirement.
- Target terms: *"online timer," "pomodoro timer," "focus timer," "aesthetic study timer," "hourglass
  timer,"* and the orphaned **"lofi.co alternative"** (lofi.co shut down May 2024; people still search it).
- `<title>`/meta/**OpenGraph**, `sitemap.xml`, `robots.txt`, **Google Search Console** (verify via DNS).
- **Backlink flywheel** — share links + embed widget + YouTube descriptions all point back.

## 10. YouTube — marketing, never income

The `/stage` page is pointed at by **OBS *Browser Source*** (never Window/Display Capture — that
screen-scrapes a throttled background tab, which is the root cause of the founder's freeze/black-screen
glitch; a Browser Source renders the page *inside* OBS, immune to focus throttling). OBS → YouTube Live;
the stream auto-archives as a VOD. ~6000 Kbps @ 1080p, NVENC if available.

**The site is the studio. We do not build a second render engine.** A 4-hour video is 4 hours of frames
(~864,000) — offline rendering is *strictly slower* than real-time and you'd wait 4 hours either way.

**Model it as customer acquisition at ~$0 CAC, never as revenue.** The research is unambiguous: 24/7 lofi
livestreams serve only **one pre-roll per viewer**, so College Music converted **38 million minutes of
watch time into ~$1,300 lifetime**. Even Lofi Girl — the category monopoly — reports ~$28.6K income.
Channels earning $500–10K/mo do it on memberships, merch and sponsorship, and one operator nets ~$1,500/mo
*after* $200–300/mo of server cost. **Those channels monetize badly because they have nothing to sell.**
We do. Every video description links the exact preset URL that made it
(`sustaintimer.com/?scene=zen&flow=240`) — the video is the ad, and the ad is the product.

## 11. App — phased

### v1 — SHIPPED
Core engine, Focus Score, Stamina, Home, Setup, Session, Onboarding, Profile/DB, Insights, Themes,
monetization + entitlements, backup/restore, strict sessions, notifications, Guide, zero telemetry.

### v1.2 — the polish release *(small, ships fast)*
- **Background soundscapes** — *blocked on founder sourcing royalty-free/CC0 audio + CREDITS.md.*
- **Native MediaStyle notification** (~1 focused day + device testing).
- **Sand-fall origin realism** (touches the locked painter — confirm before changing the locked look).

### v1.3 — the big one *(the recurring engine)*
- **Cloud Sync** — Firebase auth + sync. Shared identity with web (§4).
- **Sediment** (§7).
- **Intention** (§7.1) — absorbs the old *notes/journal* item.

> **Why v1.2 and v1.3 are separate:** the founder's instinct was one release. But v1.2's soundscapes are
> blocked on an *asset-sourcing* action, MediaStyle and sand realism are days, and Cloud+Sediment is weeks.
> **Two shippable releases beat one stalled one.**

### v2
- **Home-screen widgets.**
- **PiP mini-session.**
- **Focus Wrapped** — built as **a view of your sediment**, not a separate system.

### CUT (founder-approved, 2026-07-17)

| Cut | Why |
|---|---|
| ~~Focus currency + rewarded ads~~ | Contradicts "no ads, ever" (§2). At current volume, rewarded ads earn pennies while costing the brand position that makes people trust us. |
| ~~Levels / progression~~ | Sediment *is* the progression (§7), natively. Levels unlocking cosmetics gives away what we sell. |
| ~~Spotify connect~~ | Requires the user to hold Spotify Premium for playback control; real OAuth/API cost for something our own soundscapes serve. |
| ~~Break activities (sudoku/breathing/meditation)~~ | A second app bolted inside the app. Nothing to do with focus. |
| ~~Leaderboard~~ | Client-computed scores are user-editable — cheated via devtools in minutes. Also a pure anxiety mechanic (§2.1). Replaced by **The Collective** (§7.1). |
| ~~Browser extension~~ | **Document PiP already gives a floating always-on-top hourglass from the web page** — no install, no store review, no maintenance. Forest's extension is valuable because it *blocks*; a pure timer extension has no job. Build it only if/when blocking exists. |
| ~~Site/app blocking + monitoring~~ | **❌ Probably never on Android — the platform closed the door.** Play enforced a new **AccessibilityService policy on 2026-01-28** and Android 17 hardened it: *"only apps whose core purpose is accessibility"* may use the API (screen readers, switch input, voice control, Braille). Under **Advanced Protection Mode, Android auto-revokes AccessibilityService access from any app not classified as an accessibility tool.** Sustain's core purpose is not accessibility — we could not honestly declare `isAccessibilityTool="true"`, and it would be revoked regardless. Revisit only if a sanctioned API appears. |
| ~~"Plus" tier for blocking/DnD~~ | **❌ No tier ladder** (§6.4 — a ladder and lifetime are mutually exclusive). Also: there is no blocking to tier. And the category punishes subscription greed — Opal charges **$99.99/yr** and *"draws the most pricing anger… the highest in the category"* for what overlaps free OS Screen Time. **NB:** the "Forest escapes subscription resentment" line once cited here is **stale — Forest itself moved to a subscription in Dec 2025 and took the backlash** (§6.4.1). The lesson stands, inverted: resentment is real and Forest wore it. Ours is avoided by keeping Pro one-time and putting recurring only on a *service* (Sync). |
| **Do-Not-Disturb** ✅ | **KEEP — build it, put it in Pro.** Completely unlike blocking: `NotificationManager.setInterruptionFilter()` + `ACCESS_NOTIFICATION_POLICY` is documented, legitimate, small, and carries no policy risk. It's a session-engine feature, not a new product. |

## 12. Rendering architecture (W2)

**Do not real-time-render the scenes.** The reference images are AI stills with global illumination,
volumetric light, thousands of blossoms and water caustics. Rebuilding that in WebGL at 60fps is AAA-game
work — a 3D artist per scene, weeks each — and it would still run badly on a mid laptop. **The realism
budget goes into one object; everything expensive is baked into the plate.**

| Layer | What | Per-theme cost |
|---|---|---|
| **World** | The AI still + a **depth map** → real 2.5D parallax. Depth Anything V2/V3 produces a clean depth map from any single image — an established pipeline into Three.js (the trick behind Facebook 3D photos). Run **once, offline, per plate.** | plate + depth map |
| **Hourglass** | One Three.js object. `MeshPhysicalMaterial` with `transmission: 1.0`, `ior: 1.5`, `thickness` — genuine refraction of the world behind it, plus chromatic aberration at the edges. Sits *inside* the world at correct depth. | none — same model |
| **Atmosphere** | Petals/bubbles/embers as particles; water shimmer and light shafts as masked shader regions. | masks |
| **Comp lock** | One colour grade + one film grain over the **whole frame**. | LUT |

**A new scene = a plate, a depth map, a few masks, and a JSON config. Zero new code.**

**The four things that actually sell realism** (not the glass — the glass is the easy part now):

1. **Env map from the plate itself** — the hourglass reflects its own garden. This is what stops "3D object
   pasted on a photo." *(Upgrade path: Blockade/Skybox AI generates true 360 panos from a prompt.)*
2. **Contact shadow + caustic pool** beneath it.
3. **Unified grade + grain across the whole frame** — cheapest lever, biggest win; it's how VFX sells a comp.
4. **Slow camera breath** — 2–3% drift through the depth map over minutes. Static plates read as wallpaper;
   parallax reads as *place*.

**The sand is faked, honestly.** No granular simulation — 100k grains at 60fps is a fantasy and pointless,
nobody can tell. Instanced particles for the falling stream, a displaced cone mesh growing below, a
draining depression above. This ports the existing painter's *behaviour* and upgrades its *shading* — the
same trick that was the standout comment on Product Hunt.

**Depth Anything works on any photo** — which is why **custom background upload** (a bullet in the 07-11
spec) becomes the headline paid feature: *upload your own photo → it becomes a living 3D scene with a real
hourglass standing in it.* Three sliders for light direction/warmth/intensity. Nobody in the category has
it, every result is unique, and every result is shareable.

**Two engines, deliberately.** W1 ships the 2.5D canvas painter; W2 adds the 3D glass for scenes. This is
real duplicated work — accepted because the 2D path is also the honest **low-end/perf fallback**
(transmission has a high per-pixel cost — fine on desktop, heavy on low-end mobile).

## 13. Open decisions (deferred, not blockers)

- **⚠️ Where Sync is sold (§6.3)** — the highest-value open question here, worth **10–25% of every
  subscription**. Requires verification against **current** Play policy at billing-build time, because
  getting it wrong risks the published app. Not a guess to be made from memory.
- Frontend framework (Astro / Next / SvelteKit), MoR provider, audio source — pin at plan/build time.
- **Web cosmetic pricing** — not a W1 decision; W1 is free. Pin at W2.
- Sync price (~$2.99/mo · ~$19.99/yr proposed) — pin at billing-build time.
- India ₹ PPP — mirror the app's strategy once there's traffic.
- **The two reference plates that aren't calm** (Times Square, lightning storm) — decide against §2 before
  W2 asset generation.

## 14. Risks (standing)

- **The uncanny valley is the real rendering risk.** A *near*-photoreal object that's slightly off looks
  worse than a stylized one. The existing painter is loved *because* it's honestly stylized. §12's four
  levers are the mitigation; the founder's eye is the judge.
- **The look-match loop is unbounded by definition** and is the single biggest schedule risk in W2 — the
  engine is ordinary work; "until it looks real" is not.
- **Charging for a web timer is more ambitious than anyone in the category has managed.** Forest's browser
  product is free — the leader doesn't monetize the browser at all. Pomofocus monetizes web for modest
  indie money. lofi.co tried and died. W2's paywall is a **bet**, and is sequenced after the app's revenue
  works for exactly that reason.
- Transmission-glass performance on low-end devices.
- **Web v1 has no memory and no paywall by design** — judge it on ranking and installs, not engagement.
- Keep the calm/no-gimmick brand. Two of the reference plates (Times Square, lightning storm) are gorgeous
  and are **not calm** — they need a decision against §2 before they ship.
- **Mockup copy must not oversell.** The reference mockups show App Store badges, "iOS, Android, macOS &
  Windows", and a "Deep Focus — block distractions" feature. Today it's **Android-only with no blocking**.
  The layout is the decision; the claims must match reality.

## 15. Founder actions (outside the build)

- ✅ ~~Snapshot the published v1 code~~ — **DONE 2026-07-17**: git tag **`v1.0.0+5`** on `25f1b98`, pushed.
  Hotfix the live app from that tag, never from `master` (which is ~1,900 lines ahead — the unreleased
  large-font responsiveness fixes).
- **🚩 Update Play Console prices** to §6.1.2 (Monthly $2.99/₹89 · Yearly $19.99/₹549 · Lifetime
  $49.99/₹1,299) — and RevenueCat offerings to match. **Do this before the first Pro sale**, alongside the
  paywall copy fix, so no buyer ever sees the old numbers or the old promise.
- **Buy the domain** — `sustaintimer.com` ($11/yr, best for the funnel: trusted `.com`, memorable in a
  video, "timer" aids ranking) or `sustain.zone` ($15/yr, more brandable). *All clean `sustain.*` domains
  (`.app/.co/.so`) are taken.*
- Create the **Firebase project** + Google OAuth (now **one** project shared by app and web — §4).
- Pick the **Merchant-of-Record** (W2).
- Decide the **audio source** for soundscapes (blocks app v1.2).
- **Confirm Midjourney commercial rights** for the scene plates before they're sold (W2).
- Generate the scene plates (W2) — the asset pipeline is the founder's, not code.

---

*Next step: `writing-plans` for **Web W1** — the free funnel. It is the only fully-specified, unblocked
phase, and it's the one that starts the SEO clock.*
