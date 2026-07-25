# Sustain — Lyria 3 music prompts (44)

> **⏸️ SHELVED 2026-07-25.** In-house music is dropped (platform strategy §6.1.3): Lyria was unreliable,
> AI tracks can't be owned/sold, and there's no need — the free tier is **world ambience + a free Spotify
> embed**. Kept only as a reference if we ever commission or self-produce owned music (years out). Not
> active work.

Working document for generating a focus-music library with **Lyria 3 in the Gemini app**.

---

## How to use this

1. **Test on `lyria-3-clip-preview`** (fast), then generate keepers on **`lyria-3-pro-preview`** for the full 3 minutes. Google's own advice — iterate cheap, commit once.
2. **Pick by this test:** scrub to **0:30, 1:30 and 2:30**. If they sound interchangeable, it loops invisibly. If one section is noticeably busier — even if it's the nicest part — discard it.
3. **A clean 60 seconds is enough.** The crossfade-stacking in `setup.html` makes any uniform stretch loop forever, so a take with a gap at 2:05 is still usable. Note roughly where it sounds best.
4. **Keep the SynthID watermark.** Inaudible, doesn't affect rights, and stripping provenance markers is not something we do.

## Why these prompts are written this way

Built on Google's documented Lyria 3 Pro formula:

> `[Genre and style] + [Mood] + [Instrumentation] + [Tempo and rhythm] + [Vocal style] + [Lyrics]`

| Rule | Reason |
|---|---|
| Every prompt ends with **`Instrumental.`** | Lyria adds vocals by default. Their own docs require this word. |
| **No `[00:00]` timestamps** | Timestamps are a *structural* feature — Lyria reads them as section markers and renders a transition (an audible gap) at each one. This was the cause of the mid-track silences. |
| Continuity stated **in prose** instead | "One continuous unbroken take… no sections, no silence" is what actually holds the texture flat. |
| **"No drop, no riser, no build, no breakdown"** on every rhythmic prompt | EDM genres are *structurally defined* by these. Lyria produces them unless forbidden. We want the sustained groove a club DJ loops, never the arc. |
| **"No synthesizers, no synth pads"** on acoustic prompts | Lyria defaults to synth pads for anything tagged *ambient* — it's the genre convention. Name the exclusion or it returns. |
| **"No bass line"** on ambient prompts | Otherwise a sustained low synth appears under everything. With acoustic sources the low end comes from the instrument body instead — which also keeps the low band clear for the ocean ambience. |
| **Never name artists** | Google filters them, and it invites an argument we don't want on tracks we ship. Describe the sound, not the person. |

**Avoid these words:** *epic, emotional, cinematic, journey, builds, drops* — each one asks for the arc we're preventing.

## Licence position

Lyria 3 output: **users retain rights and Google offers copyright indemnification.** Suitable for the **free tier**.

⚠️ **Not suitable for paid packs.** Fully AI-generated music likely can't be copyrighted (US Copyright Office requires human authorship), so we'd own nothing and anyone could lawfully copy it. Paid music must be **commissioned with a full buyout** or **self-produced**. See platform strategy §6.1.3.

---

# A · Beatless & acoustic — deep study, night work

### 1 · Bowed Strings
> Ambient instrumental for deep focus. The mood is calm, spacious and unhurried. Features slow bowed cello and viola drones, gentle string ensemble swells, and natural room reverb. No synthesizers, no synth pads, no bass line, no percussion. Slow and beatless around 60 BPM. Instrumental.
> One single continuous unbroken take. No sections, no transitions, no pauses, no silence at any point. Same density and volume throughout — no intro, no outro, no build, no fade.

### 2 · Harmonium
> Ambient instrumental for concentration. The mood is warm, still and intimate. Features a softly bellowed harmonium, faint tape saturation, and gentle acoustic room tone. No synthesizers, no synth pads, no bass line, no percussion. Very slow and sustained. Instrumental.
> A single unbroken continuous recording, no sections or transitions. Never any silence or gap. Same density and volume throughout, no build, no fade.

### 3 · Felt Piano
> Minimal neoclassical instrumental for focus. The mood is contemplative and unhurried. Features soft felt piano with long spaces between notes and quiet sustained strings underneath, natural reverb. No synthesizers, no pads, no bass line, no percussion. Around 55 BPM. Instrumental.
> One continuous unbroken take, no sections or transitions. The sustained strings never stop — they hold underneath the piano at all times so there is never a true gap, only space between notes. Same intensity throughout, no build, no ending.

