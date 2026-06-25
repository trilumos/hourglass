# Sustain — Play Store visual assets

Tools to produce the store graphics + the plan for the screenshots. Open the `.html` files in
**Chrome while online** (so the Geist brand font loads), then use their **Download PNG** buttons.

## What Google Play needs

| Asset | Spec | Status / source |
|-------|------|-----------------|
| **App icon** | 512×512 PNG | ✅ exists — `icon images/android_icon/play_store_512.png`. |
| **Feature graphic** | 1024×500 PNG/JPG | Use [`feature-graphic.html`](feature-graphic.html) → Download PNG. |
| **Phone screenshots** | **2–8 required**, PNG/JPG, 9:16, **1080×1920** recommended | Capture on device → frame with [`screenshot-frame.html`](screenshot-frame.html). |
| **7" tablet screenshots** | up to 8, **optional but recommended** (1200×1920) | Same captures, reframed at the 7" size. |
| **10" tablet screenshots** | up to 8, **optional but recommended** (1600×2560) | Same captures, reframed at the 10" size. |

> Tablet screenshots are optional, but **without them Sustain looks worse / ranks lower on tablets.**
> You don't need a tablet to make them — the framer renders any capture at tablet dimensions.

## Division of work (honest)

- **I built** the feature graphic and the screenshot framer (brand colours, captions, exact sizes).
- **You capture** the raw in-app screens on your device — I can't (no device, and on-device is your
  half of the iron rule). Then drop each capture into the framer.

## Capture checklist (raw screens on your device)

Capture at a clean 1080×1920-ish portrait. On Windows:
`adb shell screencap -p /sdcard/s.png` then `adb pull /sdcard/s.png`, or just the phone's screenshot.

Some screens are **Pro** — to capture them, run a **debug** build with Settings → "Dev: unlock Pro"
(or use a Pro test account). Use a seeded/representative data set so charts look alive, not empty.

The 8 shots + captions (the framer golds the text inside `*stars*`):

1. **Home + hourglass** — `Train your focus *like an athlete*`
2. **Live session (hourglass draining)** — `Deep focus, *one honest block* at a time`
3. **Setup / intention** — `Set an intention. *Pick your mode.*`
4. **Insights dashboard** — `Watch your focus *grow over time*`  *(Pro view looks richest)*
5. **Focus Score** — `A score that reflects *real focus ability*`
6. **Themes grid** — `Make it yours — *calm color themes*`
7. **Recovery / Stamina** — `Recover *like an athlete*, too`
8. **Privacy / FAQ** — `*No ads. No accounts. No tracking.*`

Do the **phone** set first (required). Then reload each capture in the framer at **Tablet 7"** and
**Tablet 10"** and re-download — same images, tablet dimensions.

## Tips

- Keep the **first 2–3 shots** the strongest — most people only see those in search.
- Status bar: capture with a clean status bar (full battery, no clutter) or crop it.
- Keep captions short; the gold accent (`*…*`) on one phrase per caption reads best.
