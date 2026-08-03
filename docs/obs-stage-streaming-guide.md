# Streaming `/stage` with OBS

How to capture the Sustain living world as a YouTube VOD (or a live stream). Companion to the
platform-strategy spec §10, master spec §18.7, and the channel strategy in
`docs/superpowers/specs/2026-08-02-youtube-channel-strategy-design.md`.

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
| URL | `https://<domain>/stage?record=1` | the session itself is configured on the page — see §4 |
| Width × Height | `1920` × `1080` | match the canvas exactly; do not scale the source in OBS |
| FPS | `60`, or `30` | the scene is slow — 30 halves encode cost with almost no visible loss |
| Custom CSS | *(clear the default)* | OBS injects a transparent-background rule that is not wanted here |
| Shutdown source when not visible | **OFF** | otherwise the scene reloads on every scene switch and the day cycle restarts |
| Refresh browser when scene becomes active | **OFF** | same reason |
| Control audio via OBS | ON *(only if you want scene audio — see §6)* | |

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

## 3b. Recording settings — **this is the default workflow now**

§3 is for streaming. We publish **VODs** (§8), so the settings that actually matter are here.

**Settings → Output → Output Mode: Advanced → Recording**

| Setting | Value | Why |
|---|---|---|
| Recording Format | **Hybrid MP4** — or **MKV** if using two audio tracks (§6b) | Both survive a crash mid-recording; a plain in-progress `.mp4` does not. Hybrid MP4 removes the remux step. |
| Encoder | NVENC **AV1** (RTX 40/50) · NVENC H.264 · x264 | Same ladder as §3 |
| **Rate Control** | **CQP** — *not* CBR | CBR exists to keep a live stream at a constant rate. For a file you are uploading, CQP spends bits where the picture needs them. |
| **CQ Level** | **18** | 18–20 is the quality sweet spot; take 18 — our frame is almost entirely **gradient**, which is exactly where banding shows. |
| Preset | P5 or P6 (Quality) | |
| Profile | high | |
| Audio Bitrate | **320 kbps** | YouTube recommends 384 kbps stereo; 320 is the practical max in OBS and is transparent for ambient beds. |

**Settings → Video:** Base and Output both `1920×1080`, **30 fps**. The scene is slow; 30 halves the file and
the encode cost with no visible loss, and it keeps us in YouTube's *standard* frame-rate tier.

**Do not target YouTube's recommended upload bitrate** (8 Mbps for 1080p SDR at 30 fps, 12 Mbps at 60). That
is the floor for a *delivered* file — YouTube re-encodes everything you send it, so the job here is to hand it
the cleanest possible master. CQP 18 will land well above 8 Mbps during the sand fall and far below it while
the sky sits still. That is correct behaviour, not a misconfiguration.

**Disk.** Expect roughly **5–14 GB for a 4-hour capture**. At a session every other day that is well over
100 GB/month, so **upload and then delete the master**. Keep the OBS **scene-collection JSON** and a couple of
representative captures — that is the originality evidence (§8); the whole archive is not.

## 3c. Sanity check before the first real capture

Do a **10-minute test capture** and scrub it for three things, in this order:

1. **Banding in the sky gradient** — the single most likely quality failure. If present, drop CQ to 16.
2. **The sand stream reads cleanly** at 100% zoom.
3. **The day cycle is visibly moving** across the ten minutes.

## 4. How `/stage` works

`/stage` opens the **real Setup screen** — the same one production users see. Choose the mode (Flow,
Pomodoro, Custom, Endless), durations, intention, sounds and mixer, time of day and number look exactly as
you would on the site, then press **Begin**.

From that moment the session runs **with no interface at all**: no pause/resume, no break button, no
settings gear, no give up, no popcards, no navigation guard. The same timer engine drives everything —
segment advances, Pomodoro breaks, Endless block loops — it simply follows the configuration to the end and
then **fades to black**.

**Browser Back (or a back swipe) is the way out**, and it returns you to Setup ready to configure the next
capture.

| Parameter | What it does |
|---|---|
| `?record=1` | Capture preset: hides the cursor and stops the scene's breathing zoom |
| `?stopstream=1` | Also stop **streaming** on completion, not just recording (see §5) |

So the URL you point OBS at is simply:

```
https://<domain>/stage?record=1
```

Configure the session in the browser before you go live, and everything after Begin is clean footage.

**For a long unattended stream, pick Endless** — it loops the chosen block forever, so the capture never
reaches the fade-to-black.

## 5. Starting and stopping the recording automatically