### 4 · Ebow Guitar
> Ambient instrumental for studying. The mood is weightless, soft and patient. Features ebow electric guitar swells with long reverb and tape delay, and faint acoustic guitar harmonics. No synthesizers, no synth pads, no bass, no drums. Slow and beatless. Instrumental.
> One continuous unbroken take. No sections, no transitions, no silence at any point. The swells overlap so sound is always present. Same density throughout, no build, no fade.

### 5 · Cathedral Organ
> Ambient instrumental for deep work. The mood is vast, solemn and still, never dramatic or cinematic. Features sustained pipe organ chords in a low register with long natural cathedral reverb. No synthesizers, no percussion, no bass line, no melody. Extremely slow, beatless. Instrumental.
> One continuous unbroken take. Chords sustain and overlap so there is never a gap or silence. No sections, no build, no crescendo, no fade.

### 6 · Night Cello
> Dark ambient instrumental for late-night focus. The mood is calm and enveloping, never tense or eerie. Features low sustained cello and double bass drones with soft bow noise, and distant room reverb. No synthesizers, no percussion, nothing bright or piercing. Beatless. Instrumental.
> One continuous unbroken take, no sections or transitions, no silence at any point. Same low intensity throughout, no build, no fade.

# B · Beatless with subtle motion

### 7 · Seascape Dusk *(matches the Seascape world)*
> Slow ambient instrumental evoking a calm sea at dusk. The mood is muted, distant and peaceful. Features warm sustained strings, faint harmonium, and gentle harmonic drift. No synthesizers, no percussion, no water or wave sound effects. Beatless, around 60 BPM. Instrumental.
> One continuous unbroken take. No sections, no transitions, no silence. Uniform density and brightness throughout, no build, no fade.

### 8 · Tape Loop
> Lo-fi ambient instrumental for focus. The mood is nostalgic, warm and hazy. Features a short looping tape phrase of muted piano, heavy tape saturation, wow and flutter, and soft vinyl crackle. No drums, no bass line, no synthesizers. Slow and repetitive. Instrumental.
> One continuous unbroken take. The loop repeats without variation and never stops. No sections, no silence, no build, no fade.

### 9 · Rain Window *(no rain SFX — the ambience layer supplies weather)*
> Ambient instrumental for quiet concentration. The mood is soft, grey and comforting. Features muted felt piano, distant sustained strings, and gentle tape hiss. No synthesizers, no percussion, no bass, no rain or weather sound effects. Slow and beatless. Instrumental.
> One continuous unbroken take with no sections or transitions and no silence at any point. Same density throughout, no build, no fade.

# C · Gentle pulse — long sessions

### 10 · Rhodes, No Drums
> Lo-fi ambient study music with no drums. The mood is cosy, warm and low-key. Features soft Rhodes electric piano chords with tape saturation, gentle vinyl crackle, and a muted low note. Slow and repetitive around 70 BPM, no drum beat, no melody hook. Instrumental.
> One continuous unbroken take. The chord cycle repeats without variation and never stops. No sections, no silence, no build, no fade.

### 11 · Warm Pulse
> Downtempo ambient instrumental for work. The mood is steady, warm and understated. Features a soft muted pulse on muted guitar, warm sustained strings, and light tape texture. Gentle rhythmic movement around 75 BPM, no drum kit, no bass line. Instrumental.
> One continuous unbroken take. The pulse is constant and never stops. No sections, no transitions, no silence, no build, no fade.

### 12 · Marimba Minimal
> Minimalist instrumental for focus, in the style of process music. The mood is bright but calm, patient and mechanical. Features soft marimba and vibraphone playing a short repeating interlocking pattern, with light room reverb. No synthesizers, no drums, no bass. Steady around 90 BPM. Instrumental.
> One continuous unbroken take. The pattern repeats without variation from start to finish. No sections, no silence, no build, no fade.

# D · Rhythmic productivity — CEO Mode, Hyperfocus

*(These intentionally use synth — it is the genre.)*

### 13 · CEO Mode
> Deep house instrumental for focused work. The mood is confident, sleek and composed, never euphoric. Features a soft four-on-the-floor kick, warm filtered pads with gentle sidechain ducking, muted plucked chords, and restrained sub bass. Steady 122 BPM, no vocal hooks, no drops, no risers. Instrumental.
> One continuous unbroken take with the full groove present from the first bar. No sections, no breakdown, no drop, no build, no silence, no fade.

