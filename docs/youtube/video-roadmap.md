# Sustain YouTube — video roadmap

**Channel:** Sustain · `@SustainTimer` · **Domain:** `sustaintimer.com` (secured, Hostinger)
**Theme:** Seascape *(the only one — the theme selector is disabled, "more worlds coming", so this whole
list is one theme's catalogue)*
**Cadence:** one capture a day (~30/month) · **Strategy:**
`docs/superpowers/specs/2026-08-02-youtube-channel-strategy-design.md` · **Capture:**
`docs/obs-stage-streaming-guide.md`

> **Wave 1: 94 videos · one capture = one video · ~3.1 months at one a day** — drawn from a space of **15,552 per theme**
> (see *The full combinatorial space* below; this list is a publish **order**, not the whole catalogue).
> No splitting, no muxing, no editing. Configure the row, press Begin, upload the file, tick the box.

---

## How to use this

1. Take the next unticked row.
2. Set **every** column on the real Setup screen at `/stage` — the row is fully decided, nothing is left to
   judgement at capture time.
3. Press **Begin**. It fullscreens, counts 3-2-1, records itself, and stops itself on the fade to black.
4. Upload the file as-is. Paste the **Title**, the **Keyword head + the standing tag block**, and the
   description from the matching block below.
5. **Upload as UNLISTED.** YouTube processes every upload in low quality first and only builds the HD
   renditions afterwards — hours later on a 2-hour file (Google's own example: a 60-minute video can take
   up to 4 hours). Publishing before that finishes means your first viewers judge a 360p version of a
   channel whose entire appeal is visual, and those first impressions are exactly what the algorithm
   reads. Check the player's gear menu; when **1080p** is listed, switch the video to Public.
6. Tick `☐ → ☑` and drop the YouTube video ID in the last column.

**No-music videos are their own rows** (`…_bell`, audio column reads *ALL sounds OFF*), not a second export of
an existing capture. `pomodoro timer no music` is a real query (5,302/mo) and it deserves a real capture —
this keeps one row = one file = one upload with zero post-processing.

---

## The full combinatorial space — Seascape alone

Yes — understood, and the space is **larger than "hundreds or thousands."** Counting only the axes that are
real product differences (`duration × time of day × sound × timer display`, per interval config, per mode):

| Axis | Count | Values |
|---|---|---|
| Interval config | **7** | 15/5, 25/5, 30/5, 30/10, 45/15, 50/10, 60/10, 90/15 … (any w/b is possible) |
| Duration | **6** | 1, 2, 3, 4, 6, 8 h |
| Time of day | **9** | 6 held lights + 3 moving sequences |
| Sound | **16** | 4 singles + 6 pairs + 4 triplets + all-four + **bell-only** |
| Timer display | **2** | Always · 5 min *(Hover/Never are unusable in a recording — see below)* |

```
Pomodoro / Custom :  7 × 6 × 9 × 16 × 2  =  12,096
Flow (no interval):      6 × 9 × 16 × 2  =   1,728
Endless           :      6 × 9 × 16 × 2  =   1,728
                                            ───────
        ONE THEME                            15,552 videos
```

**15,552 per theme** — and each new world multiplies it again. If the cosmetic axes were multiplied too
(placement 4 × fill 3 × font 2 × separator 3 × colour 6 = **432**), the space is **6.7 million**.

**So the list below is not a claim that only 94 combinations exist. It is Wave 1 — a publish order through a
reservoir of 15,552.** At one capture a day the whole space is **43 years**, so the catalogue will
never be "finished"; the only question that matters is **which cells get captured first**. That ordering is
the actual work, and it is what the phases encode.

### How the reservoir gets drawn down

| | Draws | Selection rule |
|---|---|---|
| **Wave 1** *(below)* | 94 | Highest-volume intervals × best lights; one axis isolated per phase |
| Wave 2 | ~90 | Whatever Phase A–B Analytics say actually ignited — **written from data, not guessed now** |
| Wave 3+ | ∞ | Fill the winning slice densely; abandon dead slices entirely |

**Never sweep the space uniformly.** Roughly **50 of Timer Palette's 592 videos carry ~85% of their views**;
the reservoir is worth having, but only a thin slice of it will ever pay. Wave 1 exists to find that slice.

### Two rules that shape every wave

The second matters more than the arithmetic:

**1. An axis earns a multiplication only if people search it.** `50/10 pomodoro timer`, `4 hour study timer`
and `sunset study with me` are strings humans type. **`pomodoro timer with numerals at the ledge` is not.**
Placement, fill, font and separator have **zero search volume** — a capture spent on each is a capture spent
on a query that does not exist.

**2. Multiplying by invisible axes is the exact thing that gets channels demonetized.** YouTube's
**inauthentic content** policy names *"similar or repetitive content with… minimal variation."* Fifty videos
differing only in where the numerals sit **is that sentence.** The axis that costs nothing to produce is
precisely the axis that makes a library look mass-produced. That is a monetization risk, not merely waste.

### Catalogue axes — these multiply (they are queries)

| Axis | Values in play |
|---|---|
| Interval | 50/10, 25/5, 30/10, 60/10, 15/5, 90/15, 45/15 |
| Duration | 1, 2, 3, 4, 6, 8 h |
| **Light** | 6 held phases + 3 moving sequences — **ours alone** |
| Sound | 4 singles, 6 pairs, 4 triplets, all four, bell-only |
| Mode | Pomodoro (primary), Flow, Custom, Endless |

### Rotation axes — these NEVER multiply (they are style)

`placement` · `numeral fill` · `font` · `separator` · `colour`

They are **pre-cycled across the list** so the library looks varied rather than templated — which actively
*helps* against the repetitive-thumbnail signal — at **zero** catalogue cost. They are already filled in per
row; just copy them.

> **Colour is chosen per light, not rotated blindly.** Charcoal numerals on a midnight sky are invisible, so
> each light carries only its legible options — and the three **moving** sequences (which cross dark *and*
> bright skies) are restricted to Ivory/Gold, the only values readable the whole way through.

> **Timer display is a real axis — but only two of its four values are.** `Hover` needs mouse movement that
> never happens in a recording, and `Never` hides the product entirely, so both produce a broken video rather
> than a variant. That leaves **`Always`** and **`5 min`** (surfaces briefly, fades, repeats) — a genuinely
> different viewing experience, and the ×2 already counted in the space above. **Wave 1 is all `Always`**, to
> isolate every other axis first; `5 min` opens as a full parallel catalogue in Wave 2 once there is data
> saying which cells deserve it.

### Naming — the ID is the filename

`P50-10_4h_sunset_ocn` = **P**omodoro **50/10**, **4 h**, **sunset**, **ocean**. Use it for the capture and
the thumbnail (`P50-10_4h_sunset_ocn.mkv`, `…_thumb.png`). One list, one convention — 94 near-empty folders
would each hold the handful of fields a table row already holds.

---

## ⚠️ Two things found in the code while building this

**1. The preset link in every description cannot be specific yet.** The strategy has each description linking
the *exact* preset that produced the video — the whole *"the video is the ad"* half of the thesis. But
`/stage` reads only `record=1` and `stopstream=1`, and **nothing anywhere reads session config from the URL**
(`URLSearchParams` appears in three places, none of them config). Config lives in `localStorage.cfg`, written
by the Setup screen. **So every description below links the bare `https://sustaintimer.com`** — correct and
usable, just not deep-linked. Building a param→cfg reader is small and worth doing *before* the catalogue
grows, because descriptions are painful to retrofit across 94 videos.

**2. Master spec §18.7 is stale.** It lists `/stage` params `record / flow / loop / phase / timer`. Only
`record` and `stopstream` exist; the `eabfb05` rewrite ("`/stage` runs the real Setup") replaced the rest and
the spec was never updated.

---

## Tags — the budget, and what the research actually says

**Your Upload defaults already apply to every video** (24 tags, **353 of YouTube's 500-character** tag
field). So the `Extra tags` column is sized to the **147 characters that remain** — every row is
pre-generated to fit, with its exact length shown. Paste it after the defaults; do not retype the defaults.

**First, the honest part: tags barely matter.** YouTube's own documentation says tags *"play a minimal role
in overall discovery,"* mainly correcting misspellings and clarifying ambiguity, and the Creator Liaison has
called them a very low-weight signal next to title, description and on-screen/spoken content. The standard
advice is **5–8 tags, then stop**. Your title and thumbnail are worth **10–20×** more — that is where the
effort belongs, and it is why every row here ships a finished title.

**So why bother at all?** Because of the one thing a tag can carry that an English title cannot: **another
language.** I pulled the actual tags from Timer Palette's biggest videos, and the pattern is unmistakable —
their 1.34M-view video carries **Japanese, Hindi, Spanish, Arabic, Portuguese, French, Korean and Indonesian**
tags alongside the English ones, on an English-titled video:

> `ポモドーロタイマー` · `अध्ययन_टाइमर` · `Temporizador de estudio` · `ضجيج وردي` · `ruído rosa` ·
> `bruit rose` · `핑크 노이즈` · `derau merah muda` · `timer belajar`

That is not decoration — it is aimed at where the volume is. `ポモドーロタイマー` alone is **272,392
searches/month**, and the top-5 markets for `pomodoro timer` are US 20%, **India 12.8%**, **Japan 6.8%**,
Canada 6%, UK 4%. For `study with me`, **Vietnam is #1 at 20%**. So each row rotates in **one** non-English
term; across the catalogue that covers eight languages without bloating any single video.

> **Caveat, stated plainly:** Timer Palette does this *and* succeeds, but tags being low-weight means the
> tags are unlikely to be *why*. Treat the multilingual rotation as cheap upside, not as a growth lever.

**The other patterns worth copying from their tags:**

- **Interval in three spellings** — `50/10 pomodoro`, `50 10 pomodoro`, `50 minute pomodoro`. Cheap, and it
  is exactly the misspelling/ambiguity job tags are actually good at.
- **Duration as a bare timer query.** `2 hour timer` is **204,296/mo** on its own — far bigger than
  `2 hour study timer` (4,139/mo). Every row carries the bare form.
- **They tag their own channel ID as the first tag.** Included in their data; not replicated here, since it
  is folklore rather than anything YouTube documents.

## The description boilerplate

`{{BOILERPLATE}}` in every block below expands to:

```
🕰 Sustain is a free focus timer with a living hourglass — real sand, and a sky that moves
   with your session. No sign-up, no ads, works on any device.

⚠️ Every video on this channel is a real-time recording of Sustain's own timer — an original
   render engine with simulated sand physics and a live day/night cycle. Nothing here is a
   loop or a slideshow, and no session is ever recorded twice.

#pomodoro #studywithme #focustimer #adhd #deepwork
```

> That middle paragraph is the **compliance artefact** (strategy §4). Do **not** copy Timer Palette's
> *"AI was not used"* line — our plates *are* AI stills, so it would be false. Every clause above is
> verifiable against the repo, which is what an appeal actually needs.

---

## The metadata contract — telling YouTube exactly who this is for

**Your reasoning is right, with one correction to the mechanism.** There is no discrete "test audience" that
YouTube shows a video to and then judges. Per YouTube's Director of Growth & Discovery, the system **"pulls"
rather than "pushes"** — it assembles candidates for *each individual viewer* at the moment they open the
app. But the consequence you described is exactly right: **poor matching → low CTR and low retention → the
video stops being surfaced.** The video does get capped; it just isn't a scheduled exam.

The algorithm scores three signal groups, and **only one of them is ours to write**:

| Signal group | What it contains | Can metadata touch it? |
|---|---|---|
| Engagement | CTR, watch time | Only via title + thumbnail |
| Satisfaction | Surveys, repeat views, *Not Interested* | No — earned after the click |
| **Relevance** | **Title, description, transcript, on-screen text in the first few seconds** | **Yes — this is the whole lever** |

**So "optimise everything" is right, with one real exception.** Broad, loosely-related keywords do not widen
reach — they **actively cause the failure you are trying to avoid.** Tagging `study music` or `lofi` on a
silent bell-only timer invites exactly the viewer who wanted music, who bounces in 20 seconds. That bounce is
read as *this video disappoints this audience*, and distribution narrows. **Precision beats volume**, and
adding a keyword you cannot honestly satisfy is the one extra step that does hurt.

### Per-video settings — set every one of these, every upload

| Setting | Value | Why it matters |
|---|---|---|
| **Category** | **Education** | Real revenue lever: education inventory is treated as brand-safe and reportedly runs **$5–15 RPM** against much lower rates for Music. Our video genuinely is a study tool — this is accurate, not gaming. Revisit against real Analytics after Phase A. |
| **Made for kids** | **No — not made for kids** | **The single most expensive switch on the page.** Marked "yes": personalised ads off, comments disabled, and contextual-only ads pay **50–80% less per impression**. A calm animated hourglass is exactly the kind of video someone sets wrong by accident. |
| **Altered content / AI disclosure** | **No** | The capture is a real-time recording of our own renderer. Nothing synthetic is being passed off as real. |
| Video language | English | Drives caption + locale matching |
| Caption track | Upload/auto | The transcript is a **named relevance input**. A silent video has none — so the description and on-screen text carry that whole load. |
| Hashtags | `#pomodoro #studywithme #focustimer` | The first three render above the title |
| **Playlists** | **One per interval, one per light** | **Session contribution is the leading long-form signal in 2026.** Playlists are the cheapest way to extend a session, and this catalogue is unusually suited to them — someone who liked a 50/10 wants the next 50/10. |
| Comments | **On** | Satisfaction and returns are primary ranking signals now; comments are also where "please make a 3-hour version" arrives |
| End screen | Last 20 s | The fade-to-black is dead space — put the next session there |
| Publish time | Evening IST / morning US | India and the US are top-2 markets for these queries |

### One product opportunity this research surfaced

Relevance explicitly includes **"text on screen in the first few seconds."** Our first seconds are a blurred
scene and a 3-2-1 countdown — **no text at all**, and no transcript either, since the video is near-silent.
That means we hand YouTube *less* relevance signal than a talking video does, precisely at the moment it
matters most.

Cheap fix worth considering: show the session's own configuration during the lead-in — `50 / 10 · 4 HOURS ·
SUNSET` — for the two seconds before the bell. It is honest, it is genuinely useful to a viewer who just
clicked, and it puts the video's exact subject on screen in the first frames. **Founder call**, since it
touches the `/stage` lead-in look.

---

## The list

### MONTH 1 — chosen from search volume, not taste

Every row is **Custom mode**, the only mode that lands on an exact round hour. Titles lead with **study with me** (2,533,520/mo — six times `pomodoro timer`) and carry the duration, because `2 hour timer` alone is **204,296/mo**. **Midnight earns its slots on data**, not vibes: `study with me late night` is 6,242/mo.

**30 videos** (one capture each) · ~1.0 months at one capture a day

| ✓ | # | ID | Mode · timer · length · breaks | Time of day · Sun&moon | Numerals: show · place · fill · font · sep · colour | Audio (per-sound · master) | Title | Extra tags | Video ID |
|---|---|---|---|---|---|---|---|---|---|
| ☐ | 01 | `P50-10x2h_sunset_ocn` | **Pomodoro** · focus **50m** · break **10m** · blocks **2** → 2 hours · 2 breaks | Time of day → Sunset · Show | Always · middle · solid · Serif · none · White #ffffff | Ocean 100 — master 100 | 2-Hour Study With Me 🌊 50/10 Pomodoro Timer for Deep Focus & ADHD \| Ocean Waves & Sunset | 50/10 pomodoro, 50 minute pomodoro, pomodoro technique, 2 hour timer, study with me 2 hours, sunset ambience, pomodoro adhd, अध्ययन टाइमर **(137 ch)** | |
| ☐ | 02 | `P50-10x2h_sunset_bell` | **Pomodoro** · focus **50m** · break **10m** · blocks **2** → 2 hours · 2 breaks | Time of day → Sunset · Show | Always · middle · solid · Serif · none · White #ffffff | ALL sounds OFF — bell only | 2-Hour Study With Me 🔔 50/10 Pomodoro Timer, No Music for Deep Focus & ADHD \| Sunset | 50/10 pomodoro, 50 minute pomodoro, pomodoro technique, 2 hour timer, study with me 2 hours, sunset ambience, pomodoro adhd, pomodoro no music, silent study timer, temporizador de estudio **(187 ch)** | |
| ☐ | 03 | `P50-10x3h_midnight_ocn-brz` | **Pomodoro** · focus **50m** · break **10m** · blocks **3** → 3 hours · 3 breaks | Time of day → Midnight · Show | Always · horizon · glass · Serif · colon · White #ffffff | Ocean 100 · Shore breeze 55 — master 100 | 3-Hour Study With Me 🌊 50/10 Pomodoro Timer for Deep Focus & ADHD \| Ocean & Breeze, Midnight | 50/10 pomodoro, 50 minute pomodoro, pomodoro technique, 3 hour timer, study with me 3 hours, midnight ambience, pomodoro adhd, مؤقت للدراسة **(139 ch)** | |
| ☐ | 04 | `P50-10x3h_midnight_bell` | **Pomodoro** · focus **50m** · break **10m** · blocks **3** → 3 hours · 3 breaks | Time of day → Midnight · Show | Always · horizon · glass · Serif · colon · White #ffffff | ALL sounds OFF — bell only | 3-Hour Study With Me 🔔 50/10 Pomodoro Timer, No Music for Deep Focus & ADHD \| Midnight | 50/10 pomodoro, 50 minute pomodoro, pomodoro technique, 3 hour timer, study with me 3 hours, midnight ambience, pomodoro adhd, pomodoro no music, silent study timer, temporizador de estudo **(188 ch)** | |
| ☐ | 05 | `P50-10x4h_sunrise_ocn-brd` | **Pomodoro** · focus **50m** · break **10m** · blocks **4** → 4 hours · 4 breaks | Time of day → Sunrise · Show | Always · ledge · solid · Jost · none · Charcoal #20242e | Ocean 100 · Seabirds 55 — master 100 | 4-Hour Study With Me 🌊 50/10 Pomodoro Timer for Deep Focus & ADHD \| Ocean & Seabirds, Sunrise | 50/10 pomodoro, 50 minute pomodoro, pomodoro technique, 4 hour timer, study with me 4 hours, sunrise ambience, pomodoro adhd, 핑크 노이즈 공부 **(135 ch)** | |
| ☐ | 06 | `P50-10x4h_sunrise_bell` | **Pomodoro** · focus **50m** · break **10m** · blocks **4** → 4 hours · 4 breaks | Time of day → Sunrise · Show | Always · ledge · solid · Jost · none · Charcoal #20242e | ALL sounds OFF — bell only | 4-Hour Study With Me 🔔 50/10 Pomodoro Timer, No Music for Deep Focus & ADHD \| Sunrise | 50/10 pomodoro, 50 minute pomodoro, pomodoro technique, 4 hour timer, study with me 4 hours, sunrise ambience, pomodoro adhd, pomodoro no music, silent study timer, timer belajar **(178 ch)** | |
| ☐ | 07 | `P50-10x1h_twilight_snd-brz` | **Pomodoro** · focus **50m** · break **10m** · blocks **1** → 1 hour · 1 breaks | Time of day → Twilight · Show | Always · top · glass · Jost · dot · White #ffffff | Sand 100 · Shore breeze 55 — master 100 | 1-Hour Study With Me 🍃 50/10 Pomodoro Timer for Deep Focus & ADHD \| Sand & Breeze, Twilight | 50/10 pomodoro, 50 minute pomodoro, pomodoro technique, 1 hour timer, study with me 1 hours, twilight ambience, pomodoro adhd, çalışma zamanlayıcısı **(148 ch)** | |
| ☐ | 08 | `P50-10x1h_twilight_bell` | **Pomodoro** · focus **50m** · break **10m** · blocks **1** → 1 hour · 1 breaks | Time of day → Twilight · Show | Always · top · glass · Jost · dot · White #ffffff | ALL sounds OFF — bell only | 1-Hour Study With Me 🔔 50/10 Pomodoro Timer, No Music for Deep Focus & ADHD \| Twilight | 50/10 pomodoro, 50 minute pomodoro, pomodoro technique, 1 hour timer, study with me 1 hours, twilight ambience, pomodoro adhd, pomodoro no music, silent study timer, ポモドーロタイマー **(175 ch)** | |
| ☐ | 09 | `P50-10x3h_sunset_ocn-snd-brd` | **Pomodoro** · focus **50m** · break **10m** · blocks **3** → 3 hours · 3 breaks | Time of day → Sunset · Show | Always · horizon · solid · Serif · dot · White #ffffff | Ocean 100 · Sand 55 · Seabirds 40 — master 90 | 3-Hour Study With Me 🌊 50/10 Pomodoro Timer for Deep Focus & ADHD \| Ocean, Sand & Seabirds, Sunset | 50/10 pomodoro, 50 minute pomodoro, pomodoro technique, 3 hour timer, study with me 3 hours, sunset ambience, pomodoro adhd, अध्ययन टाइमर **(137 ch)** | |
| ☐ | 10 | `P50-10x3h_sunset_bell` | **Pomodoro** · focus **50m** · break **10m** · blocks **3** → 3 hours · 3 breaks | Time of day → Sunset · Show | Always · horizon · solid · Serif · dot · White #ffffff | ALL sounds OFF — bell only | 3-Hour Study With Me 🔔 50/10 Pomodoro Timer, No Music for Deep Focus & ADHD \| Sunset | 50/10 pomodoro, 50 minute pomodoro, pomodoro technique, 3 hour timer, study with me 3 hours, sunset ambience, pomodoro adhd, pomodoro no music, silent study timer, temporizador de estudio **(187 ch)** | |
| ☐ | 11 | `P25-5x2h_midnight_ocn` | **Pomodoro** · focus **25m** · break **5m** · blocks **4** → 2 hours · 4 breaks | Time of day → Midnight · Show | Always · top · glass · Serif · colon · White #ffffff | Ocean 100 — master 100 | 2-Hour Study With Me 🌊 25/5 Pomodoro Timer for Deep Focus & ADHD \| Ocean Waves & Midnight | 25/5 pomodoro, 25 minute pomodoro, pomodoro technique, 2 hour timer, study with me 2 hours, midnight ambience, pomodoro adhd, مؤقت للدراسة **(138 ch)** | |
| ☐ | 12 | `P25-5x2h_midnight_bell` | **Pomodoro** · focus **25m** · break **5m** · blocks **4** → 2 hours · 4 breaks | Time of day → Midnight · Show | Always · top · glass · Serif · colon · White #ffffff | ALL sounds OFF — bell only | 2-Hour Study With Me 🔔 25/5 Pomodoro Timer, No Music for Deep Focus & ADHD \| Midnight | 25/5 pomodoro, 25 minute pomodoro, pomodoro technique, 2 hour timer, study with me 2 hours, midnight ambience, pomodoro adhd, pomodoro no music, silent study timer, temporizador de estudo **(187 ch)** | |
| ☐ | 13 | `P25-5x3h_sunset_ocn-snd` | **Pomodoro** · focus **25m** · break **5m** · blocks **6** → 3 hours · 6 breaks | Time of day → Sunset · Show | Always · middle · glass · Jost · none · White #ffffff | Ocean 100 · Sand 55 — master 100 | 3-Hour Study With Me 🌊 25/5 Pomodoro Timer for Deep Focus & ADHD \| Ocean & Sand, Sunset | 25/5 pomodoro, 25 minute pomodoro, pomodoro technique, 3 hour timer, study with me 3 hours, sunset ambience, pomodoro adhd, 핑크 노이즈 공부 **(133 ch)** | |
| ☐ | 14 | `P25-5x3h_sunset_bell` | **Pomodoro** · focus **25m** · break **5m** · blocks **6** → 3 hours · 6 breaks | Time of day → Sunset · Show | Always · middle · glass · Jost · none · White #ffffff | ALL sounds OFF — bell only | 3-Hour Study With Me 🔔 25/5 Pomodoro Timer, No Music for Deep Focus & ADHD \| Sunset | 25/5 pomodoro, 25 minute pomodoro, pomodoro technique, 3 hour timer, study with me 3 hours, sunset ambience, pomodoro adhd, pomodoro no music, silent study timer, timer belajar **(176 ch)** | |
| ☐ | 15 | `P25-5x4h_midday_brz-brd` | **Pomodoro** · focus **25m** · break **5m** · blocks **8** → 4 hours · 8 breaks | Time of day → Midday · Show | Always · horizon · solid · Jost · colon · Charcoal #20242e | Shore breeze 100 · Seabirds 55 — master 100 | 4-Hour Study With Me 🍃 25/5 Pomodoro Timer for Deep Focus & ADHD \| Breeze & Seabirds, Midday | 25/5 pomodoro, 25 minute pomodoro, pomodoro technique, 4 hour timer, study with me 4 hours, midday ambience, pomodoro adhd, çalışma zamanlayıcısı **(145 ch)** | |
| ☐ | 16 | `P25-5x4h_midday_bell` | **Pomodoro** · focus **25m** · break **5m** · blocks **8** → 4 hours · 8 breaks | Time of day → Midday · Show | Always · horizon · solid · Jost · colon · Charcoal #20242e | ALL sounds OFF — bell only | 4-Hour Study With Me 🔔 25/5 Pomodoro Timer, No Music for Deep Focus & ADHD \| Midday | 25/5 pomodoro, 25 minute pomodoro, pomodoro technique, 4 hour timer, study with me 4 hours, midday ambience, pomodoro adhd, pomodoro no music, silent study timer, ポモドーロタイマー **(172 ch)** | |
| ☐ | 17 | `F60mx1h_sunrise_ocn-brd` | **Flow** · flow length **60m** → 1 hour · 0 breaks | Time of day → Sunrise · Show | Always · ledge · glass · Serif · none · Charcoal #20242e | Ocean 100 · Seabirds 55 — master 100 | 1-Hour Study With Me 🌊 Deep Work Timer, No Breaks for Flow State & ADHD \| Ocean & Seabirds, Sunrise | deep work, flow state, deep work timer, study with me no break, 1 hour timer, study with me 1 hours, sunrise ambience, pomodoro adhd, अध्ययन टाइमर **(146 ch)** | |
| ☐ | 18 | `F60mx1h_sunrise_bell` | **Flow** · flow length **60m** → 1 hour · 0 breaks | Time of day → Sunrise · Show | Always · ledge · glass · Serif · none · Charcoal #20242e | ALL sounds OFF — bell only | 1-Hour Study With Me 🔔 Deep Work Timer, No Breaks for Flow State & ADHD \| Sunrise | deep work, flow state, deep work timer, study with me no break, 1 hour timer, study with me 1 hours, sunrise ambience, pomodoro adhd, pomodoro no music, silent study timer, temporizador de estudio **(196 ch)** | |
| ☐ | 19 | `F120mx2h_midnight_snd` | **Flow** · flow length **120m** → 2 hours · 0 breaks | Time of day → Midnight · Show | Always · top · solid · Serif · dot · White #ffffff | Sand 100 — master 100 | 2-Hour Study With Me 🍃 Deep Work Timer, No Breaks for Flow State & ADHD \| Falling Sand & Midnight | deep work, flow state, deep work timer, study with me no break, 2 hour timer, study with me 2 hours, midnight ambience, pomodoro adhd, مؤقت للدراسة **(147 ch)** | |
| ☐ | 20 | `F120mx2h_midnight_bell` | **Flow** · flow length **120m** → 2 hours · 0 breaks | Time of day → Midnight · Show | Always · top · solid · Serif · dot · White #ffffff | ALL sounds OFF — bell only | 2-Hour Study With Me 🔔 Deep Work Timer, No Breaks for Flow State & ADHD \| Midnight | deep work, flow state, deep work timer, study with me no break, 2 hour timer, study with me 2 hours, midnight ambience, pomodoro adhd, pomodoro no music, silent study timer, temporizador de estudo **(196 ch)** | |
| ☐ | 21 | `F180mx3h_sunset_ocn-brz` | **Flow** · flow length **180m** → 3 hours · 0 breaks | Time of day → Sunset · Show | Always · horizon · glass · Jost · dot · White #ffffff | Ocean 100 · Shore breeze 55 — master 100 | 3-Hour Study With Me 🌊 Deep Work Timer, No Breaks for Flow State & ADHD \| Ocean & Breeze, Sunset | deep work, flow state, deep work timer, study with me no break, 3 hour timer, study with me 3 hours, sunset ambience, pomodoro adhd, 핑크 노이즈 공부 **(142 ch)** | |
| ☐ | 22 | `F180mx3h_sunset_bell` | **Flow** · flow length **180m** → 3 hours · 0 breaks | Time of day → Sunset · Show | Always · horizon · glass · Jost · dot · White #ffffff | ALL sounds OFF — bell only | 3-Hour Study With Me 🔔 Deep Work Timer, No Breaks for Flow State & ADHD \| Sunset | deep work, flow state, deep work timer, study with me no break, 3 hour timer, study with me 3 hours, sunset ambience, pomodoro adhd, pomodoro no music, silent study timer, timer belajar **(185 ch)** | |
| ☐ | 23 | `C50-15x3h_twilight_ocn` | **Custom** · By count · work **150m** · breaks **2** · break length **15m** → 3 hours · 2 breaks | Time of day → Twilight · Show | Always · top · solid · Jost · colon · White #ffffff | Ocean 100 — master 100 | 3-Hour Study With Me 🌊 50/15 Pomodoro Timer for Deep Focus & ADHD \| Ocean Waves & Twilight | 50/15 pomodoro, 50 minute pomodoro, pomodoro technique, 3 hour timer, study with me 3 hours, twilight ambience, pomodoro adhd, çalışma zamanlayıcısı **(148 ch)** | |
| ☐ | 24 | `C50-15x3h_twilight_bell` | **Custom** · By count · work **150m** · breaks **2** · break length **15m** → 3 hours · 2 breaks | Time of day → Twilight · Show | Always · top · solid · Jost · colon · White #ffffff | ALL sounds OFF — bell only | 3-Hour Study With Me 🔔 50/15 Pomodoro Timer, No Music for Deep Focus & ADHD \| Twilight | 50/15 pomodoro, 50 minute pomodoro, pomodoro technique, 3 hour timer, study with me 3 hours, twilight ambience, pomodoro adhd, pomodoro no music, silent study timer, ポモドーロタイマー **(175 ch)** | |
| ☐ | 25 | `C40-10x4h_predawn_snd-brz` | **Custom** · By count · work **200m** · breaks **4** · break length **10m** → 4 hours · 4 breaks | Time of day → Pre-dawn · Show | Always · middle · solid · Serif · none · White #ffffff | Sand 100 · Shore breeze 55 — master 100 | 4-Hour Study With Me 🍃 40/10 Pomodoro Timer for Deep Focus & ADHD \| Sand & Breeze, Pre-Dawn | 40/10 pomodoro, 40 minute pomodoro, pomodoro technique, 4 hour timer, study with me 4 hours, pre-dawn ambience, pomodoro adhd, अध्ययन टाइमर **(139 ch)** | |
| ☐ | 26 | `C40-10x4h_predawn_bell` | **Custom** · By count · work **200m** · breaks **4** · break length **10m** → 4 hours · 4 breaks | Time of day → Pre-dawn · Show | Always · middle · solid · Serif · none · White #ffffff | ALL sounds OFF — bell only | 4-Hour Study With Me 🔔 40/10 Pomodoro Timer, No Music for Deep Focus & ADHD \| Pre-Dawn | 40/10 pomodoro, 40 minute pomodoro, pomodoro technique, 4 hour timer, study with me 4 hours, pre-dawn ambience, pomodoro adhd, pomodoro no music, silent study timer, temporizador de estudio **(189 ch)** | |
| ☐ | 27 | `C30-15x2h_midday_all4` | **Custom** · By count · work **90m** · breaks **2** · break length **15m** → 2 hours · 2 breaks | Time of day → Midday · Show | Always · horizon · glass · Serif · colon · Charcoal #20242e | Ocean 100 · Sand 55 · Shore breeze 40 · Seabirds 30 — master 85 | 2-Hour Study With Me 🍃 30/15 Pomodoro Timer for Deep Focus & ADHD \| Full Shore Ambience & Midday | 30/15 pomodoro, 30 minute pomodoro, pomodoro technique, 2 hour timer, study with me 2 hours, midday ambience, pomodoro adhd, مؤقت للدراسة **(137 ch)** | |
| ☐ | 28 | `C30-15x2h_midday_bell` | **Custom** · By count · work **90m** · breaks **2** · break length **15m** → 2 hours · 2 breaks | Time of day → Midday · Show | Always · horizon · glass · Serif · colon · Charcoal #20242e | ALL sounds OFF — bell only | 2-Hour Study With Me 🔔 30/15 Pomodoro Timer, No Music for Deep Focus & ADHD \| Midday | 30/15 pomodoro, 30 minute pomodoro, pomodoro technique, 2 hour timer, study with me 2 hours, midday ambience, pomodoro adhd, pomodoro no music, silent study timer, temporizador de estudo **(186 ch)** | |
| ☐ | 29 | `C60-20x5h_sunrise_ocn-snd` | **Custom** · By count · work **240m** · breaks **3** · break length **20m** → 5 hours · 3 breaks | Time of day → Sunrise · Show | Always · ledge · solid · Jost · none · Charcoal #20242e | Ocean 100 · Sand 55 — master 100 | 5-Hour Study With Me 🌊 60/20 Pomodoro Timer for Deep Focus & ADHD \| Ocean & Sand, Sunrise | 60/20 pomodoro, 60 minute pomodoro, pomodoro technique, 5 hour timer, study with me 5 hours, sunrise ambience, pomodoro adhd, 핑크 노이즈 공부 **(135 ch)** | |
| ☐ | 30 | `C60-20x5h_sunrise_bell` | **Custom** · By count · work **240m** · breaks **3** · break length **20m** → 5 hours · 3 breaks | Time of day → Sunrise · Show | Always · ledge · solid · Jost · none · Charcoal #20242e | ALL sounds OFF — bell only | 5-Hour Study With Me 🔔 60/20 Pomodoro Timer, No Music for Deep Focus & ADHD \| Sunrise | 60/20 pomodoro, 60 minute pomodoro, pomodoro technique, 5 hour timer, study with me 5 hours, sunrise ambience, pomodoro adhd, pomodoro no music, silent study timer, timer belajar **(178 ch)** | |

---

## Ready-to-paste blocks — Month 1

Month 1 only, deliberately. Once these land we will have real Analytics, and later phases should be
rewritten from that data rather than frozen today.

<details>
<summary><code>P50-10x2h_sunset_ocn</code> — 2-Hour Study With Me 🌊 50/10 Pomodoro Timer for Deep Focus & ADHD | Ocean Waves & Sunset</summary>

**Setup:** Pomodoro · focus **50m** · break **10m** · blocks **2** · Time of day → Sunset · Ocean

**Verified length: 2 hours exactly.**

**Title:** 2-Hour Study With Me 🌊 50/10 Pomodoro Timer for Deep Focus & ADHD | Ocean Waves & Sunset

**Extra tags** — paste after the Upload-defaults tags (137/219 chars):

> 50/10 pomodoro, 50 minute pomodoro, pomodoro technique, 2 hour timer, study with me 2 hours, sunset ambience, pomodoro adhd, अध्ययन टाइमर

**Description — paste ABOVE the Upload-defaults text.** The standing block (channel blurb,
originality declaration, hashtags) lives in Upload defaults and pre-fills every video; only the
head below changes per video, and it goes FIRST because the opening two lines are what appear in
search and above the "…more" fold.

```
2 hours Study With Me pomodoro timer — 50/10 focus blocks with ocean waves under a sunset sky.
A calm, no-talking study timer for deep focus, ADHD, exam revision, coding and long work sessions.

2 focus blocks of 50 minutes, a 10-minute break after each, and a soft bell on every change. The sky moves the whole way through — this session begins in late-afternoon light and sinks to the horizon as you work.

⏱ Chapters
00:00:00 Focus 1
00:50:00 Break 1
01:00:00 Focus 2
01:50:00 Break 2

```

> ⚠️ No preset link: this channel cannot post links yet (advanced features pending). Flip
> `LINKS_OK = true` at the top of gen-roadmap.cjs the day verification lands and regenerate —
> every row gains its deep link. Preset for this row: `https://sustaintimer.com/?mode=pomodoro&work=50&break=10&blocks=2&phase=sunset&sound=ocean`

</details>

<details>
<summary><code>P50-10x2h_sunset_bell</code> — 2-Hour Study With Me 🔔 50/10 Pomodoro Timer, No Music for Deep Focus & ADHD | Sunset</summary>

**Setup:** Pomodoro · focus **50m** · break **10m** · blocks **2** · Time of day → Sunset · ALL sounds OFF — bell only

**Verified length: 2 hours exactly.**

**Title:** 2-Hour Study With Me 🔔 50/10 Pomodoro Timer, No Music for Deep Focus & ADHD | Sunset

**Extra tags** — paste after the Upload-defaults tags (187/219 chars):

> 50/10 pomodoro, 50 minute pomodoro, pomodoro technique, 2 hour timer, study with me 2 hours, sunset ambience, pomodoro adhd, pomodoro no music, silent study timer, temporizador de estudio

**Description — paste ABOVE the Upload-defaults text.** The standing block (channel blurb,
originality declaration, hashtags) lives in Upload defaults and pre-fills every video; only the
head below changes per video, and it goes FIRST because the opening two lines are what appear in
search and above the "…more" fold.

```
2 hours Study With Me pomodoro timer — 50/10 focus blocks with no music, bell only under a sunset sky.
A calm, no-talking study timer for deep focus, ADHD, exam revision, coding and long work sessions.

2 focus blocks of 50 minutes, a 10-minute break after each, and a soft bell on every change. The sky moves the whole way through — this session begins in late-afternoon light and sinks to the horizon as you work.

⏱ Chapters
00:00:00 Focus 1
00:50:00 Break 1
01:00:00 Focus 2
01:50:00 Break 2

```

> ⚠️ No preset link: this channel cannot post links yet (advanced features pending). Flip
> `LINKS_OK = true` at the top of gen-roadmap.cjs the day verification lands and regenerate —
> every row gains its deep link. Preset for this row: `https://sustaintimer.com/?mode=pomodoro&work=50&break=10&blocks=2&phase=sunset&sound=`

</details>

<details>
<summary><code>P50-10x3h_midnight_ocn-brz</code> — 3-Hour Study With Me 🌊 50/10 Pomodoro Timer for Deep Focus & ADHD | Ocean & Breeze, Midnight</summary>

**Setup:** Pomodoro · focus **50m** · break **10m** · blocks **3** · Time of day → Midnight · Ocean + Shore breeze

**Verified length: 3 hours exactly.**

**Title:** 3-Hour Study With Me 🌊 50/10 Pomodoro Timer for Deep Focus & ADHD | Ocean & Breeze, Midnight

**Extra tags** — paste after the Upload-defaults tags (139/219 chars):

> 50/10 pomodoro, 50 minute pomodoro, pomodoro technique, 3 hour timer, study with me 3 hours, midnight ambience, pomodoro adhd, مؤقت للدراسة

**Description — paste ABOVE the Upload-defaults text.** The standing block (channel blurb,
originality declaration, hashtags) lives in Upload defaults and pre-fills every video; only the
head below changes per video, and it goes FIRST because the opening two lines are what appear in
search and above the "…more" fold.

```
3 hours Study With Me pomodoro timer — 50/10 focus blocks with ocean & breeze under a midnight sky.
A calm, no-talking study timer for deep focus, ADHD, exam revision, coding and long work sessions.

3 focus blocks of 50 minutes, a 10-minute break after each, and a soft bell on every change. The sky moves the whole way through — this session settles from dusk into the small hours as you work.

⏱ Chapters
00:00:00 Focus 1
00:50:00 Break 1
01:00:00 Focus 2
01:50:00 Break 2
02:00:00 Focus 3
02:50:00 Break 3

```

> ⚠️ No preset link: this channel cannot post links yet (advanced features pending). Flip
> `LINKS_OK = true` at the top of gen-roadmap.cjs the day verification lands and regenerate —
> every row gains its deep link. Preset for this row: `https://sustaintimer.com/?mode=pomodoro&work=50&break=10&blocks=3&phase=midnight&sound=ocean,breeze`

</details>

<details>
<summary><code>P50-10x3h_midnight_bell</code> — 3-Hour Study With Me 🔔 50/10 Pomodoro Timer, No Music for Deep Focus & ADHD | Midnight</summary>

**Setup:** Pomodoro · focus **50m** · break **10m** · blocks **3** · Time of day → Midnight · ALL sounds OFF — bell only

**Verified length: 3 hours exactly.**

**Title:** 3-Hour Study With Me 🔔 50/10 Pomodoro Timer, No Music for Deep Focus & ADHD | Midnight

**Extra tags** — paste after the Upload-defaults tags (188/219 chars):

> 50/10 pomodoro, 50 minute pomodoro, pomodoro technique, 3 hour timer, study with me 3 hours, midnight ambience, pomodoro adhd, pomodoro no music, silent study timer, temporizador de estudo

**Description — paste ABOVE the Upload-defaults text.** The standing block (channel blurb,
originality declaration, hashtags) lives in Upload defaults and pre-fills every video; only the
head below changes per video, and it goes FIRST because the opening two lines are what appear in
search and above the "…more" fold.

```
3 hours Study With Me pomodoro timer — 50/10 focus blocks with no music, bell only under a midnight sky.
A calm, no-talking study timer for deep focus, ADHD, exam revision, coding and long work sessions.

3 focus blocks of 50 minutes, a 10-minute break after each, and a soft bell on every change. The sky moves the whole way through — this session settles from dusk into the small hours as you work.

⏱ Chapters
00:00:00 Focus 1
00:50:00 Break 1
01:00:00 Focus 2
01:50:00 Break 2
02:00:00 Focus 3
02:50:00 Break 3

```

> ⚠️ No preset link: this channel cannot post links yet (advanced features pending). Flip
> `LINKS_OK = true` at the top of gen-roadmap.cjs the day verification lands and regenerate —
> every row gains its deep link. Preset for this row: `https://sustaintimer.com/?mode=pomodoro&work=50&break=10&blocks=3&phase=midnight&sound=`

</details>

<details>
<summary><code>P50-10x4h_sunrise_ocn-brd</code> — 4-Hour Study With Me 🌊 50/10 Pomodoro Timer for Deep Focus & ADHD | Ocean & Seabirds, Sunrise</summary>

**Setup:** Pomodoro · focus **50m** · break **10m** · blocks **4** · Time of day → Sunrise · Ocean + Seabirds

**Verified length: 4 hours exactly.**

**Title:** 4-Hour Study With Me 🌊 50/10 Pomodoro Timer for Deep Focus & ADHD | Ocean & Seabirds, Sunrise

**Extra tags** — paste after the Upload-defaults tags (135/219 chars):

> 50/10 pomodoro, 50 minute pomodoro, pomodoro technique, 4 hour timer, study with me 4 hours, sunrise ambience, pomodoro adhd, 핑크 노이즈 공부

**Description — paste ABOVE the Upload-defaults text.** The standing block (channel blurb,
originality declaration, hashtags) lives in Upload defaults and pre-fills every video; only the
head below changes per video, and it goes FIRST because the opening two lines are what appear in
search and above the "…more" fold.

```
4 hours Study With Me pomodoro timer — 50/10 focus blocks with ocean & seabirds under a sunrise sky.
A calm, no-talking study timer for deep focus, ADHD, exam revision, coding and long work sessions.

4 focus blocks of 50 minutes, a 10-minute break after each, and a soft bell on every change. The sky moves the whole way through — this session begins at first light and warms into full morning as you work.

⏱ Chapters
00:00:00 Focus 1
00:50:00 Break 1
01:00:00 Focus 2
01:50:00 Break 2
02:00:00 Focus 3
02:50:00 Break 3
03:00:00 Focus 4
03:50:00 Break 4

```

> ⚠️ No preset link: this channel cannot post links yet (advanced features pending). Flip
> `LINKS_OK = true` at the top of gen-roadmap.cjs the day verification lands and regenerate —
> every row gains its deep link. Preset for this row: `https://sustaintimer.com/?mode=pomodoro&work=50&break=10&blocks=4&phase=sunrise&sound=ocean,birds`

</details>

<details>
<summary><code>P50-10x4h_sunrise_bell</code> — 4-Hour Study With Me 🔔 50/10 Pomodoro Timer, No Music for Deep Focus & ADHD | Sunrise</summary>

**Setup:** Pomodoro · focus **50m** · break **10m** · blocks **4** · Time of day → Sunrise · ALL sounds OFF — bell only

**Verified length: 4 hours exactly.**

**Title:** 4-Hour Study With Me 🔔 50/10 Pomodoro Timer, No Music for Deep Focus & ADHD | Sunrise

**Extra tags** — paste after the Upload-defaults tags (178/219 chars):

> 50/10 pomodoro, 50 minute pomodoro, pomodoro technique, 4 hour timer, study with me 4 hours, sunrise ambience, pomodoro adhd, pomodoro no music, silent study timer, timer belajar

**Description — paste ABOVE the Upload-defaults text.** The standing block (channel blurb,
originality declaration, hashtags) lives in Upload defaults and pre-fills every video; only the
head below changes per video, and it goes FIRST because the opening two lines are what appear in
search and above the "…more" fold.

```
4 hours Study With Me pomodoro timer — 50/10 focus blocks with no music, bell only under a sunrise sky.
A calm, no-talking study timer for deep focus, ADHD, exam revision, coding and long work sessions.

4 focus blocks of 50 minutes, a 10-minute break after each, and a soft bell on every change. The sky moves the whole way through — this session begins at first light and warms into full morning as you work.

⏱ Chapters
00:00:00 Focus 1
00:50:00 Break 1
01:00:00 Focus 2
01:50:00 Break 2
02:00:00 Focus 3
02:50:00 Break 3
03:00:00 Focus 4
03:50:00 Break 4

```

> ⚠️ No preset link: this channel cannot post links yet (advanced features pending). Flip
> `LINKS_OK = true` at the top of gen-roadmap.cjs the day verification lands and regenerate —
> every row gains its deep link. Preset for this row: `https://sustaintimer.com/?mode=pomodoro&work=50&break=10&blocks=4&phase=sunrise&sound=`

</details>

<details>
<summary><code>P50-10x1h_twilight_snd-brz</code> — 1-Hour Study With Me 🍃 50/10 Pomodoro Timer for Deep Focus & ADHD | Sand & Breeze, Twilight</summary>

**Setup:** Pomodoro · focus **50m** · break **10m** · blocks **1** · Time of day → Twilight · Sand + Shore breeze

**Verified length: 1 hour exactly.**

**Title:** 1-Hour Study With Me 🍃 50/10 Pomodoro Timer for Deep Focus & ADHD | Sand & Breeze, Twilight

**Extra tags** — paste after the Upload-defaults tags (148/219 chars):

> 50/10 pomodoro, 50 minute pomodoro, pomodoro technique, 1 hour timer, study with me 1 hours, twilight ambience, pomodoro adhd, çalışma zamanlayıcısı

**Description — paste ABOVE the Upload-defaults text.** The standing block (channel blurb,
originality declaration, hashtags) lives in Upload defaults and pre-fills every video; only the
head below changes per video, and it goes FIRST because the opening two lines are what appear in
search and above the "…more" fold.

```
1 hour Study With Me pomodoro timer — 50/10 focus blocks with sand & breeze under a twilight sky.
A calm, no-talking study timer for deep focus, ADHD, exam revision, coding and long work sessions.

One 50-minute block, with a soft bell to open and close it. The sky moves the whole way through — this session deepens from the last light into dusk as you work.
```

> ⚠️ No preset link: this channel cannot post links yet (advanced features pending). Flip
> `LINKS_OK = true` at the top of gen-roadmap.cjs the day verification lands and regenerate —
> every row gains its deep link. Preset for this row: `https://sustaintimer.com/?mode=pomodoro&work=50&break=10&blocks=1&phase=twilight&sound=sand,breeze`

</details>

<details>
<summary><code>P50-10x1h_twilight_bell</code> — 1-Hour Study With Me 🔔 50/10 Pomodoro Timer, No Music for Deep Focus & ADHD | Twilight</summary>

**Setup:** Pomodoro · focus **50m** · break **10m** · blocks **1** · Time of day → Twilight · ALL sounds OFF — bell only

**Verified length: 1 hour exactly.**

**Title:** 1-Hour Study With Me 🔔 50/10 Pomodoro Timer, No Music for Deep Focus & ADHD | Twilight

**Extra tags** — paste after the Upload-defaults tags (175/219 chars):

> 50/10 pomodoro, 50 minute pomodoro, pomodoro technique, 1 hour timer, study with me 1 hours, twilight ambience, pomodoro adhd, pomodoro no music, silent study timer, ポモドーロタイマー

**Description — paste ABOVE the Upload-defaults text.** The standing block (channel blurb,
originality declaration, hashtags) lives in Upload defaults and pre-fills every video; only the
head below changes per video, and it goes FIRST because the opening two lines are what appear in
search and above the "…more" fold.

```
1 hour Study With Me pomodoro timer — 50/10 focus blocks with no music, bell only under a twilight sky.
A calm, no-talking study timer for deep focus, ADHD, exam revision, coding and long work sessions.

One 50-minute block, with a soft bell to open and close it. The sky moves the whole way through — this session deepens from the last light into dusk as you work.
```

> ⚠️ No preset link: this channel cannot post links yet (advanced features pending). Flip
> `LINKS_OK = true` at the top of gen-roadmap.cjs the day verification lands and regenerate —
> every row gains its deep link. Preset for this row: `https://sustaintimer.com/?mode=pomodoro&work=50&break=10&blocks=1&phase=twilight&sound=`

</details>

<details>
<summary><code>P50-10x3h_sunset_ocn-snd-brd</code> — 3-Hour Study With Me 🌊 50/10 Pomodoro Timer for Deep Focus & ADHD | Ocean, Sand & Seabirds, Sunset</summary>

**Setup:** Pomodoro · focus **50m** · break **10m** · blocks **3** · Time of day → Sunset · Ocean + Sand + Seabirds

**Verified length: 3 hours exactly.**

**Title:** 3-Hour Study With Me 🌊 50/10 Pomodoro Timer for Deep Focus & ADHD | Ocean, Sand & Seabirds, Sunset

**Extra tags** — paste after the Upload-defaults tags (137/219 chars):

> 50/10 pomodoro, 50 minute pomodoro, pomodoro technique, 3 hour timer, study with me 3 hours, sunset ambience, pomodoro adhd, अध्ययन टाइमर

**Description — paste ABOVE the Upload-defaults text.** The standing block (channel blurb,
originality declaration, hashtags) lives in Upload defaults and pre-fills every video; only the
head below changes per video, and it goes FIRST because the opening two lines are what appear in
search and above the "…more" fold.

```
3 hours Study With Me pomodoro timer — 50/10 focus blocks with ocean, sand & seabirds under a sunset sky.
A calm, no-talking study timer for deep focus, ADHD, exam revision, coding and long work sessions.

3 focus blocks of 50 minutes, a 10-minute break after each, and a soft bell on every change. The sky moves the whole way through — this session begins in late-afternoon light and sinks to the horizon as you work.

⏱ Chapters
00:00:00 Focus 1
00:50:00 Break 1
01:00:00 Focus 2
01:50:00 Break 2
02:00:00 Focus 3
02:50:00 Break 3

```

> ⚠️ No preset link: this channel cannot post links yet (advanced features pending). Flip
> `LINKS_OK = true` at the top of gen-roadmap.cjs the day verification lands and regenerate —
> every row gains its deep link. Preset for this row: `https://sustaintimer.com/?mode=pomodoro&work=50&break=10&blocks=3&phase=sunset&sound=ocean,sand,birds`

</details>

<details>
<summary><code>P50-10x3h_sunset_bell</code> — 3-Hour Study With Me 🔔 50/10 Pomodoro Timer, No Music for Deep Focus & ADHD | Sunset</summary>

**Setup:** Pomodoro · focus **50m** · break **10m** · blocks **3** · Time of day → Sunset · ALL sounds OFF — bell only

**Verified length: 3 hours exactly.**

**Title:** 3-Hour Study With Me 🔔 50/10 Pomodoro Timer, No Music for Deep Focus & ADHD | Sunset

**Extra tags** — paste after the Upload-defaults tags (187/219 chars):

> 50/10 pomodoro, 50 minute pomodoro, pomodoro technique, 3 hour timer, study with me 3 hours, sunset ambience, pomodoro adhd, pomodoro no music, silent study timer, temporizador de estudio

**Description — paste ABOVE the Upload-defaults text.** The standing block (channel blurb,
originality declaration, hashtags) lives in Upload defaults and pre-fills every video; only the
head below changes per video, and it goes FIRST because the opening two lines are what appear in
search and above the "…more" fold.

```
3 hours Study With Me pomodoro timer — 50/10 focus blocks with no music, bell only under a sunset sky.
A calm, no-talking study timer for deep focus, ADHD, exam revision, coding and long work sessions.

3 focus blocks of 50 minutes, a 10-minute break after each, and a soft bell on every change. The sky moves the whole way through — this session begins in late-afternoon light and sinks to the horizon as you work.

⏱ Chapters
00:00:00 Focus 1
00:50:00 Break 1
01:00:00 Focus 2
01:50:00 Break 2
02:00:00 Focus 3
02:50:00 Break 3

```

> ⚠️ No preset link: this channel cannot post links yet (advanced features pending). Flip
> `LINKS_OK = true` at the top of gen-roadmap.cjs the day verification lands and regenerate —
> every row gains its deep link. Preset for this row: `https://sustaintimer.com/?mode=pomodoro&work=50&break=10&blocks=3&phase=sunset&sound=`

</details>

<details>
<summary><code>P25-5x2h_midnight_ocn</code> — 2-Hour Study With Me 🌊 25/5 Pomodoro Timer for Deep Focus & ADHD | Ocean Waves & Midnight</summary>

**Setup:** Pomodoro · focus **25m** · break **5m** · blocks **4** · Time of day → Midnight · Ocean

**Verified length: 2 hours exactly.**

**Title:** 2-Hour Study With Me 🌊 25/5 Pomodoro Timer for Deep Focus & ADHD | Ocean Waves & Midnight

**Extra tags** — paste after the Upload-defaults tags (138/219 chars):

> 25/5 pomodoro, 25 minute pomodoro, pomodoro technique, 2 hour timer, study with me 2 hours, midnight ambience, pomodoro adhd, مؤقت للدراسة

**Description — paste ABOVE the Upload-defaults text.** The standing block (channel blurb,
originality declaration, hashtags) lives in Upload defaults and pre-fills every video; only the
head below changes per video, and it goes FIRST because the opening two lines are what appear in
search and above the "…more" fold.

```
2 hours Study With Me pomodoro timer — 25/5 focus blocks with ocean waves under a midnight sky.
A calm, no-talking study timer for deep focus, ADHD, exam revision, coding and long work sessions.

4 focus blocks of 25 minutes, a 5-minute break after each, and a soft bell on every change. The sky moves the whole way through — this session settles from dusk into the small hours as you work.

⏱ Chapters
00:00:00 Focus 1
00:25:00 Break 1
00:30:00 Focus 2
00:55:00 Break 2
01:00:00 Focus 3
01:25:00 Break 3
01:30:00 Focus 4
01:55:00 Break 4

```

> ⚠️ No preset link: this channel cannot post links yet (advanced features pending). Flip
> `LINKS_OK = true` at the top of gen-roadmap.cjs the day verification lands and regenerate —
> every row gains its deep link. Preset for this row: `https://sustaintimer.com/?mode=pomodoro&work=25&break=5&blocks=4&phase=midnight&sound=ocean`

</details>

<details>
<summary><code>P25-5x2h_midnight_bell</code> — 2-Hour Study With Me 🔔 25/5 Pomodoro Timer, No Music for Deep Focus & ADHD | Midnight</summary>

**Setup:** Pomodoro · focus **25m** · break **5m** · blocks **4** · Time of day → Midnight · ALL sounds OFF — bell only

**Verified length: 2 hours exactly.**

**Title:** 2-Hour Study With Me 🔔 25/5 Pomodoro Timer, No Music for Deep Focus & ADHD | Midnight

**Extra tags** — paste after the Upload-defaults tags (187/219 chars):

> 25/5 pomodoro, 25 minute pomodoro, pomodoro technique, 2 hour timer, study with me 2 hours, midnight ambience, pomodoro adhd, pomodoro no music, silent study timer, temporizador de estudo

**Description — paste ABOVE the Upload-defaults text.** The standing block (channel blurb,
originality declaration, hashtags) lives in Upload defaults and pre-fills every video; only the
head below changes per video, and it goes FIRST because the opening two lines are what appear in
search and above the "…more" fold.

```
2 hours Study With Me pomodoro timer — 25/5 focus blocks with no music, bell only under a midnight sky.
A calm, no-talking study timer for deep focus, ADHD, exam revision, coding and long work sessions.

4 focus blocks of 25 minutes, a 5-minute break after each, and a soft bell on every change. The sky moves the whole way through — this session settles from dusk into the small hours as you work.

⏱ Chapters
00:00:00 Focus 1
00:25:00 Break 1
00:30:00 Focus 2
00:55:00 Break 2
01:00:00 Focus 3
01:25:00 Break 3
01:30:00 Focus 4
01:55:00 Break 4

```

> ⚠️ No preset link: this channel cannot post links yet (advanced features pending). Flip
> `LINKS_OK = true` at the top of gen-roadmap.cjs the day verification lands and regenerate —
> every row gains its deep link. Preset for this row: `https://sustaintimer.com/?mode=pomodoro&work=25&break=5&blocks=4&phase=midnight&sound=`

</details>

<details>
<summary><code>P25-5x3h_sunset_ocn-snd</code> — 3-Hour Study With Me 🌊 25/5 Pomodoro Timer for Deep Focus & ADHD | Ocean & Sand, Sunset</summary>

**Setup:** Pomodoro · focus **25m** · break **5m** · blocks **6** · Time of day → Sunset · Ocean + Sand

**Verified length: 3 hours exactly.**

**Title:** 3-Hour Study With Me 🌊 25/5 Pomodoro Timer for Deep Focus & ADHD | Ocean & Sand, Sunset

**Extra tags** — paste after the Upload-defaults tags (133/219 chars):

> 25/5 pomodoro, 25 minute pomodoro, pomodoro technique, 3 hour timer, study with me 3 hours, sunset ambience, pomodoro adhd, 핑크 노이즈 공부

**Description — paste ABOVE the Upload-defaults text.** The standing block (channel blurb,
originality declaration, hashtags) lives in Upload defaults and pre-fills every video; only the
head below changes per video, and it goes FIRST because the opening two lines are what appear in
search and above the "…more" fold.

```
3 hours Study With Me pomodoro timer — 25/5 focus blocks with ocean & sand under a sunset sky.
A calm, no-talking study timer for deep focus, ADHD, exam revision, coding and long work sessions.

6 focus blocks of 25 minutes, a 5-minute break after each, and a soft bell on every change. The sky moves the whole way through — this session begins in late-afternoon light and sinks to the horizon as you work.

⏱ Chapters
00:00:00 Focus 1
00:25:00 Break 1
00:30:00 Focus 2
00:55:00 Break 2
01:00:00 Focus 3
01:25:00 Break 3
01:30:00 Focus 4
01:55:00 Break 4
02:00:00 Focus 5
02:25:00 Break 5
02:30:00 Focus 6
02:55:00 Break 6

```

> ⚠️ No preset link: this channel cannot post links yet (advanced features pending). Flip
> `LINKS_OK = true` at the top of gen-roadmap.cjs the day verification lands and regenerate —
> every row gains its deep link. Preset for this row: `https://sustaintimer.com/?mode=pomodoro&work=25&break=5&blocks=6&phase=sunset&sound=ocean,sand`

</details>

<details>
<summary><code>P25-5x3h_sunset_bell</code> — 3-Hour Study With Me 🔔 25/5 Pomodoro Timer, No Music for Deep Focus & ADHD | Sunset</summary>

**Setup:** Pomodoro · focus **25m** · break **5m** · blocks **6** · Time of day → Sunset · ALL sounds OFF — bell only

**Verified length: 3 hours exactly.**

**Title:** 3-Hour Study With Me 🔔 25/5 Pomodoro Timer, No Music for Deep Focus & ADHD | Sunset

**Extra tags** — paste after the Upload-defaults tags (176/219 chars):

> 25/5 pomodoro, 25 minute pomodoro, pomodoro technique, 3 hour timer, study with me 3 hours, sunset ambience, pomodoro adhd, pomodoro no music, silent study timer, timer belajar

**Description — paste ABOVE the Upload-defaults text.** The standing block (channel blurb,
originality declaration, hashtags) lives in Upload defaults and pre-fills every video; only the
head below changes per video, and it goes FIRST because the opening two lines are what appear in
search and above the "…more" fold.

```
3 hours Study With Me pomodoro timer — 25/5 focus blocks with no music, bell only under a sunset sky.
A calm, no-talking study timer for deep focus, ADHD, exam revision, coding and long work sessions.

6 focus blocks of 25 minutes, a 5-minute break after each, and a soft bell on every change. The sky moves the whole way through — this session begins in late-afternoon light and sinks to the horizon as you work.

⏱ Chapters
00:00:00 Focus 1
00:25:00 Break 1
00:30:00 Focus 2
00:55:00 Break 2
01:00:00 Focus 3
01:25:00 Break 3
01:30:00 Focus 4
01:55:00 Break 4
02:00:00 Focus 5
02:25:00 Break 5
02:30:00 Focus 6
02:55:00 Break 6

```

> ⚠️ No preset link: this channel cannot post links yet (advanced features pending). Flip
> `LINKS_OK = true` at the top of gen-roadmap.cjs the day verification lands and regenerate —
> every row gains its deep link. Preset for this row: `https://sustaintimer.com/?mode=pomodoro&work=25&break=5&blocks=6&phase=sunset&sound=`

</details>

<details>
<summary><code>P25-5x4h_midday_brz-brd</code> — 4-Hour Study With Me 🍃 25/5 Pomodoro Timer for Deep Focus & ADHD | Breeze & Seabirds, Midday</summary>

**Setup:** Pomodoro · focus **25m** · break **5m** · blocks **8** · Time of day → Midday · Shore breeze + Seabirds

**Verified length: 4 hours exactly.**

**Title:** 4-Hour Study With Me 🍃 25/5 Pomodoro Timer for Deep Focus & ADHD | Breeze & Seabirds, Midday

**Extra tags** — paste after the Upload-defaults tags (145/219 chars):

> 25/5 pomodoro, 25 minute pomodoro, pomodoro technique, 4 hour timer, study with me 4 hours, midday ambience, pomodoro adhd, çalışma zamanlayıcısı

**Description — paste ABOVE the Upload-defaults text.** The standing block (channel blurb,
originality declaration, hashtags) lives in Upload defaults and pre-fills every video; only the
head below changes per video, and it goes FIRST because the opening two lines are what appear in
search and above the "…more" fold.

```
4 hours Study With Me pomodoro timer — 25/5 focus blocks with breeze & seabirds under a midday sky.
A calm, no-talking study timer for deep focus, ADHD, exam revision, coding and long work sessions.

8 focus blocks of 25 minutes, a 5-minute break after each, and a soft bell on every change. The sky moves the whole way through — this session drifts from late morning into afternoon as you work.

⏱ Chapters
00:00:00 Focus 1
00:25:00 Break 1
00:30:00 Focus 2
00:55:00 Break 2
01:00:00 Focus 3
01:25:00 Break 3
01:30:00 Focus 4
01:55:00 Break 4
02:00:00 Focus 5
02:25:00 Break 5
02:30:00 Focus 6
02:55:00 Break 6
03:00:00 Focus 7
03:25:00 Break 7
03:30:00 Focus 8
03:55:00 Break 8

```

> ⚠️ No preset link: this channel cannot post links yet (advanced features pending). Flip
> `LINKS_OK = true` at the top of gen-roadmap.cjs the day verification lands and regenerate —
> every row gains its deep link. Preset for this row: `https://sustaintimer.com/?mode=pomodoro&work=25&break=5&blocks=8&phase=midday&sound=breeze,birds`

</details>

<details>
<summary><code>P25-5x4h_midday_bell</code> — 4-Hour Study With Me 🔔 25/5 Pomodoro Timer, No Music for Deep Focus & ADHD | Midday</summary>

**Setup:** Pomodoro · focus **25m** · break **5m** · blocks **8** · Time of day → Midday · ALL sounds OFF — bell only

**Verified length: 4 hours exactly.**

**Title:** 4-Hour Study With Me 🔔 25/5 Pomodoro Timer, No Music for Deep Focus & ADHD | Midday

**Extra tags** — paste after the Upload-defaults tags (172/219 chars):

> 25/5 pomodoro, 25 minute pomodoro, pomodoro technique, 4 hour timer, study with me 4 hours, midday ambience, pomodoro adhd, pomodoro no music, silent study timer, ポモドーロタイマー

**Description — paste ABOVE the Upload-defaults text.** The standing block (channel blurb,
originality declaration, hashtags) lives in Upload defaults and pre-fills every video; only the
head below changes per video, and it goes FIRST because the opening two lines are what appear in
search and above the "…more" fold.

```
4 hours Study With Me pomodoro timer — 25/5 focus blocks with no music, bell only under a midday sky.
A calm, no-talking study timer for deep focus, ADHD, exam revision, coding and long work sessions.

8 focus blocks of 25 minutes, a 5-minute break after each, and a soft bell on every change. The sky moves the whole way through — this session drifts from late morning into afternoon as you work.

⏱ Chapters
00:00:00 Focus 1
00:25:00 Break 1
00:30:00 Focus 2
00:55:00 Break 2
01:00:00 Focus 3
01:25:00 Break 3
01:30:00 Focus 4
01:55:00 Break 4
02:00:00 Focus 5
02:25:00 Break 5
02:30:00 Focus 6
02:55:00 Break 6
03:00:00 Focus 7
03:25:00 Break 7
03:30:00 Focus 8
03:55:00 Break 8

```

> ⚠️ No preset link: this channel cannot post links yet (advanced features pending). Flip
> `LINKS_OK = true` at the top of gen-roadmap.cjs the day verification lands and regenerate —
> every row gains its deep link. Preset for this row: `https://sustaintimer.com/?mode=pomodoro&work=25&break=5&blocks=8&phase=midday&sound=`

</details>

<details>
<summary><code>F60mx1h_sunrise_ocn-brd</code> — 1-Hour Study With Me 🌊 Deep Work Timer, No Breaks for Flow State & ADHD | Ocean & Seabirds, Sunrise</summary>

**Setup:** Flow · flow length **60m** · Time of day → Sunrise · Ocean + Seabirds

**Verified length: 1 hour exactly.**

**Title:** 1-Hour Study With Me 🌊 Deep Work Timer, No Breaks for Flow State & ADHD | Ocean & Seabirds, Sunrise

**Extra tags** — paste after the Upload-defaults tags (146/219 chars):

> deep work, flow state, deep work timer, study with me no break, 1 hour timer, study with me 1 hours, sunrise ambience, pomodoro adhd, अध्ययन टाइमर

**Description — paste ABOVE the Upload-defaults text.** The standing block (channel blurb,
originality declaration, hashtags) lives in Upload defaults and pre-fills every video; only the
head below changes per video, and it goes FIRST because the opening two lines are what appear in
search and above the "…more" fold.

```
1 hour Study With Me deep work timer — one unbroken block with ocean & seabirds under a sunrise sky.
A calm, no-talking study timer for deep focus, ADHD, exam revision, coding and long work sessions.

One 60-minute block, with a soft bell to open and close it. The sky moves the whole way through — this session begins at first light and warms into full morning as you work.
```

> ⚠️ No preset link: this channel cannot post links yet (advanced features pending). Flip
> `LINKS_OK = true` at the top of gen-roadmap.cjs the day verification lands and regenerate —
> every row gains its deep link. Preset for this row: `https://sustaintimer.com/?mode=flow&flow=60&phase=sunrise&sound=ocean,birds`

</details>

<details>
<summary><code>F60mx1h_sunrise_bell</code> — 1-Hour Study With Me 🔔 Deep Work Timer, No Breaks for Flow State & ADHD | Sunrise</summary>

**Setup:** Flow · flow length **60m** · Time of day → Sunrise · ALL sounds OFF — bell only

**Verified length: 1 hour exactly.**

**Title:** 1-Hour Study With Me 🔔 Deep Work Timer, No Breaks for Flow State & ADHD | Sunrise

**Extra tags** — paste after the Upload-defaults tags (196/219 chars):

> deep work, flow state, deep work timer, study with me no break, 1 hour timer, study with me 1 hours, sunrise ambience, pomodoro adhd, pomodoro no music, silent study timer, temporizador de estudio

**Description — paste ABOVE the Upload-defaults text.** The standing block (channel blurb,
originality declaration, hashtags) lives in Upload defaults and pre-fills every video; only the
head below changes per video, and it goes FIRST because the opening two lines are what appear in
search and above the "…more" fold.

```
1 hour Study With Me deep work timer — one unbroken block with no music, bell only under a sunrise sky.
A calm, no-talking study timer for deep focus, ADHD, exam revision, coding and long work sessions.

One 60-minute block, with a soft bell to open and close it. The sky moves the whole way through — this session begins at first light and warms into full morning as you work.
```

> ⚠️ No preset link: this channel cannot post links yet (advanced features pending). Flip
> `LINKS_OK = true` at the top of gen-roadmap.cjs the day verification lands and regenerate —
> every row gains its deep link. Preset for this row: `https://sustaintimer.com/?mode=flow&flow=60&phase=sunrise&sound=`

</details>

<details>
<summary><code>F120mx2h_midnight_snd</code> — 2-Hour Study With Me 🍃 Deep Work Timer, No Breaks for Flow State & ADHD | Falling Sand & Midnight</summary>

**Setup:** Flow · flow length **120m** · Time of day → Midnight · Sand

**Verified length: 2 hours exactly.**

**Title:** 2-Hour Study With Me 🍃 Deep Work Timer, No Breaks for Flow State & ADHD | Falling Sand & Midnight

**Extra tags** — paste after the Upload-defaults tags (147/219 chars):

> deep work, flow state, deep work timer, study with me no break, 2 hour timer, study with me 2 hours, midnight ambience, pomodoro adhd, مؤقت للدراسة

**Description — paste ABOVE the Upload-defaults text.** The standing block (channel blurb,
originality declaration, hashtags) lives in Upload defaults and pre-fills every video; only the
head below changes per video, and it goes FIRST because the opening two lines are what appear in
search and above the "…more" fold.

```
2 hours Study With Me deep work timer — one unbroken block with falling sand under a midnight sky.
A calm, no-talking study timer for deep focus, ADHD, exam revision, coding and long work sessions.

One 120-minute block, with a soft bell to open and close it. The sky moves the whole way through — this session settles from dusk into the small hours as you work.
```

> ⚠️ No preset link: this channel cannot post links yet (advanced features pending). Flip
> `LINKS_OK = true` at the top of gen-roadmap.cjs the day verification lands and regenerate —
> every row gains its deep link. Preset for this row: `https://sustaintimer.com/?mode=flow&flow=120&phase=midnight&sound=sand`

</details>

<details>
<summary><code>F120mx2h_midnight_bell</code> — 2-Hour Study With Me 🔔 Deep Work Timer, No Breaks for Flow State & ADHD | Midnight</summary>

**Setup:** Flow · flow length **120m** · Time of day → Midnight · ALL sounds OFF — bell only

**Verified length: 2 hours exactly.**

**Title:** 2-Hour Study With Me 🔔 Deep Work Timer, No Breaks for Flow State & ADHD | Midnight

**Extra tags** — paste after the Upload-defaults tags (196/219 chars):

> deep work, flow state, deep work timer, study with me no break, 2 hour timer, study with me 2 hours, midnight ambience, pomodoro adhd, pomodoro no music, silent study timer, temporizador de estudo

**Description — paste ABOVE the Upload-defaults text.** The standing block (channel blurb,
originality declaration, hashtags) lives in Upload defaults and pre-fills every video; only the
head below changes per video, and it goes FIRST because the opening two lines are what appear in
search and above the "…more" fold.

```
2 hours Study With Me deep work timer — one unbroken block with no music, bell only under a midnight sky.
A calm, no-talking study timer for deep focus, ADHD, exam revision, coding and long work sessions.

One 120-minute block, with a soft bell to open and close it. The sky moves the whole way through — this session settles from dusk into the small hours as you work.
```

> ⚠️ No preset link: this channel cannot post links yet (advanced features pending). Flip
> `LINKS_OK = true` at the top of gen-roadmap.cjs the day verification lands and regenerate —
> every row gains its deep link. Preset for this row: `https://sustaintimer.com/?mode=flow&flow=120&phase=midnight&sound=`

</details>

<details>
<summary><code>F180mx3h_sunset_ocn-brz</code> — 3-Hour Study With Me 🌊 Deep Work Timer, No Breaks for Flow State & ADHD | Ocean & Breeze, Sunset</summary>

**Setup:** Flow · flow length **180m** · Time of day → Sunset · Ocean + Shore breeze

**Verified length: 3 hours exactly.**

**Title:** 3-Hour Study With Me 🌊 Deep Work Timer, No Breaks for Flow State & ADHD | Ocean & Breeze, Sunset

**Extra tags** — paste after the Upload-defaults tags (142/219 chars):

> deep work, flow state, deep work timer, study with me no break, 3 hour timer, study with me 3 hours, sunset ambience, pomodoro adhd, 핑크 노이즈 공부

**Description — paste ABOVE the Upload-defaults text.** The standing block (channel blurb,
originality declaration, hashtags) lives in Upload defaults and pre-fills every video; only the
head below changes per video, and it goes FIRST because the opening two lines are what appear in
search and above the "…more" fold.

```
3 hours Study With Me deep work timer — one unbroken block with ocean & breeze under a sunset sky.
A calm, no-talking study timer for deep focus, ADHD, exam revision, coding and long work sessions.

One 180-minute block, with a soft bell to open and close it. The sky moves the whole way through — this session begins in late-afternoon light and sinks to the horizon as you work.
```

> ⚠️ No preset link: this channel cannot post links yet (advanced features pending). Flip
> `LINKS_OK = true` at the top of gen-roadmap.cjs the day verification lands and regenerate —
> every row gains its deep link. Preset for this row: `https://sustaintimer.com/?mode=flow&flow=180&phase=sunset&sound=ocean,breeze`

</details>

<details>
<summary><code>F180mx3h_sunset_bell</code> — 3-Hour Study With Me 🔔 Deep Work Timer, No Breaks for Flow State & ADHD | Sunset</summary>

**Setup:** Flow · flow length **180m** · Time of day → Sunset · ALL sounds OFF — bell only

**Verified length: 3 hours exactly.**

**Title:** 3-Hour Study With Me 🔔 Deep Work Timer, No Breaks for Flow State & ADHD | Sunset

**Extra tags** — paste after the Upload-defaults tags (185/219 chars):

> deep work, flow state, deep work timer, study with me no break, 3 hour timer, study with me 3 hours, sunset ambience, pomodoro adhd, pomodoro no music, silent study timer, timer belajar

**Description — paste ABOVE the Upload-defaults text.** The standing block (channel blurb,
originality declaration, hashtags) lives in Upload defaults and pre-fills every video; only the
head below changes per video, and it goes FIRST because the opening two lines are what appear in
search and above the "…more" fold.

```
3 hours Study With Me deep work timer — one unbroken block with no music, bell only under a sunset sky.
A calm, no-talking study timer for deep focus, ADHD, exam revision, coding and long work sessions.

One 180-minute block, with a soft bell to open and close it. The sky moves the whole way through — this session begins in late-afternoon light and sinks to the horizon as you work.
```

> ⚠️ No preset link: this channel cannot post links yet (advanced features pending). Flip
> `LINKS_OK = true` at the top of gen-roadmap.cjs the day verification lands and regenerate —
> every row gains its deep link. Preset for this row: `https://sustaintimer.com/?mode=flow&flow=180&phase=sunset&sound=`

</details>

<details>
<summary><code>C50-15x3h_twilight_ocn</code> — 3-Hour Study With Me 🌊 50/15 Pomodoro Timer for Deep Focus & ADHD | Ocean Waves & Twilight</summary>

**Setup:** Custom · By count · work **150m** · breaks **2** · break length **15m** · Time of day → Twilight · Ocean

**Verified length: 3 hours exactly.**

**Title:** 3-Hour Study With Me 🌊 50/15 Pomodoro Timer for Deep Focus & ADHD | Ocean Waves & Twilight

**Extra tags** — paste after the Upload-defaults tags (148/219 chars):

> 50/15 pomodoro, 50 minute pomodoro, pomodoro technique, 3 hour timer, study with me 3 hours, twilight ambience, pomodoro adhd, çalışma zamanlayıcısı

**Description — paste ABOVE the Upload-defaults text.** The standing block (channel blurb,
originality declaration, hashtags) lives in Upload defaults and pre-fills every video; only the
head below changes per video, and it goes FIRST because the opening two lines are what appear in
search and above the "…more" fold.

```
3 hours Study With Me custom timer — 50/15 focus blocks with ocean waves under a twilight sky.
A calm, no-talking study timer for deep focus, ADHD, exam revision, coding and long work sessions.

3 focus blocks of 50 minutes, a 15-minute break after each, and a soft bell on every change. The sky moves the whole way through — this session deepens from the last light into dusk as you work.

⏱ Chapters
00:00:00 Focus 1
00:50:00 Break 1
01:05:00 Focus 2
01:55:00 Break 2
02:10:00 Focus 3

```

> ⚠️ No preset link: this channel cannot post links yet (advanced features pending). Flip
> `LINKS_OK = true` at the top of gen-roadmap.cjs the day verification lands and regenerate —
> every row gains its deep link. Preset for this row: `https://sustaintimer.com/?mode=custom&phase=twilight&sound=ocean`

</details>

<details>
<summary><code>C50-15x3h_twilight_bell</code> — 3-Hour Study With Me 🔔 50/15 Pomodoro Timer, No Music for Deep Focus & ADHD | Twilight</summary>

**Setup:** Custom · By count · work **150m** · breaks **2** · break length **15m** · Time of day → Twilight · ALL sounds OFF — bell only

**Verified length: 3 hours exactly.**

**Title:** 3-Hour Study With Me 🔔 50/15 Pomodoro Timer, No Music for Deep Focus & ADHD | Twilight

**Extra tags** — paste after the Upload-defaults tags (175/219 chars):

> 50/15 pomodoro, 50 minute pomodoro, pomodoro technique, 3 hour timer, study with me 3 hours, twilight ambience, pomodoro adhd, pomodoro no music, silent study timer, ポモドーロタイマー

**Description — paste ABOVE the Upload-defaults text.** The standing block (channel blurb,
originality declaration, hashtags) lives in Upload defaults and pre-fills every video; only the
head below changes per video, and it goes FIRST because the opening two lines are what appear in
search and above the "…more" fold.

```
3 hours Study With Me custom timer — 50/15 focus blocks with no music, bell only under a twilight sky.
A calm, no-talking study timer for deep focus, ADHD, exam revision, coding and long work sessions.

3 focus blocks of 50 minutes, a 15-minute break after each, and a soft bell on every change. The sky moves the whole way through — this session deepens from the last light into dusk as you work.

⏱ Chapters
00:00:00 Focus 1
00:50:00 Break 1
01:05:00 Focus 2
01:55:00 Break 2
02:10:00 Focus 3

```

> ⚠️ No preset link: this channel cannot post links yet (advanced features pending). Flip
> `LINKS_OK = true` at the top of gen-roadmap.cjs the day verification lands and regenerate —
> every row gains its deep link. Preset for this row: `https://sustaintimer.com/?mode=custom&phase=twilight&sound=`

</details>

<details>
<summary><code>C40-10x4h_predawn_snd-brz</code> — 4-Hour Study With Me 🍃 40/10 Pomodoro Timer for Deep Focus & ADHD | Sand & Breeze, Pre-Dawn</summary>

**Setup:** Custom · By count · work **200m** · breaks **4** · break length **10m** · Time of day → Pre-dawn · Sand + Shore breeze

**Verified length: 4 hours exactly.**

**Title:** 4-Hour Study With Me 🍃 40/10 Pomodoro Timer for Deep Focus & ADHD | Sand & Breeze, Pre-Dawn

**Extra tags** — paste after the Upload-defaults tags (139/219 chars):

> 40/10 pomodoro, 40 minute pomodoro, pomodoro technique, 4 hour timer, study with me 4 hours, pre-dawn ambience, pomodoro adhd, अध्ययन टाइमर

**Description — paste ABOVE the Upload-defaults text.** The standing block (channel blurb,
originality declaration, hashtags) lives in Upload defaults and pre-fills every video; only the
head below changes per video, and it goes FIRST because the opening two lines are what appear in
search and above the "…more" fold.

```
4 hours Study With Me custom timer — 40/10 focus blocks with sand & breeze under a pre-dawn sky.
A calm, no-talking study timer for deep focus, ADHD, exam revision, coding and long work sessions.

5 focus blocks of 40 minutes, a 10-minute break after each, and a soft bell on every change. The sky moves the whole way through — this session begins in the dark hour before dawn and eases toward first light as you work.

⏱ Chapters
00:00:00 Focus 1
00:40:00 Break 1
00:50:00 Focus 2
01:30:00 Break 2
01:40:00 Focus 3
02:20:00 Break 3
02:30:00 Focus 4
03:10:00 Break 4
03:20:00 Focus 5

```

> ⚠️ No preset link: this channel cannot post links yet (advanced features pending). Flip
> `LINKS_OK = true` at the top of gen-roadmap.cjs the day verification lands and regenerate —
> every row gains its deep link. Preset for this row: `https://sustaintimer.com/?mode=custom&phase=pre-dawn&sound=sand,breeze`

</details>

<details>
<summary><code>C40-10x4h_predawn_bell</code> — 4-Hour Study With Me 🔔 40/10 Pomodoro Timer, No Music for Deep Focus & ADHD | Pre-Dawn</summary>

**Setup:** Custom · By count · work **200m** · breaks **4** · break length **10m** · Time of day → Pre-dawn · ALL sounds OFF — bell only

**Verified length: 4 hours exactly.**

**Title:** 4-Hour Study With Me 🔔 40/10 Pomodoro Timer, No Music for Deep Focus & ADHD | Pre-Dawn

**Extra tags** — paste after the Upload-defaults tags (189/219 chars):

> 40/10 pomodoro, 40 minute pomodoro, pomodoro technique, 4 hour timer, study with me 4 hours, pre-dawn ambience, pomodoro adhd, pomodoro no music, silent study timer, temporizador de estudio

**Description — paste ABOVE the Upload-defaults text.** The standing block (channel blurb,
originality declaration, hashtags) lives in Upload defaults and pre-fills every video; only the
head below changes per video, and it goes FIRST because the opening two lines are what appear in
search and above the "…more" fold.

```
4 hours Study With Me custom timer — 40/10 focus blocks with no music, bell only under a pre-dawn sky.
A calm, no-talking study timer for deep focus, ADHD, exam revision, coding and long work sessions.

5 focus blocks of 40 minutes, a 10-minute break after each, and a soft bell on every change. The sky moves the whole way through — this session begins in the dark hour before dawn and eases toward first light as you work.

⏱ Chapters
00:00:00 Focus 1
00:40:00 Break 1
00:50:00 Focus 2
01:30:00 Break 2
01:40:00 Focus 3
02:20:00 Break 3
02:30:00 Focus 4
03:10:00 Break 4
03:20:00 Focus 5

```

> ⚠️ No preset link: this channel cannot post links yet (advanced features pending). Flip
> `LINKS_OK = true` at the top of gen-roadmap.cjs the day verification lands and regenerate —
> every row gains its deep link. Preset for this row: `https://sustaintimer.com/?mode=custom&phase=pre-dawn&sound=`

</details>

<details>
<summary><code>C30-15x2h_midday_all4</code> — 2-Hour Study With Me 🍃 30/15 Pomodoro Timer for Deep Focus & ADHD | Full Shore Ambience & Midday</summary>

**Setup:** Custom · By count · work **90m** · breaks **2** · break length **15m** · Time of day → Midday · Sand + Ocean + Shore breeze + Seabirds

**Verified length: 2 hours exactly.**

**Title:** 2-Hour Study With Me 🍃 30/15 Pomodoro Timer for Deep Focus & ADHD | Full Shore Ambience & Midday

**Extra tags** — paste after the Upload-defaults tags (137/219 chars):

> 30/15 pomodoro, 30 minute pomodoro, pomodoro technique, 2 hour timer, study with me 2 hours, midday ambience, pomodoro adhd, مؤقت للدراسة

**Description — paste ABOVE the Upload-defaults text.** The standing block (channel blurb,
originality declaration, hashtags) lives in Upload defaults and pre-fills every video; only the
head below changes per video, and it goes FIRST because the opening two lines are what appear in
search and above the "…more" fold.

```
2 hours Study With Me custom timer — 30/15 focus blocks with full shore ambience under a midday sky.
A calm, no-talking study timer for deep focus, ADHD, exam revision, coding and long work sessions.

3 focus blocks of 30 minutes, a 15-minute break after each, and a soft bell on every change. The sky moves the whole way through — this session drifts from late morning into afternoon as you work.

⏱ Chapters
00:00:00 Focus 1
00:30:00 Break 1
00:45:00 Focus 2
01:15:00 Break 2
01:30:00 Focus 3

```

> ⚠️ No preset link: this channel cannot post links yet (advanced features pending). Flip
> `LINKS_OK = true` at the top of gen-roadmap.cjs the day verification lands and regenerate —
> every row gains its deep link. Preset for this row: `https://sustaintimer.com/?mode=custom&phase=midday&sound=`

</details>

<details>
<summary><code>C30-15x2h_midday_bell</code> — 2-Hour Study With Me 🔔 30/15 Pomodoro Timer, No Music for Deep Focus & ADHD | Midday</summary>

**Setup:** Custom · By count · work **90m** · breaks **2** · break length **15m** · Time of day → Midday · ALL sounds OFF — bell only

**Verified length: 2 hours exactly.**

**Title:** 2-Hour Study With Me 🔔 30/15 Pomodoro Timer, No Music for Deep Focus & ADHD | Midday

**Extra tags** — paste after the Upload-defaults tags (186/219 chars):

> 30/15 pomodoro, 30 minute pomodoro, pomodoro technique, 2 hour timer, study with me 2 hours, midday ambience, pomodoro adhd, pomodoro no music, silent study timer, temporizador de estudo

**Description — paste ABOVE the Upload-defaults text.** The standing block (channel blurb,
originality declaration, hashtags) lives in Upload defaults and pre-fills every video; only the
head below changes per video, and it goes FIRST because the opening two lines are what appear in
search and above the "…more" fold.

```
2 hours Study With Me custom timer — 30/15 focus blocks with no music, bell only under a midday sky.
A calm, no-talking study timer for deep focus, ADHD, exam revision, coding and long work sessions.

3 focus blocks of 30 minutes, a 15-minute break after each, and a soft bell on every change. The sky moves the whole way through — this session drifts from late morning into afternoon as you work.

⏱ Chapters
00:00:00 Focus 1
00:30:00 Break 1
00:45:00 Focus 2
01:15:00 Break 2
01:30:00 Focus 3

```

> ⚠️ No preset link: this channel cannot post links yet (advanced features pending). Flip
> `LINKS_OK = true` at the top of gen-roadmap.cjs the day verification lands and regenerate —
> every row gains its deep link. Preset for this row: `https://sustaintimer.com/?mode=custom&phase=midday&sound=`

</details>

<details>
<summary><code>C60-20x5h_sunrise_ocn-snd</code> — 5-Hour Study With Me 🌊 60/20 Pomodoro Timer for Deep Focus & ADHD | Ocean & Sand, Sunrise</summary>

**Setup:** Custom · By count · work **240m** · breaks **3** · break length **20m** · Time of day → Sunrise · Ocean + Sand

**Verified length: 5 hours exactly.**

**Title:** 5-Hour Study With Me 🌊 60/20 Pomodoro Timer for Deep Focus & ADHD | Ocean & Sand, Sunrise

**Extra tags** — paste after the Upload-defaults tags (135/219 chars):

> 60/20 pomodoro, 60 minute pomodoro, pomodoro technique, 5 hour timer, study with me 5 hours, sunrise ambience, pomodoro adhd, 핑크 노이즈 공부

**Description — paste ABOVE the Upload-defaults text.** The standing block (channel blurb,
originality declaration, hashtags) lives in Upload defaults and pre-fills every video; only the
head below changes per video, and it goes FIRST because the opening two lines are what appear in
search and above the "…more" fold.

```
5 hours Study With Me custom timer — 60/20 focus blocks with ocean & sand under a sunrise sky.
A calm, no-talking study timer for deep focus, ADHD, exam revision, coding and long work sessions.

4 focus blocks of 60 minutes, a 20-minute break after each, and a soft bell on every change. The sky moves the whole way through — this session begins at first light and warms into full morning as you work.

⏱ Chapters
00:00:00 Focus 1
01:00:00 Break 1
01:20:00 Focus 2
02:20:00 Break 2
02:40:00 Focus 3
03:40:00 Break 3
04:00:00 Focus 4

```

> ⚠️ No preset link: this channel cannot post links yet (advanced features pending). Flip
> `LINKS_OK = true` at the top of gen-roadmap.cjs the day verification lands and regenerate —
> every row gains its deep link. Preset for this row: `https://sustaintimer.com/?mode=custom&phase=sunrise&sound=ocean,sand`

</details>

<details>
<summary><code>C60-20x5h_sunrise_bell</code> — 5-Hour Study With Me 🔔 60/20 Pomodoro Timer, No Music for Deep Focus & ADHD | Sunrise</summary>

**Setup:** Custom · By count · work **240m** · breaks **3** · break length **20m** · Time of day → Sunrise · ALL sounds OFF — bell only

**Verified length: 5 hours exactly.**

**Title:** 5-Hour Study With Me 🔔 60/20 Pomodoro Timer, No Music for Deep Focus & ADHD | Sunrise

**Extra tags** — paste after the Upload-defaults tags (178/219 chars):

> 60/20 pomodoro, 60 minute pomodoro, pomodoro technique, 5 hour timer, study with me 5 hours, sunrise ambience, pomodoro adhd, pomodoro no music, silent study timer, timer belajar

**Description — paste ABOVE the Upload-defaults text.** The standing block (channel blurb,
originality declaration, hashtags) lives in Upload defaults and pre-fills every video; only the
head below changes per video, and it goes FIRST because the opening two lines are what appear in
search and above the "…more" fold.

```
5 hours Study With Me custom timer — 60/20 focus blocks with no music, bell only under a sunrise sky.
A calm, no-talking study timer for deep focus, ADHD, exam revision, coding and long work sessions.

4 focus blocks of 60 minutes, a 20-minute break after each, and a soft bell on every change. The sky moves the whole way through — this session begins at first light and warms into full morning as you work.

⏱ Chapters
00:00:00 Focus 1
01:00:00 Break 1
01:20:00 Focus 2
02:20:00 Break 2
02:40:00 Focus 3
03:40:00 Break 3
04:00:00 Focus 4

```

> ⚠️ No preset link: this channel cannot post links yet (advanced features pending). Flip
> `LINKS_OK = true` at the top of gen-roadmap.cjs the day verification lands and regenerate —
> every row gains its deep link. Preset for this row: `https://sustaintimer.com/?mode=custom&phase=sunrise&sound=`

</details>