**Press Begin and OBS starts recording.** The same click also puts the page into **fullscreen**, so the
session always fills the frame. (Begin checks `getStatus` first, so pressing it twice cannot start a second
recording.)

When the session finishes, `/stage` fades to black over ~2.4 s and then calls
**`window.obsstudio.stopRecording()`**, so the recording ends by itself on clean black. No timers to babysit,
and a trivially easy cut point in the edit.

`window.obsstudio` is injected by OBS **only inside a Browser Source**, so this does nothing in a normal
browser — it cannot misfire while you are configuring the session.

**One setting is required for it to work:**

> Browser Source properties → **Page permissions → `Full access to OBS (Start/Stop streaming without
> warning, etc.)`** — the LAST entry in the dropdown.
>
> **Not "Advanced access".** `startRecording()` / `stopRecording()` require *ALL* permissions per the
> obs-browser README, and "Advanced" (change scenes, replay buffer) is one level short. The symptom is
> exact and misleading: **Begin works and the session runs perfectly, but the record timer never starts** —
> because the page loaded fine, `window.obsstudio` exists, and only the recording calls are withheld.

Without that, OBS does not expose the control functions and the page simply fades to black without stopping
anything (harmless, just manual).

Notes:
- Recording only. Add `?stopstream=1` if you also want a **live stream** to end — usually you do *not* want
  that, since ending a YouTube Live ends the broadcast.
- Endless never completes, so it never triggers this. That is the right behaviour for a 24/7 stream.
- The stop fires ~3.2 s after completion, comfortably after the fade, so the last frames are pure black.

## 6. Audio

`/stage` does **not** start the scene's ambient audio. Browsers block audio until a user gesture, and a
Browser Source never receives one. This is deliberate, not a bug:

- For a music stream you want your own licensed track in OBS anyway (add it as a **Media Source**), and
  Sustain ships **no in-house music** by design (strategy §6.1.4).
- If you specifically want the ocean/sand/birds bed, add those files as OBS Media Sources with loop enabled.
  They are in `web-astro/public/assets/audio/`.

## 6b. Multi-track audio — OPTIONAL, and off by default

> **The default workflow is one capture = one video.** No splitting, no muxing, no editing: configure the
> roadmap row, press Begin, upload the file. The no-music videos are **their own rows** in
> `docs/youtube/video-roadmap.md` (audio column reads *ALL sounds OFF*), captured normally.
>
> **Why not the split?** Timer Palette exports each session twice (ambient + bell-only) from one recording,
> and the twin does pull ~10–30% extra views for no extra capture time. But it **doubles the titling and
> uploading**, which is the founder's scarce resource — captures are unattended, desk work is not. Not worth
> it at one capture every other day.

Keep this section for later: if the catalogue ever outgrows capture time, one recording *can* carry several
audio mixes.

**Advanced Audio Properties** (right-click any source → *Advanced Audio Properties*), tick per source:

| Source | Track 1 | Track 2 |
|---|---|---|
| Bell | ✅ | ✅ |
| Ocean / ambient bed | — | ✅ |

Then **Output → Recording → Audio Track: 1 and 2**, and record to **MKV** (multi-track MP4 is supported but
has editor-compatibility quirks; MKV has none, and we are not editing — we are splitting).

Two lossless commands, seconds each, no re-encode:

```bash
ffmpeg -i capture.mkv -map 0:v:0 -map 0:a:0 -c copy "bell-only.mp4"   # Track 1
ffmpeg -i capture.mkv -map 0:v:0 -map 0:a:1 -c copy "ocean.mp4"       # Track 2
```

This scales directly to the noise beds in phase 2 (strategy §12): brown → Track 3, pink → Track 4, and each
becomes one more upload off the *same* capture.

> **✅ Confirmed on-device 2026-08-02: the bell IS audible in the capture.** Pressing **Begin** inside the
> Browser Source counts as a user gesture in that browser context, which unblocks the page's Web Audio. So
> §6's "a Browser Source never receives one" is true only for a source you never interact with — **interact
> with it once and the scene's own audio works.** No post-mux fallback is needed.

## 7. Stopping Windows from interrupting a long capture

**First, the diagnosis.** "It logs out the user but the processes keep running" is Windows **locking**, not
signing out. A real sign-out terminates your processes; a lock leaves everything running behind the sign-in
screen. That matters because it changes the fix, and it is also **one more reason to use a Browser Source**:
a locked desktop stops composing, so Display/Window Capture records black, while a Browser Source keeps
rendering inside OBS regardless.

