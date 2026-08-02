# Streaming `/stage` with OBS

How to capture the Sustain living world for YouTube Live (or a local recording). Companion to the
platform-strategy spec §10 ("YouTube — marketing, never income") and master spec §18.7.

> **The site is the studio. We do not build a second render engine.** A 4-hour video is ~864,000 frames;
> offline rendering is *strictly slower* than real-time and you would wait 4 hours either way.

---

## 1. The one rule that matters

**Capture `/stage` with a Browser Source. Never with Window Capture or Display Capture.**

Window/Display Capture screen-scrapes a browser window. When that window loses focus the browser throttles
it — timers slow, rAF stops, the tab may be discarded — which is the root cause of the freeze/black-screen
glitch (strategy §10). A **Browser Source renders the page inside OBS**, so it is immune to focus throttling
and keeps rendering whether or not anything is in front of it.

## 2. Add the source

**Sources → + → Browser**

| Setting | Value | Why |
|---|---|---|
| URL | `https://<domain>/stage?record=1&flow=240` | see §4 for the parameters |
| Width × Height | `1920` × `1080` | match the canvas exactly; do not scale the source in OBS |
| FPS | `60`, or `30` | the scene is slow — 30 halves encode cost with almost no visible loss |
| Custom CSS | *(clear the default)* | OBS injects a transparent-background rule that is not wanted here |
| Shutdown source when not visible | **OFF** | otherwise the scene reloads on every scene switch and the day cycle restarts |
| Refresh browser when scene becomes active | **OFF** | same reason |
| Control audio via OBS | ON *(only if you want scene audio — see §5)* | |

Then **right-click the source → Transform → Fit to screen**.

## 3. Encoder settings

**Settings → Output → Output Mode: Advanced → Streaming**

| | RTX 40/50 series | Other NVIDIA | No NVIDIA |
|---|---|---|---|
| Encoder | NVENC **AV1** | NVENC H.264 | x264 |
| Bitrate (CBR) | **8000 Kbps** | **9000 Kbps** | 6000 Kbps |
| Preset | P5 (Quality) | P5 (Quality) | `veryfast` |

- **Rate control: CBR.** Not VBR — live platforms want a constant rate.
- **Keyframe interval: 2 seconds.** Required by YouTube; not "auto".
- **Profile: high.** Look-ahead off, psycho-visual tuning on.
- AV1 gives roughly 40% better quality at the same bitrate, so prefer it if the GPU supports it.

**Settings → Video:** Base and Output resolution both `1920×1080`, downscale filter irrelevant (no scaling),
FPS matching the Browser Source.

Two practical notes:
- **A clean 8000 Kbps stream that never drops looks better than a 12000 Kbps one that buffers.** Your upload
  should be at least double the bitrate.
- This scene is mostly slow gradients and a fine sand stream. Gradients are where low bitrates show banding,
  so do not go below ~6000 Kbps at 1080p even though the motion is gentle.

## 4. `/stage` URL parameters

| Parameter | Default | What it does |
|---|---|---|
| `record=1` | off | Capture preset: hides the cursor, stops the breathing zoom, removes idle motion |
| `flow=<minutes>` | `240` | Focus block length. The sand drains across it |
| `loop=1` \| `0` | `1` | Start another block when one ends. Keep `1` for 24/7 — otherwise you film a finished hourglass |
| `phase=` | `follow` | `follow` (real local time) or `pre-dawn` `sunrise` `midday` `sunset` `twilight` `midnight` |
| `timer=1` | `0` | Show the clock numerals. Off by default — on a stream the hourglass *is* the timer |

Examples:

```
/stage?record=1                                  live day cycle, 4 h blocks, no numerals
/stage?record=1&phase=midnight&flow=120          fixed night scene, 2 h blocks
/stage?record=1&phase=sunset&timer=1             golden hour with the countdown showing
```

`phase=follow` means a 24/7 stream watches the real sun rise and set. A fixed `phase` is better for a
themed VOD ("2 hours of rain at midnight").

## 5. Audio

`/stage` does **not** start the scene's ambient audio. Browsers block audio until a user gesture, and a
Browser Source never receives one. This is deliberate, not a bug:

- For a music stream you want your own licensed track in OBS anyway (add it as a **Media Source**), and
  Sustain ships **no in-house music** by design (strategy §6.1.4).
- If you specifically want the ocean/sand/birds bed, add those files as OBS Media Sources with loop enabled.
  They are in `web-astro/public/assets/audio/`.

## 6. Long runs

- Browser sources can leak memory over many hours. For 24/7, restart the stream on a schedule (daily is
  ample) rather than trusting an unbounded run.
- Disable Windows sleep, display sleep and any GPU power-saving profile.
- Do a **10-minute test recording first** and scrub it: check for banding in the sky gradient, that the sand
  stream reads cleanly, and that the day cycle is moving.

## 7. Publishing

Stream to YouTube Live; it auto-archives as a VOD. Per strategy §10, **treat this as customer acquisition at
~$0 CAC, never as revenue** — the research there is blunt that lofi streams monetise badly (College Music
converted 38M watch-minutes into ~$1,300 lifetime).

The payoff is the link-back: **every description links the exact preset URL that produced the video**, e.g.
`sustaintimer.com/?flow=240`. The video is the ad, and the ad is the product.
