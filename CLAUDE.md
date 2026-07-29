# Sustain — project instructions

## Web version — the master spec is the source of truth (READ FIRST)

For **any** work on the Sustain **web** version (the Astro site, `site/`, `web-prototype/`, the timer/setup/
session screens, the living scene, audio, landing, SEO, deployment):

1. **Read `docs/superpowers/specs/2026-07-29-sustain-web-master-spec.md` FIRST.** It holds the full context —
   purpose, architecture, workflow, features, decisions, current build state, and the path to production. It
   consolidates every prior web spec (see its §20).
2. **Before asking the founder any question or clarification, check the master spec and the prior web specs
   first.** If it's already decided or mentioned there, **apply it and say so** — e.g. "clarified from the
   master spec §5" or "clarified from `2026-07-22-...-first-push-design.md`". **Only ask the founder when it's
   genuinely unaddressed** anywhere.
3. **Keep the master spec current.** Anything decided, changed, or completed about the web version — **anything
   at all** — is written into the relevant section **in the same task**, and appended to its §22 changelog. The
   spec is never allowed to drift behind the code.

## General

- The docs map is `docs/README.md`; the conflict order of truth is (1) the code, (2) `feature-roadmap.md`,
  (3) `project-context.md`, (4) the latest dated spec. For web specifically, the master spec above is that
  latest roll-up.
- Founder verifies visual/UX and audio **on-device himself** (Iron Rule) — don't drive the browser to "verify"
  after building unless asked; running the static server is fine.
