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

> Browser Source properties → **Page permissions → All access**

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

Stream to YouTube Live; it auto-archives as a VOD. Per strategy §10, **treat this as customer acquisition at
~$0 CAC, never as revenue** — the research there is blunt that lofi streams monetise badly (College Music
converted 38M watch-minutes into ~$1,300 lifetime).

The payoff is the link-back: **every description links the exact preset URL that produced the video**, e.g.
`sustaintimer.com`. The video is the ad, and the ad is the product.