### 14 · Hyperfocus / Fluxwork
> Minimal techno and ambient hybrid for sustained concentration. The mood is steady, hypnotic and unobtrusive. Features a soft understated four-on-the-floor kick, gently sidechained warm pads, a subtle repeating arpeggio low in the mix, and soft filtered hats with no sharp transients. Steady 120 BPM. Instrumental.
> One continuous unbroken take. The arpeggio repeats without variation. No sections, no filter sweep, no build, no silence, no fade.

### 15 · Coding Flow
> Minimal electronic instrumental for long coding sessions. The mood is neutral, clean and unobtrusive — never emotional. Features a quiet steady kick, muted percussive clicks, a simple repeating bass pulse, and thin sustained pads far back in the mix. Steady 118 BPM, no melody, no vocal samples. Instrumental.
> One continuous unbroken take. Every element repeats without variation. No sections, no build, no drop, no silence, no fade.

### 16 · Night Drive
> Downtempo electronic instrumental for late focus. The mood is cool, dark and steady. Features a soft muffled kick, warm analog bass pulse, muted chord stabs, and distant reverb. Steady 105 BPM, no vocals, no lead melody, no risers. Instrumental.
> One continuous unbroken take with the groove present from the first bar. No sections, no breakdown, no build, no silence, no fade.

# E · Pure texture

### 17 · Warm Noise Bed
> Ambient texture for deep concentration. The mood is neutral, soft and enveloping. Features a warm filtered noise bed, faint low harmonic hum, and very slow gentle movement. No melody, no chords, no percussion, no synthesizer leads. Completely beatless. Instrumental.
> One continuous unbroken take with no sections, no transitions and no silence. Absolutely uniform from start to finish, no build, no fade.

### 18 · Held Chord
> Drone ambient instrumental for hyperfocus. The mood is still, warm and hypnotic. Features one sustained low string and harmonium chord that barely shifts, with deep natural reverb. No rhythm, no percussion, no melody, no synthesizers. Beatless. Instrumental.
> One continuous unbroken take. The chord sustains without stopping for the entire duration. No sections, no silence, no swell, no build, no fade.

---

# F · Modern & melodic — moderate drive

### 19 · Melodic Techno
> Melodic techno instrumental for focused work. The mood is hypnotic, dark and driving but never aggressive. Features a steady four-on-the-floor kick, a rolling analog bassline, a repeating arpeggiated synth motif, and reverb-drenched chord stabs. Steady 124 BPM. Instrumental.
> One continuous unbroken take with the full groove present from the first bar. No intro, no breakdown, no drop, no riser, no build. Every element repeats without variation. No sections, no silence, no fade.

### 20 · Progressive House
> Progressive house instrumental for deep work. The mood is uplifting but restrained, forward-moving and clean. Features a warm four-on-the-floor kick, a plucky repeating arpeggio, wide sidechained pads, and a smooth sub bass. Steady 126 BPM, no vocal hooks. Instrumental.
> One continuous unbroken take, full groove from the first bar. No intro, no breakdown, no drop, no riser, no filter sweep. Everything repeats without variation. No sections, no silence, no fade.

### 21 · Future Garage
> Future garage instrumental for focus. The mood is atmospheric, cool and spacious. Features syncopated halftime drums, deep sub bass, muffled chord stabs, and washed reverb pads. Steady 140 BPM with a halftime feel. Instrumental.
> One continuous unbroken take with the beat present from the first bar. No intro, no drop, no build, no breakdown. The drum pattern repeats without variation. No sections, no silence, no fade.

### 22 · Synthwave
> Synthwave instrumental for productive work. The mood is nocturnal, cool and steady, never epic. Features gated drum machine hits, a pulsing analog bass arpeggio, warm retro pads, and light tape saturation. Steady 110 BPM, no lead melody hook, no vocals. Instrumental.
> One continuous unbroken take with the full arrangement from the first bar. No intro, no build, no drop, no climax. Every part repeats identically. No sections, no silence, no fade.

### 23 · Chillstep
> Melodic chillstep instrumental for concentration. The mood is warm, wide and emotive but calm. Features halftime drums with soft snares, deep rolling sub bass, lush sustained pads, and faint bell textures. Steady 140 BPM, halftime feel, no vocals. Instrumental.
> One continuous unbroken take, full texture from the first bar. No intro, no build, no drop, no breakdown. Repeats without variation. No sections, no silence, no fade.

# G · Club-rooted — steady drive

