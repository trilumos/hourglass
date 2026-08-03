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
5. Tick `☐ → ☑` and drop the YouTube video ID in the last column.

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
