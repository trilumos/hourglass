# Audio provenance

Every file here must have a clear, commercial-safe origin recorded below **before it ships**.
Accepted origins: original synthesis · our own recording · CC0 · a paid licence that covers
commercial use. Anything else does not go in this folder.

| File | Origin | Licence | Notes |
|---|---|---|---|
| `sand.m4a` / `sand.webm` | **Pixabay** — *"Pouring sand onto sand"* by **ArtificiallyInspired** ([source](https://pixabay.com/users/artificiallyinspired-30441549/), id 291368) | **Pixabay Content Licence** — commercial use allowed, **attribution not required** (credited here anyway, as good practice) | 8.1 s original. Steady 1.5–7.2 s slice only (start ramp and the loud end-dump discarded), slow gain-riding, granular reassembly to 90 s, softened, seamless loop. Built by `build_sand.py`. |
| `ocean.m4a` / `ocean.webm` | **Pixabay** — *"Ocean waves sea beach close stereo"* by **freesound_community** ([source](https://pixabay.com/users/freesound_community-46691455/), id 25857) | **Pixabay Content Licence** — commercial use allowed, attribution not required (credited anyway) | Used **as recorded**. 193.6 s original → 174 s loop, chosen so the tail already matches the head, then an 8 s equal-power crossfade. **Stereo kept** (L/R corr 0.678). No EQ, no flattening, no granulation — the 16 dB swell is the character. Built by `build_ocean.py`. |
| `breeze.*` | _pending_ | | |
| `birds.*` | _pending_ | | Bird calls do not synthesise convincingly — needs a CC0 recording |

## Spec every file must meet

- **90 s** seamless loop (crossfaded from material past the loop end, so the wrap is continuous)
- **≈ −19 dBFS RMS**, peak **≤ −6 dBFS** — a quiet bed; the UI volume slider does the rest
- **Crest ≈ 13 dB** — grains fused, nothing poking out
- **No metadata** — encoded with `-map_metadata -1 -fflags +bitexact`
- Mono, AAC `.m4a` (universal) + Opus `.webm` (smaller)

## On timbre matching

`synth_sand.py` can measure a reference recording's long-term average spectrum and shape our
own noise to that curve. Only a ~100-number tone curve is taken; **no reference audio enters the
output.** That is the difference between being influenced by a sound and copying a recording —
and it is the only way a reference may ever be used here.

## Rejected sources — do not revisit

- **YouTube / streaming rips.** A specific *recording* of a sound is copyrighted even when the
  sound itself is not, regardless of the channel's size. Stripping metadata does not transfer
  rights, and audio fingerprinting finds these routinely.
- **Free-tier AI generators.** ElevenLabs' free output is personal-use only and requires
  attribution; only paid plans carry a commercial licence.