### 24 · Tech House
> Tech house instrumental for fast focused work. The mood is tight, groovy and businesslike. Features a punchy kick, a rolling syncopated bassline, crisp percussive loops, shakers and rim clicks. Steady 126 BPM, no vocal samples, no drops. Instrumental.
> One continuous unbroken take with the groove locked from the first bar. No intro, no breakdown, no drop, no build. All loops repeat without variation. No sections, no silence, no fade.

### 25 · UK Garage
> UK garage two-step instrumental for energetic work. The mood is bouncy, warm and confident. Features shuffled two-step drums with swung hats, a warm bouncing bassline, and muted organ chord stabs. Steady 135 BPM, no vocals. Instrumental.
> One continuous unbroken take, full groove from the first bar. No intro, no drop, no build, no breakdown. The shuffle repeats without variation. No sections, no silence, no fade.

### 26 · Lo-fi House
> Lo-fi house instrumental for work. The mood is dusty, warm and hypnotic. Features a muffled four-on-the-floor kick, filtered looping chords, tape hiss, and a simple round bassline. Steady 122 BPM, no vocals, no lead. Instrumental.
> One continuous unbroken take with the loop present from the first bar. No intro, no build, no drop. The chord loop repeats identically throughout. No sections, no silence, no fade.

### 27 · Nu-Disco
> Nu-disco instrumental for upbeat productive work. The mood is warm, funky and effortless. Features a live-feel four-on-the-floor kick, a funky syncopated bassline, muted rhythm guitar chops, and soft electric piano. Steady 115 BPM, no vocals, no big chorus. Instrumental.
> One continuous unbroken take, full groove from the first bar. No intro, no build, no breakdown, no drop. Every part loops without variation. No sections, no silence, no fade.

### 28 · Breakbeat
> Breakbeat instrumental for fast-paced work. The mood is punchy, propulsive and clean. Features a chopped funk drum break, a firm round bassline, and short filtered chord stabs. Steady 130 BPM, no vocals, no risers. Instrumental.
> One continuous unbroken take with the break rolling from the first bar. No intro, no drop, no build, no fill variations. Repeats identically. No sections, no silence, no fade.

### 29 · Electro / IDM
> Electro instrumental for focused technical work. The mood is precise, cool and mechanical. Features a crunchy drum machine pattern, a detuned analog bassline, and short blipping synth sequences. Steady 120 BPM, no vocals, no melody hook. Instrumental.
> One continuous unbroken take, full pattern from the first bar. No intro, no build, no drop, no variation. No sections, no silence, no fade.

# H · High tempo — maximum drive

### 30 · Liquid Drum & Bass
> Liquid drum and bass instrumental for fast focused work. The mood is rolling, warm and smooth, never harsh. Features a steady rolling breakbeat, deep smooth sub bass, warm jazzy chords, and soft atmospheric pads. Steady 174 BPM. Instrumental.
> One continuous unbroken take with the break rolling from the first bar. No intro, no drop, no build, no breakdown. The drum pattern repeats without variation. No sections, no silence, no fade.

### 31 · Atmospheric Jungle
> Atmospheric jungle instrumental for high-energy work. The mood is deep, rolling and hypnotic. Features chopped amen-style breaks, a deep warm sub bass, and wide ambient pads underneath. Steady 170 BPM, no vocals. Instrumental.
> One continuous unbroken take, breaks rolling from the first bar. No intro, no drop, no build. The break pattern repeats consistently. No sections, no silence, no fade.

### 32 · Driving Techno
> Hypnotic driving techno instrumental for intense focus. The mood is relentless, dark and steady, never chaotic. Features a hard steady kick, a repetitive percussive loop, a low rumbling bass, and faint metallic textures. Steady 135 BPM, no vocals, no melody. Instrumental.
> One continuous unbroken take with the kick and loop from the first bar. No intro, no breakdown, no drop, no build, no filter sweep. Absolutely repetitive throughout. No sections, no silence, no fade.

### 33 · Instrumental Trance
> Instrumental trance for sustained fast work. The mood is bright, forward-moving and euphoric but controlled. Features a driving four-on-the-floor kick, a rolling offbeat bassline, a repeating supersaw arpeggio, and wide pads. Steady 138 BPM, no vocals, no big drop. Instrumental.
> One continuous unbroken take, full arrangement from the first bar. No intro, no build, no riser, no drop, no breakdown. The arpeggio repeats without variation. No sections, no silence, no fade.

