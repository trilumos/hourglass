import { defineConfig } from 'astro/config';

// https://astro.build/config
// NORTH STAR (spec §0): one living world. A single app page mounts the scene island once and never
// re-mounts it; Home(hero) -> Setup -> Session are states layered inside it.
// Static output (Astro's default) = zero JS by default; the scene (Three.js WebGL) + timer hydrate as
// vanilla islands. Keep the plate the LCP (preloaded); the WebGL glitter/sun/moon defer-inits over it.
export default defineConfig({
  site: 'https://sustaintimer.com',   // domain secured 2026-08-02 (Hostinger). Canonical/OG/sitemap use
                                      // their own SITE constant per page, so this is for tooling that
                                      // reads Astro.site (e.g. adding @astrojs/sitemap later).
  // Astro's dev toolbar renders bottom-centre at z-index 999999 — directly over the Session's pause button,
  // eating its clicks in dev (it's dev-only, never in the production build). Disabled so dev matches prod.
  devToolbar: { enabled: false },
});
