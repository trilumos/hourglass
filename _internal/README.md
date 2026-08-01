# _internal — working files, references & source art (NOT shipped)

Everything here is for our own use — it is **not** part of the shipping Flutter app or the production web build
(`web-astro/`). Nothing here is imported by a build; it was moved out of the repo root to declutter (2026-08-01,
`git mv`, history preserved — nothing deleted).

| Folder / file | What it is |
|---|---|
| `site/` | The original static-HTML web build — **LOCKED design references** (`session.html`, `setup.html`, `home.html`) that `web-astro/` is ported from. |
| `web-prototype/` | Web prototypes & experiment labs (`number-lab.html`, `hybrid.html`, `timer-modes.json`, gen scripts). |
| `tools/` | One-off tool scripts (`gen_sound_cues.py`). |
| `icon images/` | Source app-icon art (Play Store, adaptive mipmaps). |
| `plates without hourglass/` | Source seascape plate art (no hourglass composited). |
| `skyline-matte (1).png` | Stray matte source. |
| `FGS Proof/` | Foreground-service proof video (Play Console evidence). |
| `APP DESCRIPTION` | Draft store description. |

When building the web version, the design source of truth is `_internal/site/` + `_internal/web-prototype/`
(see `CLAUDE.md`).