### 34 · Drift Phonk *(restrained)*
> Restrained phonk instrumental for high-energy work. The mood is dark, confident and rhythmic, but clean rather than distorted or aggressive. Features a punchy kick, a melodic cowbell pattern, a deep 808 bass, and muted retro samples. Steady 140 BPM, no vocals, no heavy distortion, no screaming leads. Instrumental.
> One continuous unbroken take, full groove from the first bar. No intro, no build, no drop, no breakdown. The cowbell pattern repeats without variation. No sections, no silence, no fade.

---

# I · Lofi — study beats

*Three things make these read as Lofi Girl rather than generic hip hop: the snare **behind the beat**, **vinyl crackle and tape hiss** as aesthetic rather than defect, and a **four-bar loop that never develops**.*

### 35 · Classic Lofi Hip Hop *(the archetype)*
> Lofi hip hop instrumental to study to. The mood is warm, nostalgic and slightly melancholic. Features dusty boom bap drums with a laid-back swing and the snare slightly behind the beat, warm Rhodes electric piano chords, a round upright bass, vinyl crackle and tape hiss. Steady 78 BPM. Instrumental.
> One continuous unbroken take. The same four-bar loop repeats without variation from start to finish. No intro, no build, no breakdown, no drop, no sections, no silence, no fade.

### 36 · Jazzhop
> Jazzhop instrumental for studying. The mood is smoky, relaxed and sophisticated. Features soft brushed boom bap drums, mellow jazz piano chords with extended voicings, a walking upright bass, and a distant muted trumpet holding long notes. Vinyl crackle throughout. Steady 82 BPM. Instrumental.
> One continuous unbroken take. The loop repeats identically, no melodic development or solo. No intro, no build, no sections, no silence, no fade.

### 37 · Sleepy Night Lofi
> Slow sleepy lofi hip hop for late-night study. The mood is soft, hazy and drowsy. Features gentle muffled boom bap drums, a soft Rhodes chord loop, a deep round sub bass, heavy tape saturation and vinyl noise. Very slow, around 68 BPM. Instrumental.
> One continuous unbroken take with the loop repeating identically throughout. No intro, no build, no breakdown, no sections, no silence, no fade.

### 38 · Lofi Guitar
> Lofi hip hop instrumental with guitar, for focused study. The mood is warm, gentle and unhurried. Features soft boom bap drums, a clean jazz electric guitar playing a short repeating chord phrase, a round upright bass, and light vinyl crackle. Steady 76 BPM. Instrumental.
> One continuous unbroken take. The guitar phrase loops without variation, no solo, no fills. No intro, no build, no sections, no silence, no fade.

### 39 · Rainy Day Lofi *(no rain SFX — the ambience layer supplies weather)*
> Moody lofi hip hop for a quiet grey afternoon. The mood is wistful, calm and introspective. Features soft dusty drums, minor-key Rhodes chords, a mellow sub bass, and warm tape hiss. No rain, weather or water sound effects. Steady 74 BPM. Instrumental.
> One continuous unbroken take with the same loop throughout. No intro, no build, no breakdown, no sections, no silence, no fade.

### 40 · Music Box Lofi
> Nostalgic lofi hip hop for studying. The mood is tender, childlike and bittersweet. Features a soft music box melody looping gently, muted boom bap drums far back in the mix, warm low pads, and vinyl crackle. Steady 72 BPM. Instrumental.
> One continuous unbroken take. The music box phrase repeats identically without variation. No intro, no build, no sections, no silence, no fade.

### 41 · Lofi Bossa
> Lofi bossa nova instrumental for relaxed work. The mood is warm, breezy and easy. Features softly brushed bossa drums, nylon-string acoustic guitar playing a repeating chord pattern, a round upright bass, and gentle tape warmth. Steady 84 BPM. Instrumental.
> One continuous unbroken take. The guitar pattern repeats without variation. No intro, no build, no sections, no silence, no fade.

### 42 · Upright Jazz Lofi
> Lofi jazz instrumental for concentration. The mood is intimate, late and unhurried. Features brushed drums on a soft snare, a warm walking upright bass, sparse jazz piano chords, and room tone with faint vinyl noise. Steady 80 BPM. Instrumental.
> One continuous unbroken take. The bass and chord loop repeat without variation, no solos or fills. No intro, no build, no sections, no silence, no fade.

### 43 · Minimal Study Beat *(least distracting of the set)*
> Minimal lofi hip hop for deep study. The mood is neutral, steady and unobtrusive. Features soft muffled drums low in the mix, two simple alternating Rhodes chords, a quiet round bass, and constant vinyl hiss. Almost no melody. Steady 75 BPM. Instrumental.
> One continuous unbroken take. The two-chord loop repeats without any variation at all. No intro, no build, no sections, no silence, no fade.