Work through these on the Asus TUF (Windows 11 Home):

1. **Settings → Accounts → Sign-in options → "If you've been away, when should Windows require you to sign
   in again?" → Never.** This is the usual culprit.
   *On some Windows 11 Home builds this dropdown is greyed out with "Security policies on this PC are
   preventing some options from being shown."* If so, set it directly:
   ```
   reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v InactivityTimeoutSecs /t REG_DWORD /d 0 /f
   ```
   (`0` = never; needs an admin terminal and a reboot.)

2. **Screen saver.** Search "Change screen saver" → set to **(None)** and untick **"On resume, display logon
   screen."** A screen saver with that box ticked locks the machine on its own schedule.

3. **Dynamic Lock** — Settings → Accounts → Sign-in options → Dynamic lock → **untick**. It locks the PC when
   a paired phone's Bluetooth goes out of range, which looks exactly like a random lock.

4. **Power.** Settings → System → Power & battery → Screen and sleep → set **all four** to *Never* (both
   "on battery" and "plugged in"). Then also clear the hidden console-lock timeout, which the GUI does not
   expose:
   ```
   powercfg /setacvalueindex SCHEME_CURRENT SUB_VIDEO VIDEOCONLOCK 0
   powercfg /setdcvalueindex SCHEME_CURRENT SUB_VIDEO VIDEOCONLOCK 0
   powercfg /setactive SCHEME_CURRENT
   ```

5. **MyASUS / Armoury Crate.** Asus utilities ship their own power and battery-saver profiles that override
   Windows settings. Check Armoury Crate for a power plan or "battery care" mode and disable anything that
   dims, sleeps or locks. This is the step people miss on TUF/ROG machines.

6. **Belt and braces:** install **Microsoft PowerToys** and turn on **Awake** ("Keep screen on"). It holds a
   system power request for as long as it runs and is the cleanest official way to guarantee an
   uninterrupted capture. Verify with `powercfg /requests` in an admin terminal — you should see an entry
   under DISPLAY or SYSTEM.

Then confirm: leave it for an hour longer than your longest planned capture and check the recording is
unbroken before you trust it with a real session.

## 7b. Other long-run notes

- Browser sources can leak memory over many hours. For 24/7, restart the stream on a schedule (daily is
  ample) rather than trusting an unbounded run.
- Do a **10-minute test recording first** and scrub it: check for banding in the sky gradient, that the sand
  stream reads cleanly, and that the day cycle is moving.

## 8. Publishing

**Publish discrete VODs, not a livestream.** This is the revenue decision and it is not close:

- A **livestream** serves **one pre-roll per viewer** — College Music turned 38M watch-minutes into ~$1,300
  *lifetime*. Treat a livestream as customer acquisition at ~$0 CAC, never as revenue.
- A **VOD ≥8 minutes** carries **mid-roll** breaks, and this niche averages **2–4 hours of view duration**.
  Timer Palette earns **~$3,273/month** from 592 such VODs.

So the default workflow is: **record locally with `/stage` (§5), then upload.** Reserve YouTube Live for a
24/7 Endless run used purely as a brand/subscriber surface.

**Pomodoro beats a continuous timer here**, and for a non-obvious reason: YouTube's automatic mid-roll
placement looks for *"natural visual or audio breaks."* A silent continuous timer has none; a Pomodoro
session has **a bell and a break screen every 25–50 minutes by design**. The format manufactures its own ad
slots. Keep **automatic mid-rolls on** (auto + manual together tested +5% over manual alone), and do **not**
hand-stack a break every 8 minutes — interruptive slots now earn *less*.

The second payoff is the link-back: **every description links the exact preset URL that produced the video**,
e.g. `sustaintimer.com/?mode=pomodoro&work=50&break=10&phase=sunset`. The video is the ad, and the ad is the
product.

Full strategy — catalogue grid, titles, YPP math, the 90-day plan:
`docs/superpowers/specs/2026-08-02-youtube-channel-strategy-design.md`.

**One compliance note that matters more than any encoder setting.** YouTube's **inauthentic content** policy
(renamed from "repetitious content" on 2025-07-15) demonetises mass-produced, templated, repetitive uploads.
Our defence is that each capture is a **real-time render of a real running program** — the sand, the day
cycle and the clock never repeat a frame. Therefore: **never upload the same render twice under different
titles**, never add music we do not own (a Content ID claim takes 100% of that video's revenue), and keep the
OBS project files — appeals in this area succeed on evidence of a real production process.
