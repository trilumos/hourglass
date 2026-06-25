# Preview / screenshot build

Self-contained build for taking **Play Store screenshots**. Everything lives in
this folder; the real app (`lib/main.dart`) is untouched and unaffected.

## Run / build

```bash
# live on a connected device
flutter run               -t lib/preview/preview_main.dart

# or an installable APK (debug, so the Pro toggle is available)
flutter build apk --debug -t lib/preview/preview_main.dart
```

## What you get

- **Every real screen, fully navigable**, with **realistic seeded data** (an
  active ~40-day history → Focus Score, Stamina, streak, Insights charts,
  heatmap, history, personal bests all populated). Onboarding is auto-skipped.
- **USD prices** on the paywall + theme sheets: Pro **$4.99 / $29.99 / $59.99**;
  themes **$1.99**, **Aurora $3.99**.
- Starts **Free** (so the paywall, theme prices, and Insights upsells show). To
  capture the **Pro** screens (full Insights, Stamina, Avg), open
  **Settings → "Dev: unlock Pro"** and toggle it on.

## Notes

- In-memory DB + fake billing — **no real purchases, accounts, or network**, and
  nothing here ships in the real app.
- Data is deterministic (fixed random seed) so screenshots are repeatable.
- To change the demo name / amount of history, edit `_seedDemoData` in
  `preview_main.dart`.
- Frame the captures into store-ready images with
  [`../../docs/store-assets/screenshot-frame.html`](../../docs/store-assets/screenshot-frame.html).