### 44 · Warm Rhodes Lofi
> Cosy lofi hip hop instrumental for long work sessions. The mood is comfortable, warm and low-key. Features soft swung boom bap drums, lush warm Rhodes chords with tremolo, a round sub bass, and gentle tape saturation with light crackle. Steady 79 BPM. Instrumental.
> One continuous unbroken take. The chord loop repeats identically throughout. No intro, no build, no breakdown, no sections, no silence, no fade.

---

## Tracking

| # | Name | Group | Generated | Kept | Notes |
|---|---|---|---|---|---|
| 1 | Bowed Strings | A | ☐ | ☐ | |
| 2 | Harmonium | A | ☐ | ☐ | |
| 3 | Felt Piano | A | ☐ | ☐ | |
| 4 | Ebow Guitar | A | ☐ | ☐ | |
| 5 | Cathedral Organ | A | ☐ | ☐ | |
| 6 | Night Cello | A | ☐ | ☐ | |
| 7 | Seascape Dusk | B | ☐ | ☐ | |
| 8 | Tape Loop | B | ☐ | ☐ | |
| 9 | Rain Window | B | ☐ | ☐ | |
| 10 | Rhodes, No Drums | C | ☐ | ☐ | |
| 11 | Warm Pulse | C | ☐ | ☐ | |
| 12 | Marimba Minimal | C | ☐ | ☐ | |
| 13 | CEO Mode | D | ☐ | ☐ | |
| 14 | Hyperfocus / Fluxwork | D | ☐ | ☐ | |
| 15 | Coding Flow | D | ☐ | ☐ | |
| 16 | Night Drive | D | ☐ | ☐ | |
| 17 | Warm Noise Bed | E | ☐ | ☐ | |
| 18 | Held Chord | E | ☐ | ☐ | |
| 19 | Melodic Techno | F | ☐ | ☐ | |
| 20 | Progressive House | F | ☐ | ☐ | |
| 21 | Future Garage | F | ☐ | ☐ | |
| 22 | Synthwave | F | ☐ | ☐ | |
| 23 | Chillstep | F | ☐ | ☐ | |
| 24 | Tech House | G | ☐ | ☐ | |
| 25 | UK Garage | G | ☐ | ☐ | |
| 26 | Lo-fi House | G | ☐ | ☐ | |
| 27 | Nu-Disco | G | ☐ | ☐ | |
| 28 | Breakbeat | G | ☐ | ☐ | |
| 29 | Electro / IDM | G | ☐ | ☐ | |
| 30 | Liquid Drum & Bass | H | ☐ | ☐ | |
| 31 | Atmospheric Jungle | H | ☐ | ☐ | |
| 32 | Driving Techno | H | ☐ | ☐ | |
| 33 | Instrumental Trance | H | ☐ | ☐ | |
| 34 | Drift Phonk | H | ☐ | ☐ | |
| 35 | Classic Lofi Hip Hop | I | ☐ | ☐ | |
| 36 | Jazzhop | I | ☐ | ☐ | |
| 37 | Sleepy Night Lofi | I | ☐ | ☐ | |
| 38 | Lofi Guitar | I | ☐ | ☐ | |
| 39 | Rainy Day Lofi | I | ☐ | ☐ | |
| 40 | Music Box Lofi | I | ☐ | ☐ | |
| 41 | Lofi Bossa | I | ☐ | ☐ | |
| 42 | Upright Jazz Lofi | I | ☐ | ☐ | |
| 43 | Minimal Study Beat | I | ☐ | ☐ | |
| 44 | Warm Rhodes Lofi | I | ☐ | ☐ | |

## Handing tracks over

Drop generations into `site/assets/audio/` with the prompt number in the filename (e.g. `35-classic-lofi.mp3`). For each one, note **where it sounds best** if the take isn't uniform throughout.

Each track then gets the same treatment the ambience got:
- **K-weighted loudness (ITU-R BS.1770)** measured, and per-source gain set so music sits *under* ocean and sand — RMS badly under-reads busy material.
- **Artefact scan** for persistent encoder tones (the ocean source had a 13,135 Hz whistle); anything found is notched at playback rather than re-encoded.
- **Gap detection**, then the loop region chosen from the cleanest continuous stretch.
- **Crossfade stacking** so it loops indefinitely with no seam and no pumping.
