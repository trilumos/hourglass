# Sustain on YouTube — channel strategy, algorithm model, and the 90-day plan

**Date:** 2026-08-02 · **Status:** research complete, strategy LOCKED, all 3 founder decisions resolved (§12)
**Channel:** **Sustain — `@SustainTimer`** (live, 0 videos as of writing)
**Supersedes the conclusion of** platform-strategy §10 ("YouTube — marketing, never income") — see §1.
**Companion to** `docs/obs-stage-streaming-guide.md` and master spec §18.7 (`/stage`).

---

## 1. The verdict — §10 was half right, and the half it got wrong is the profitable half

Strategy §10 says YouTube is *"customer acquisition at ~$0 CAC, never revenue."* Its evidence is real but it
was measured on **livestreams**:

> College Music converted **38 million minutes of watch time into ~$1,300 lifetime.**

That number is true and it stays true. A 24/7 livestream serves **one pre-roll per viewer** and then nothing
for the next four hours. The viewer's time is real; the ad inventory is not.

**A discrete VOD monetises through a completely different mechanism.** Any video 8 minutes or longer carries
**mid-roll** breaks ([YouTube Help](https://support.google.com/youtube/answer/6175006?hl=en)), and this niche
has an average view duration of **2–4 hours against a platform average of ~7 minutes**
([reported](https://medium.com/@twistszymon/make-money-with-ambient-videos-side-hustle-8054438caee2)). One
viewer, one session, many ad breaks — the exact opposite of the livestream case.

The founder's reference channel proves it out. **Timer Palette** (`@timer.palette`, vidIQ, 2026-08-02):

| | |
|---|---|
| Created | **2025-02-10** (17.7 months old) |
| Subscribers | 73,300 |
| Lifetime views | 14,469,675 |
| Videos | 592 |
| Views, last 30 days | 1,301,820 |
| **Estimated earnings** | **~$3,273 / month** |
| Shorts | **zero** |

vidIQ's per-video model on their biggest video (2,671,501 views) returns **$3,967 – $10,579**, mid **$6,612**
→ an **RPM of ~$2.47 per 1,000 views**. Cross-check: 1.30M monthly views × $2.47 = **$3,210**, which lands on
the $3,273 channel estimate. The model is internally consistent.

**So: ~$2.5 RPM × volume, compounding over a library.** Lifetime that channel has earned roughly $35K.

> **The correction to §10:** *"never revenue"* is **true for livestreams and false for VODs.* The difference
> is not the content — it is the ad format. §10's own closing line ("those channels monetize badly because
> they have nothing to sell") remains right, and now cuts in our favour twice: **VODs earn ad revenue AND
> carry the link.** It was never an either/or. Treat YouTube as **both** a revenue line and the funnel.

**Caveat, stated plainly:** every dollar figure above is a **third-party model** (vidIQ applies a category
RPM × geo multiplier), not YouTube Analytics. Directionally sound, not accounting. The first real number
arrives when we are monetised.

---

## 2. The single most important fact in this entire document

I pulled the month-by-month history of Timer Palette's biggest video (`Nc40WbWz8CE`, published 2025-06-20):

| Age | Views |
|---|---|
| 11 days | 387 |
| 1.5 months | 512 |
| 2.5 months | **649** |
| 3.5 months | 2,308 |
| 4.5 months | 9,857 |
| **5.5 months** | **291,557** ← ignition |
| 7.5 months | 1,178,331 |
| 12 months | 2,453,706 |
| 13.5 months | 2,671,501 |

**That video had 649 views after two and a half months. It now has 2.67 million.**

This is not a hit-driven business, it is a **library that ignites late**. Confirmation: Timer Palette's
uploads from the last three weeks are sitting at **200–4,800 views each** — and the channel still earns
~$3,273/month, because the money is coming from a back catalogue that ignited months ago. Roughly **50 of
their 592 videos carry ~85% of all views.**

Three consequences, and they govern everything else:

1. **The channel cannot be judged before month 6.** A video at 400 views in week three is *on plan*.
   Quitting at month 3 because "nothing is working" is the single most likely way this fails.
2. **Volume is buying lottery tickets** — which only works because `/stage` makes a ticket nearly free.
3. **Never delete or unlist an underperformer.** It is not a failure, it is an unexploded charge.

---

## 3. How the 2026 algorithm actually works, and what it means for a timer video

YouTube is **five separate recommendation systems** — Home, Suggested, Search, Subscriptions, Shorts — each
with different primary signals, resolving one question: *will this specific viewer enjoy this specific video
right now?*

The 2026 shift that matters: **viewer satisfaction has overtaken raw watch time as the primary ranking
input** (satisfaction surveys, repeat views, shares, returns to channel; negative weight on "don't recommend
channel"). And for long-form, **session contribution** — how much your video extends the viewer's overall
YouTube session — is now the leading signal, which is why series and playlists outperform one-off uploads
([vidIQ](https://vidiq.com/blog/post/understanding-youtube-algorithm/),
[OutlierKit](https://outlierkit.com/resources/youtube-viewer-satisfaction-algorithm-2026/)).

**Read that against a focus timer and it is an unusually good fit:**

| Signal the algorithm now rewards | What a timer video naturally does |
|---|---|
| Viewer satisfaction | The viewer got what the title promised — a 50/10 timer that ran 4 hours |
| **Repeat views** | People re-run the *same* timer daily. This is the format's superpower. |
| Session contribution | A 4-hour view is the longest session-extender on the platform |
| Returns to channel | A tool you liked is a tool you come back to |
| Avg view duration | 2–4 h vs the ~7 min platform average |

**Search is our primary system, not Home.** Nobody browses into a timer — they *type* one. "pomodoro timer"
is **415,235 searches/month**, "study with me" **2,533,520**, "study timer" 103,138, "brown noise for
studying" 199,658 (vidIQ). This is a **search-intent library**, and that is exactly why the ignition curve in
§2 looks the way it does: search rankings accrue slowly, then compound.

**Practical translation:** we are not optimising a thumbnail for a browse feed. We are **occupying query
space** — one video per query a real person types.

---

## 4. The existential risk, named honestly

On **2025-07-15** YouTube renamed its "repetitious content" policy to **inauthentic content**
([policy](https://support.google.com/youtube/answer/1311392?hl=en)). Content that is *"mass-produced,
generic, repetitive, or manipulative"* is **not eligible for monetization**. Reported triggers include
**repetitive thumbnails and titles, templated video structure, and excessively frequent uploads**.

Read literally, that describes the entire timer niche — including Timer Palette, which publishes **two
near-identical videos per day** under one rigid title template. They are monetised anyway. Why:

1. **The variation is functional, not cosmetic.** A 25/5 and a 50/10 are genuinely different tools serving
   different searches. That is a catalogue, not a template farm.
2. **The assets are original**, and they say so — their channel description carries an explicit declaration:
   *"All designs, illustrations, and sounds on this channel are my own original creations. AI was not used
   either."* That sentence is a **compliance artefact**, and we want our own version of it.

> **⚠️ Do NOT copy their wording.** Sustain's scene plates **are AI stills** (strategy §12 says so plainly),
> so *"AI was not used"* would be a **false declaration** — and a false compliance statement is far worse than
> no statement. Our honest claim is a different and, for this policy, a stronger one: **the video is a
> real-time capture of a program we wrote.** Say that, and only that:
>
> *"Every video on this channel is a real-time recording of Sustain's own timer — an original render engine
> with simulated sand physics and a live day/night cycle. Nothing here is a loop or a slideshow; no session is
> ever recorded twice."*
>
> Every clause is verifiable against the repo. That is what an appeal needs.

**Sustain's position here is materially stronger than Timer Palette's**, and this is the strategic core:

> Our video is a **real-time capture of a real running program** — real sand physics, a real day/night cycle
> that advances across the session, a real timer engine. The frame at 03:12:44 has never existed before and
> will not repeat. It is not a loop, not a slideshow, not a still with a countdown composited on.

That is the strongest possible answer to "is this mass-produced?" — and appeals in this area **succeed on
evidence of a real production process, not on stated intent**. We have a repo, a render engine, and a capture
pipeline. Keep that provenance, and keep the OBS project files.

**The hard don'ts that follow (each one is a channel-ending mistake):**

- ❌ **Never upload the same render twice under different titles.** That is precisely the violation.
- ❌ **Never use music we do not own.** A Content ID claim redirects **100% of that video's revenue** to the
  rights holder. Strategy §6.1.4 already ships no in-house music — that constraint is now an asset.
- ❌ No purchased views/subs, no engagement pods.
- ❌ No AI voiceover, no AI-generated stills. We do not need them and they attract the wrong classifier.

---

## 5. Format decision — Pomodoro VODs, not a continuous timer, and not a livestream

Three structural reasons, in order of weight:

1. **Livestream vs VOD** is the §1 argument: one pre-roll vs many mid-rolls. **VOD wins outright.**
2. **Pomodoro beats a continuous timer for ad revenue.** YouTube's automatic mid-roll placement uses ML to
   find *"natural visual or audio breaks."* A silent continuous 4-hour timer contains **none**. A Pomodoro
   session contains a **bell and a break screen every 25–50 minutes, by design** — the format manufactures
   exactly the breakpoints the ad system is looking for.
   *(This is my inference from the placement rules, not a YouTube statement — but it is consistent with a
   10-hour video reportedly carrying 15–20 breaks, and it costs us nothing to be right about.)*
3. **Pomodoro is where the search volume is** (415K/mo vs 4K/mo for "hourglass timer").

**Corollary on the hourglass:** "hourglass timer" gets 4,010 searches/month at competition 12.3 — too small
to build on, too cheap to ignore. So: **compete on `pomodoro timer` / `study timer` / `study with me`, and
let the hourglass be the thing that makes our thumbnail unmistakable in that crowded result list.** It is the
differentiator, not the query.

---

## 6. The catalogue matrix — what we actually publish

Timer Palette's catalogue is a combinatorial grid, and every cell is a query someone types:
`{work}/{break}` × `{noise colour}` × `{total length}` × `{noise | bell-only}`. Their proven winners cluster
hard: **50/10 and 25/5** on interval, **2-hour and 4-hour** on length.

**Sustain's grid uses the same two proven axes and replaces their third with the one they cannot copy:**

| Axis | Launch values | Why |
|---|---|---|
| Interval | **50/10, 25/5**, then 30/10, 60/10 | Where their views are |
| Length | **2 h, 4 h**, then 1 h, 6 h | 2h/4h carry most of their big hits |
| **Time of day** | **Sunrise · Golden Hour · Dusk · Midnight** | **Ours alone.** The sky actually moves. |
| Audio | Ocean bed · **bell-only** | Bell-only is a free second SKU (§7) |

The **time-of-day axis is the whole play**. Nobody else's timer changes over four hours, because nobody else
is capturing a live day cycle. It is simultaneously the aesthetic hook, the "not mass-produced" evidence, and
a reason to watch *ours* at 6am and again at midnight.

**Steal this one operational trick:** Timer Palette publishes each session **twice, seconds apart** — one
"with {colour} noise", one **"No Music 🔔 Bell Only"**. Same render, different audio track. The bell-only twin
pulls only ~10–30% of the views, but it costs **one extra encode and zero extra capture time**, and it owns
the "pomodoro timer no music" query (5,302/mo, competition 17.9). Free catalogue.

---

## 7. Titles, thumbnails, descriptions

**Title** — front-load the searched string, keep it rigid. Their proven formula, carrying our axis:

```
50/10 Pomodoro Timer 🌅 4-Hour Sunset Session | Study with Me for Deep Focus & ADHD
25/5 Pomodoro Timer 🌙 2-Hour Midnight Session | Study with Me for Deep Focus & ADHD
50/10 Pomodoro Timer | No Music 🔔 Bell Only | 4-Hour Sunrise Study With Me
```

`Pomodoro Timer`, `Study with Me`, `Deep Focus`, `ADHD` are all high-volume strings and all literally true of
the product. **ADHD is not a growth-hack here** — it is Timer Palette's stated audience, it is a real reason
people need external time structure, and it must stay honest.

**Thumbnail** — this is where we win the click, and it is the one place Sustain's existing work does all the
labour. The hourglass with real sand, at the actual sky colour of that session, plus the interval set large
and legible at 168px. Four sky variants = four visually distinct thumbnails from an otherwise identical grid,
which also happens to soften the "repetitive thumbnails" signal from §4.

**Description** — the funnel, per strategy §10:

```
Run this exact session yourself: https://<domain>/?mode=pomodoro&work=50&break=10&phase=sunset
Free. No sign-up. Works on any device.

00:00 Focus 1 · 50:00 Break · 1:00:00 Focus 2 ...
[originality declaration — see §4]
```

**Chapters are not optional.** Timestamps give the viewer a reason to scrub, and scrub points are structural
break candidates.

---

## 8. The path to monetization, and the bottleneck nobody expects

Thresholds ([YouTube Help](https://support.google.com/youtube/answer/72851?hl=en)):

- **Ad revenue share:** **1,000 subscribers + 4,000 valid public watch hours in the last 12 months.**
- Earlier **fan funding** access at 500 subs + 3,000 watch hours (expanded YPP, region-dependent).

Now do the arithmetic **for this format specifically**:

> 4,000 watch hours at a 2-hour average view duration = **2,000 views.** Even at a pessimistic 45-minute
> AVD it is ~5,300 views.

**The watch-hour threshold is nearly free for us.** A normal channel needs ~34,000 views at the 7-minute
platform average to bank 4,000 hours; we need a couple of thousand. This is a genuine structural advantage of
the format and it is worth naming.

**Which means the binding constraint is 1,000 subscribers** — and a utility converts to subscribers *badly*,
because people bookmark tools, they do not subscribe to them.

> **Subscribers are a GATE, not a growth metric** *(founder correction, 2026-08-03 — and it is right).*
> Subscribers earn nothing. Revenue is **RPM × views**, full stop, and the algorithm ranks each video on
> satisfaction and relevance rather than on how many subscribers the channel has. §13's data says it
> outright: Study Pomodoro pulls **98,246 views per video on 47,300 subs at +0.2% monthly sub growth**, and
> The Study Bud Hub does 94,703 avg views at **0%** sub growth. Chasing subscribers as a KPI is chasing the
> wrong number.
>
> **The single exception is the YPP gate: below 1,000 subscribers, views earn exactly $0.** So treat 1,000
> subs as a **one-time unlock, then stop thinking about it** — never as an ongoing target.

**Hence the one deliberate deviation from Timer Palette's playbook: a small Shorts track that exists only to
pick the lock, then gets dropped.** Timer Palette has zero Shorts. Shorts RPM is dismal and Shorts views do
**not** count toward the 4,000 long-form watch hours, so this earns nothing directly — that is fine, it is a
key, not an engine. A 20-second silent clip of the sand falling as the sky turns is genuinely arresting and
cuts from footage we already have. **~2 Shorts/week until 1,000 subs, then stop entirely** and put every
minute back into long-form, where the views (and therefore the money) actually are.

---

## 9. Honest revenue model

At Timer Palette's demonstrated **~$2.47 RPM**:

| Monthly views | Ad revenue / month |
|---|---|
| 100,000 | ~$250 |
| 500,000 | ~$1,235 |
| 1,300,000 *(Timer Palette today)* | ~$3,200 |
| 3,000,000 | ~$7,400 |

**Realistic trajectory**, given the §2 ignition curve and assuming we publish consistently from day one:

- **Months 0–3:** ~zero revenue, videos at hundreds of views. **This is the plan working, not failing.**
- **Months 4–6:** YPP thresholds cleared; first ignitions; **$0 → low hundreds/month.**
- **Months 7–12:** the library compounds; **$500–2,000/month** is a reasonable band if we hit the cadence.
- **Month 12+:** Timer Palette's ~$3K/month is the demonstrated ceiling **for a channel with nothing to
  sell.** Ours also carries the link — and the app/Plus conversions may well out-earn the AdSense.

**Do not model this as salary.** Model it as an asset that appreciates: 592 videos → $35K lifetime and still
compounding, built by one person with a render pipeline.

---

## 10. The 90-day plan

**Phase 0 — before the first upload (this week)**
1. ✅ **Decisions resolved (§12). Channel live as `@SustainTimer`.**
2. OBS: set the **Recording** tab per capture guide §3b (CQP 18, Hybrid MP4 / MKV, 1080p30), wire the
   **two audio tracks** per §6b, complete the Windows lock hardening in §7, then a **10-minute test capture**
   and scrub it for sky-gradient banding (§3c). **Confirm on that test whether the session bell is actually
   audible in the capture** — flagged as untested in §6b, and it decides whether the bell-only SKU works as
   designed or needs a post-mux.
3. Add the **originality declaration** (§4 — *our* wording, not Timer Palette's) to the channel description.
   Turn on **two-step verification** on the Google account (a hard YPP requirement). Link the site.
4. Capture **one** 2-hour 50/10 sunset session end-to-end, split it into its two SKUs, and publish. Learn the
   whole pipeline on a real upload before scaling it.

**Phase 1 — build the grid (weeks 2–6)**
- Cadence: **1 session/day → 2 uploads/day** (noise + bell-only twin). Sessions run unattended; the cost is
  wall-clock, not attention. Two 4-hour captures/day is 8 hours of machine time, not founder time.
- Work the grid systematically: fix time-of-day, sweep interval × length, then rotate the sky.
- **Never** re-upload a render. Every upload is a fresh capture (§4).

**Phase 2 — clear the gates (weeks 6–12)**
- Watch hours will arrive on their own (§8). **Push subscribers**: Shorts track, an end-card on the fade to
  black, and a tasteful brand mark on the break screen — the break screen is currently dead space and it is
  the *only* moment a focus viewer actually looks at the frame.
- Apply to YPP the moment both gates clear.
- **Measure, do not guess:** at week 12 pull YouTube Analytics for real RPM and real AVD and replace §9's
  modelled numbers with actuals.

**Phase 3 — read the data (month 4+)**
- Find which grid cells ignited. Double down on those axes; stop sweeping the dead ones.
- Only then consider a 24/7 Endless livestream — **as a subscriber/brand surface, never for revenue** (§1
  still holds for livestreams). `/stage` already supports Endless for exactly this.

---

## 11. Do / Don't, compressed

**Do**
- Publish on a fixed daily cadence, unattended, and let the library age.
- One video per real query. Functional variation only.
- Keep automatic mid-rolls **on** (auto + manual together tested **+5%** vs manual alone).
- Put the exact preset URL in every description. The video is the ad.
- Keep the OBS project files and captures — that is the originality evidence (§4).
- Answer early comments. Satisfaction and returns are now primary signals (§3).

**Don't**
- Don't judge the channel before month 6 (§2).
- Don't re-upload renders, use others' music, or buy engagement (§4).
- Don't stack manual mid-rolls every 8 minutes — interruptive slots now **earn less**, not more.
- Don't chase "hourglass timer" as a query (§5).
- Don't build a second render engine. The site is the studio.

---

## 12. Decisions — RESOLVED 2026-08-02

1. **Channel identity → branded Sustain. Already live: `@SustainTimer`.** Hourglass avatar, anime seascape
   banner, and the description already leads with *"Pomodoro timers, focus timers, study with me videos."*
   Keyword-aligned from day one. **One thing still owed on it: add the originality declaration from §4** —
   our version, not Timer Palette's.
2. **Audio → both, sequenced.**
   - **Phase 1 (now):** ship **bell-only + ocean bed**. Strictly inside §6.1.4, nothing to license, and the
     bell-only SKU already owns `pomodoro timer no music` (5,302/mo). Publishing starts immediately.
   - **Phase 2 (once the pipeline is proven on real uploads):** synthesise our **own brown / pink / white**
     noise beds. `brown noise for studying` alone is **199,658 searches/month** — this is the single largest
     traffic source in the niche and we currently cannot compete for it. Generated noise is a few lines of
     DSP, 100% ours, and carries **zero Content ID exposure**.
   - Both phases ride the **same captures**: noise beds become extra audio tracks, not extra recordings
     (capture guide §6b). Phase 2 costs no new capture time and can be applied retroactively to the phase-1
     back catalogue.
3. **Cadence → one capture a day** (~30/month) — *revised upward from every-other-day in the same session,
   and the roadmap is why.* The original reason for the slower rate was that titling and uploading do not
   automate. **They now do**: every row ships a finished title, a budget-fitted tag string, and a
   description with computed chapters, so per-video desk work collapses to *configure, upload, paste, tick*.
   Captures are unattended, so the machine absorbs the rest. **One capture = one video** — the bell-only
   twin (splitting one recording into two SKUs) was dropped on the founder's call; **no-music videos are
   their own rows**, keeping query coverage with zero post-processing.
   **Still half Timer Palette's rate** (they publish 2/day), so §2's ignition may land later than their
   ~5.5 months. The §2 curve punishes *inconsistency* far harder than rate — **a daily cadence that holds
   beats a daily cadence that stops in week three.**
4. **Domain → `sustaintimer.com`, secured (Hostinger).** This closes handoff blocker #1 — canonical, sitemap
   and robots already assumed exactly this. Cloudflare Pages deploy still needs `wrangler login`.

### The catalogue is now a written list

**`docs/youtube/video-roadmap.md` — Wave 1: 94 videos, every config decided, tickable** (regenerate with
`node docs/youtube/gen-roadmap.mjs`). Phases A–F, one row per capture, carrying mode/interval/duration/
breaks, light, sun&moon, numeral placement/fill/font/separator/colour, per-sound volumes and master, the
finished title, the budget-fitted tags, and a column for the video ID. Phase A also ships ready-to-paste
descriptions with **computed chapter timestamps**.

**The space is real and it is enormous.** Counting only genuine product differences — `interval (7) ×
duration (6) × time of day (9) × sound (16) × timer display (2)` — one theme holds **15,552 videos**
(12,096 Pomodoro/Custom + 1,728 Flow + 1,728 Endless). Multiply the cosmetic axes back in (placement 4 ×
fill 3 × font 2 × separator 3 × colour 6 = 432) and it is **6.7 million**. At one a day the full space is
**43 years**, so the catalogue is never "finished" — **the only question is which cells get captured
first**, and that ordering is the whole value of the list. **Wave 1 is a publish order through a reservoir,
not the catalogue.** Wave 2 gets written from Phase A–B Analytics rather than guessed now; `5 min` timer
display opens as a full parallel catalogue there.

**Two rules shape every wave:** **(a)** an axis earns a multiplication only if people search it —
placement/fill/font/separator have **zero** search volume, so they are **rotated** for variety at zero
catalogue cost; **(b)** multiplying by invisible axes is *literally* the inauthentic-content policy's
"minimal variation" wording — a **monetization risk, not just waste**. `Hover`/`Never` display values are
unusable in a recording (no mouse / hides the product); `Always` and `5 min` are the two real ones.

**Uniqueness is enforced, not assumed.** The generator throws on any repeated config tuple — and it caught a
genuine duplicate on first run (Phase E re-adding a bell config Phase A already held). The key includes every
axis, so Wave 2 automatically re-checks against everything already planned.

### Metadata contract (roadmap doc, "The metadata contract")

Founder's framing — *metadata should tell YouTube exactly whom to show this to* — is correct in outcome; the
mechanism is that YouTube **"pulls" per viewer** rather than testing on a cohort. Of its three signal groups
(Engagement / Satisfaction / **Relevance**), **only Relevance is ours to write**: title, description,
transcript, and on-screen text in the first seconds. Two decisions with real money attached: **Category =
Education** (brand-safe inventory, reportedly $5–15 RPM vs much lower for Music) and **Made for kids = No**
(marking it yes kills personalised ads — contextual pays **50–80% less** — and disables comments).

**The one honest exception to "an extra step never hurts":** broad, loosely-related keywords *cause* the
failure they are meant to prevent. `study music` on a silent timer buys a viewer who bounces, and the bounce
narrows distribution. **Precision beats volume.**

**Product opportunity surfaced:** relevance counts *on-screen text in the first few seconds*, and our lead-in
is a wordless 3-2-1 over a blurred scene, on a near-silent video with no transcript — so we hand YouTube less
relevance signal than a talking video, exactly when it matters most. Showing `50 / 10 · 4 HOURS · SUNSET`
during the lead-in would fix it honestly. **Founder call — it touches the `/stage` look.**

### Revised cadence plan (supersedes §10 Phase 1)

- **~15 captures/month.** Sessions run unattended; budget founder time for **uploads, titles, thumbnails and
  descriptions**, which is the part that does not automate.
- **Batch the desk work.** Capture on a rolling basis, then do titling/uploading in one weekly sitting —
  cheaper in attention than a daily context-switch, and YouTube does not care when the file was made.
- **Sweep the grid in a fixed order** so coverage stays even: hold time-of-day, sweep interval × length, then
  rotate the sky. Ad-hoc picking leaves query holes.
- **Publishing rhythm beats capture rhythm.** Schedule uploads to go out on a steady drip rather than in
  bursts — a channel that posts every other day reliably reads better to both viewers and the Subscriptions
  system than one that posts seven videos on a Sunday.

---

## 13. The competitive landscape (vidIQ, 2026-08-02)

Similar-channel scan around Timer Palette's niche. **The niche is actively growing, and small channels are
growing fastest** — which is the single most encouraging fact for a channel with zero videos:

| Channel | Subs | Subs +30d | Views +30d | Faceless |
|---|---|---|---|---|
| **Work Mode Audio** | 7,590 | **+54.3%** | **+99.2%** | ✅ |
| **Power Hour Focus** | 13,700 | **+37.0%** | +36.9% | |
| **Focus Room** | 19,700 | **+32.2%** | +33.4% | ✅ |
| **GooDuck Pomodoro** | 5,010 | **+22.8%** | +30.6% | ✅ |
| Milli Lofi Timer | 110,000 | +13.2% | +15.9% | |
| Study Pomodoro | 47,300 | +0.2% | +0.7% | |
| Chill Countdown Timers | 32,600 | +0.3% | +1.5% | |

**Three reads that change what we do:**

1. **Faceless is the norm here, not a handicap.** Four of the fastest risers are explicitly faceless. Our
   format needs no apology and no on-camera presence — ever.
2. **The subscriber bottleneck (§8) is confirmed in the data.** Study Pomodoro averages **98,246 views per
   video** against **47,300 subscribers and +0.2% monthly sub growth**. The Study Bud Hub: 94,703 avg views,
   **0%** sub growth. People use the tool and leave without subscribing — exactly the failure mode §8
   predicts, which is why the Shorts track exists purely as a sub pump.
3. **Entry is viable now.** Channels at 5–20K subs are compounding 20–55%/month. This is not a saturated
   category with the door closed; it is one where new entrants are currently winning.

**One adjacent audience worth noting:** *Chill Countdown Timers* (24.8M lifetime views) lists **"Classroom
Resources"** among its niches, and the keyword data backs it — `classroom timer` 6,986/mo, `timer for
classroom` 4,495/mo, plus a long tail of `N minute timer for classroom`. Teachers running timers on a
projector are a real segment our product already serves. **Not a Wave 1 priority** — noted for Wave 2.

## 14. The directory — where combinations come from

`tools/video-directory/index.html` — a single self-contained page (15 KB, no dependencies, no network) that
holds **every combination of every Setup control**.

**It never stores the space.** Each combination is a **mixed-radix index** decoded on demand, so the page
holds 13 axes and a few ticks, not a billion rows. Verified: index↔config round-trips exactly, the
closed-form validity counts match Monte-Carlo sampling to <0.2%, and filtered subspaces enumerate uniquely
with no scanning.

```
4 modes × 13 intervals × 9 durations × 7 times of day × 5 cycles × 2 sun&moon × 4 timer displays
      × 4 placements × 3 fills × 2 fonts × 3 separators × 6 colours × 16 sound sets

              905,748,480 combinations   (452,874,240 reachable in Setup · 226,437,120 recordable)
```

> **The real total is ~906 million, not 6.7M** — the earlier figure counted a smaller axis set. "Reachable"
> drops the pairings Setup cannot produce (it forces separator = *none* at *middle*/*ledge*);
> "recordable" further drops `hover` and `never` timer display.

**The loop is MONTHLY — one wave = one month = 30 videos at one a day:**

1. Filter the directory to the slice this month tests.
2. **Export next month →** picks the first 30 unmade, recordable matches and writes
   `wave-YYYY-MM.md`: a day-numbered table **plus the end-of-month review checklist**.
3. Shoot top-down, one row per day. Upload, tick each back by its ID.
4. **End of month: run the review.** Which axis value won? Low impressions (a relevance/targeting problem)
   or high impressions with low CTR (a thumbnail problem)? What is the *real* RPM? Subs per 1,000 views?
5. Set the filter to the winning slice. Export the next month. Repeat.

So `docs/youtube/video-roadmap.md` is simply months 1–3 drawn by hand; every month after comes out of the
directory, **aimed by data instead of guesswork**. Ticks persist in the browser and **export to JSON** — keep
a copy in the repo so the record survives a cleared cache.

> **The one discipline that makes the monthly review honest:** judge the **axis**, not the video. §2's curve
> means a 3-week-old upload at 400 views is *on plan*, so comparing this month's videos against last
> quarter's is meaningless. **Compare like-aged cohorts only.**

**Deploy** (needs interactive OAuth, so the founder runs it):

```bash
npx wrangler login
npx wrangler pages deploy tools/video-directory --project-name sustain-directory
```

Keep it a **separate Pages project** from `sustaintimer.com` — it is an internal tool, and it already carries
`noindex,nofollow`.

## 16. The title template — LOCKED 2026-08-03

Measured on the live SERP for `3 hour study with me pomodoro timer` (vidIQ, 2026-08-03). Every channel
that wins this niche runs **one rigid skeleton and varies one or two words per upload**:

| Channel | Views | Title | Variable |
|---|---:|---|---|
| Countdown Time | 687,672 / 472,688 / 436,770 | `{IV} Pomodoro Timer - 3 hour study \|\| No music - Study for dreams - Deep focus - Study timer` | interval ONLY |
| Timer Palette | 546,673 / 239,288 / 117,648 | `50/10 Pomodoro Timer with {Noise} 🎧 3-Hour Study with Me for Deep Focus & ADHD ✨` | noise ONLY |
| Mr. Tiny's Studio | 178,420 / 115,339 | `3-HOUR STUDY WITH ME \| {Time} Lofi \| Pomodoro timer 3x50 \| Study & Work \| Deep Focus \| Lofi {emoji}` | time of day |
| iCanStudy | 13,210,854 | `3-HOUR STUDY WITH ME \| Hyper Efficient, Doctor, Focus Music, Pomodoro 50-10` | — |

Both openings are proven at scale, so the opener is picked on volume: **study with me 2,525,198/mo**
beats **50/10 pomodoro 47,568/mo** by 53×, and leads.

### The locked skeleton

```
{N}-Hour Study With Me {emoji} {MODE PHRASE} for {BENEFIT} & ADHD | {Sound}, {Light}
```

Four slots move. Everything else is fixed forever. Mode phrase is one of three:

| Mode | Phrase | Targets |
|---|---|---|
| Pomodoro / Custom | `{IV} Pomodoro Timer for Deep Focus` | pomodoro timer 427,868 · {iv} pomodoro 47,568 · deep focus 887,738 |
| Bell-only twin | `{IV} Pomodoro Timer, No Music for Deep Focus` | pomodoro no music 9,661 **at competition 10.4** |
| Flow | `Deep Work Timer, No Breaks for Flow State` | deep work 654,229 · flow state 316,535 |

Emoji is tied to the sound, never decorative: 🌊 ocean · 🍃 land ambience · 🔔 bell-only.

### Three fixes over the video-#1 wording

1. **`Pomodoro 50/10` → `50/10 Pomodoro Timer`.** Word order is what exact-phrase matching sees. The
   old order matched **neither** `50/10 pomodoro` (47,568/mo) **nor** `pomodoro timer` (427,868/mo).
   Four words now carry both. This was the single biggest hole in the old title, and it applies
   retroactively — **video #1's title should be updated.**
2. **`Focus & ADHD` → `Deep Focus & ADHD`.** `deep focus` is 887,738/mo standing alone.
3. **One emoji.** Every top performer here uses one or two. In a column of identically-shaped titles it
   is the only glyph, which is what earns the eye in a sidebar.

Hard cap 100 characters, enforced by the generator; when a long sound name would breach it the **tail**
gives way, never the head — the sound is already in the description, the tags and the thumbnail.

## 17. Session mix — REBUILT 2026-08-03 on measured volume

Was 15 Pomodoro-only sessions at 1h/2h/4h. Now spans three modes and five durations:

| Duration | Sessions | Why |
|---|---:|---|
| 3 hours | 5 | `study with me 3 hours` **125,629/mo** — was missing entirely |
| 2 hours | 4 | `2 hour timer` 204,296/mo |
| 4 hours | 3 | `study with me 4 hours` 44,753/mo |
| 1 hour | 2 | `60 minute timer` 33,037/mo |
| 5 hours | 1 | `5 hours study with me` 14,310/mo |

Modes: **Pomodoro 8** (50/10, 25/5) · **Custom 4** (30/15, 40/10, 50/15, 60/20) · **Flow 3** (60/120/180m).

Flow earns its place on `deep work` (654,229) and `flow state` (316,535), and **no competitor in this
niche ships an unbroken block** — every one of them is a Pomodoro channel. Custom covers the long-block
schedules Pomodoro's fixed ratio cannot express.

**Flow ships without chapters.** One block yields two markers (Intro + Focus); YouTube requires three,
and the outro cannot be the third because recording stops 5 s into it, under the 10 s per-chapter
minimum. An unbroken session genuinely has no segments — inventing them would be dishonest metadata.

## 18. Sleep / ambience content — REJECTED for this channel, 2026-08-03

The volume is real and larger than our niche: `white noise` 2,267,059/mo · `sleep music` 1,941,376 ·
`deep sleep music` 1,242,148 · `nature sounds` 504,753. It was still the wrong move, on four grounds:

1. **Topic dilution.** YouTube builds a channel-level topic profile and uses it to decide who gets our
   next upload. A channel that is unambiguously "focus timer" is why a 157-subscriber channel can pull
   8,442 views. Splitting the signal between focus and sleep degrades targeting for **both**.
2. **Zero funnel value.** Sustain is a focus timer. A viewer who came to fall asleep will never install
   it. Every sleep view is a watch-hour with no downstream revenue — the opposite of §1's whole thesis.
3. **Competition is 2× ours.** Those terms sit at 55–65 competition against 25–35 in the timer niche.
   We would be entering the harder market with the weaker asset.
4. **Production cost is prohibitive.** Sleep content is 8–10 h. One capture would consume a full
   working day plus an overnight upload, against ~30 videos/month from the current list. And our
   ambience is four short loops, which an audience listening for eight hours will hear seam.

**Revisit trigger:** after YPP is cleared *and* the focus catalogue is self-sustaining, and then as a
**separate channel**, not this one. Sleep is a real business; it is not this business.

## 19. Batch-record and schedule — ADOPTED 2026-08-03

Record several sessions on a free day, upload all as **Private**, configure fully, then use YouTube's
native **Schedule** to release one per day. Correct on every axis that matters:

- **The algorithm sees the publish time, not the capture time.** There is no penalty, no signal, no
  difference. Consistency of *release* is what the system rewards, and scheduling delivers it perfectly.
- **It removes the only real failure mode.** §2's ignition curve says the library does not pay out
  until ~month 6. The one thing that reliably kills a channel before then is a missed run of uploads
  during a busy week. A month scheduled in advance makes that impossible.
- **Processing time stops being a risk.** HD/4K transcoding can take hours after upload; scheduling
  guarantees the video is fully processed long before it goes live, so no viewer ever gets the 360p
  first-impression that video #1 hit.
- **Metadata quality goes up.** Configuring five videos in one sitting with the directory open beats
  five rushed uploads.

Two constraints: capture is real-time, so a day of recording is bounded by the clock — a 3 h session
costs 3 h. Pair long captures with short ones. And **upload as Private, not Unlisted** — an Unlisted
video is live and accumulates views before its scheduled slot, which is what happened to video #1.

## 20. Chapters — root cause found and fixed, 2026-08-03

Video #1 (`IRTdF6rgjpQ`) shipped valid-looking timestamps that YouTube silently refused. Diagnosed by
comparing the rendered watch pages of four videos:

| Video | Length | `macroMarkersListItemRenderer` | Timestamps in description |
|---|---|---|---|
| iCanStudy `74cOUSKXMz0` | 10,303 s | **present** | 35 |
| Timer Palette `KNzl1LYrHtw` | 10,807 s | **present** | 30 |
| Countdown Time `EZEF0-gEJ0Q` | 10,835 s | absent | 0 (never added any) |
| **Sustain #1 `IRTdF6rgjpQ`** | 7,218 s | **absent** | **25** |

Ours were present and *rejected* — and Timer Palette proves a 3-hour timer video can carry chapters.

**Cause:** the list changed shape partway down. `ts()` was `h ? H:MM:SS : MM:SS`, so a 2-hour video
emitted `00:00`, `00:13`, `50:13`, then `1:00:13`, `1:50:13`. Two defects at once — a format switch
mid-list, and no leading zero on the hour. This survived the earlier `0:00` → `00:00` fix because that
one only padded the minutes.

**Fix:** always emit full zero-padded `HH:MM:SS`. Matches Timer Palette's working format exactly
(`00:00:00` / `00:50:00` / `01:00:00`). Asserted in the generator: all chapters across all 30 videos
now match `/^\d{2}:\d{2}:\d{2} \S/`.

**Session start moved to the countdown (founder's call, 2026-08-03).** `Focus 1` is now stamped at
10 s — where the 3-2-1 countdown begins — not 13 s where the engine fires. The viewer is already
working by "3", so those seconds belong to the session. This makes the Intro chapter exactly 10 s,
precisely YouTube's per-chapter minimum: legal, but with zero headroom. A `MIN_CHAPTER` assertion now
walks every gap in every video (including the last chapter against real video length, lead-in + session
+ the 5 s of outro /stage records) and refuses to emit below 10 s. Verified to fire.

**Second attempt, 2026-08-03.** Fixing the format alone did not revive chapters — the corrected block
went live (verified in the served description) and the progress bar stayed unsegmented. Two differences
from Timer Palette's working block remained, and both were changed:

1. **No `Intro` chapter.** It left a 10-second first gap, exactly YouTube's per-chapter minimum with
   zero headroom. Focus 1 now owns `00:00:00`, which is precisely what Timer Palette does — its first
   marker is FOCUS 1 at 00:00:00 and its smallest gap is ten *minutes*. The 13 s of card + countdown is
   absorbed into Focus 1: off by 13 s at the head of a 50-minute chapter, which no viewer will notice.
2. **Blank line after the final chapter.** The generator emitted a single newline, so the list ran
   straight into the `━━━` divider of the Upload-defaults block. Timer Palette's is surrounded by blank
   lines.

Also enforced: `MIN_CHAPTERS = 3`. A one-block Pomodoro yields two markers (Focus 1, Break 1), which
YouTube ignores — emitting them just reproduces the silent rejection. Below three, ship none. Result:
22 of 30 videos carry chapters (minimum 4 each); the 6 Flow sessions and 2 one-block hours carry none.

**Why it was invisible:** YouTube renders *any* timestamp as a clickable blue link, whether or not it
validates as a chapter. The description looked correct in every way while the progress bar stayed
unsegmented — there is no error message anywhere in Studio.

## 21. Numeral rules — LOCKED 2026-08-04

The directory used to cycle placement/fill/font/separator/colour off the ROW index. Two failures:

1. **A bell twin differed from its own session.** Rows are interleaved (session, twin), so the twin
   picked up the next index and came out a visually different video. A twin is the same session with
   the sound off; everything visible must be identical.
2. **It emitted combinations that look wrong**, because nothing encoded what actually looks good — only
   that no permutation repeated. Thirty considered videos beat thirty proofs of combinatorial coverage.

### The rules

| Setting | Rule |
|---|---|
| **Timer display** | **Always.** Never hover / 5 min / never. |
| **Separator** | `middle` and `ledge` → **none, ever**. `horizon` and `top` → colon or dot. |
| **Fill** | solid or glass only. **Never outline.** |
| **Colour** | white or charcoal only. |

**Timer display is the dangerous one:** Setup defaults `timershow` to `hover`, so a session recorded
without explicitly setting Always will have the numbers fade out mid-video.

**Charcoal `#20242e` is the palette's black** — the swatch row is White / Ivory / Gold / Sky / Charcoal,
with no pure black. Colour is assigned by legibility, not variety: charcoal on the bright skies
(midday, sunrise), white on everything dim.

Only the six permitted `(placement, separator)` pairs can be generated at all — an illegal pair has no
representation in the source. Fill phase flips each time the placement cycle wraps, because fill has
period 2 against placement's period 6: a plain `si % 2` locks them in phase forever and every `middle`
comes out solid, every `top` glass. That in-phase artifact is exactly the mechanical look the rules
exist to prevent.

All of it is **asserted after generation**, not assumed — visibility, fill, colour, both separator
rules, and full twin parity across `numerals`, `lightSetup`, `mode`, `interval`, `blocks`, `duration`
and `setup`. Every one of these has shipped wrong once already.

## 22. The reservoir under the rules — 746,496 videos

| Dimension | Count | What varies |
|---|---:|---|
| Look | **48** | 6 legal (placement, separator) pairs x 2 fills x 2 fonts x 2 colours |
| Sound | **16** | 15 non-empty mixes of ocean/sand/breeze/birds + bell-only |
| Sky | **6** | pre-dawn, sunrise, midday, sunset, twilight, midnight |
| Session | **162** | 91 Pomodoro + 11 Flow + 60 Custom, under >=25/5 and round-hour |
| **Total** | **746,496** | |

**As shipped: 373,248**, because colour is bound to the sky for legibility rather than left free.

The rules *shrink* the space and that is the point. Unconstrained the look space is 4 placements x 3
separators x 3 fills x 2 fonts x 5 colours = 360; the rules cut it to 48, and every survivor is
publishable. Sessions alone, ignoring look entirely, still give **15,552** genuinely distinct videos.

**Combination count is a ceiling, not a plan.** 746,496 is 2,045 years at one a day. The binding
constraints are elsewhere: capture is real-time (a 3-hour video costs 3 hours, so 1-2 recordings a day),
and per section 4 a large stock of near-identical permutations is a *liability* under the
inauthentic-content policy, not an asset. This is why the monthly 15 are chosen against measured search
volume rather than drawn from this space at random.

## 15. Sources

- [YouTube Partner Program overview & eligibility](https://support.google.com/youtube/answer/72851?hl=en)
- [YouTube channel monetization policies (inauthentic / reused content)](https://support.google.com/youtube/answer/1311392?hl=en)
- [Manage mid-roll ad breaks in long videos](https://support.google.com/youtube/answer/6175006?hl=en)
- [Mid-roll ads updates explained — YouTube Blog](https://blog.youtube/creator-and-artist-stories/mid-roll-ads-updates-explained/)
- [YouTube details changes to mid-roll ads, May 12 2025 — Search Engine Journal](https://www.searchenginejournal.com/youtube-details-changes-coming-to-mid-roll-ads-on-May-12/540924/)
- [YouTube clarifies monetization rules around inauthentic content — Social Media Today](https://www.socialmediatoday.com/news/youtube-clarifies-monetization-update-inauthentic-repeated-content/752892/)
- [How the YouTube algorithm works in 2026 — vidIQ](https://vidiq.com/blog/post/understanding-youtube-algorithm/)
- [Viewer satisfaction replaces watch time, 2026 — OutlierKit](https://outlierkit.com/resources/youtube-viewer-satisfaction-algorithm-2026/)
- [Why channels get demonetized: inauthentic content explained](https://ytstudiodesktop.com/blog/youtube-inauthentic-content-policy-demonetization)
- [Ambient video monetization / AVD in the niche](https://medium.com/@twistszymon/make-money-with-ambient-videos-side-hustle-8054438caee2)
- Channel/video/keyword data: **vidIQ**, pulled 2026-08-02 (Timer Palette `UCCT_uvQA3sljsfI7XySXTVQ`;
  video `Nc40WbWz8CE` monthly history; keyword volumes for `pomodoro timer`, `hourglass timer`).
