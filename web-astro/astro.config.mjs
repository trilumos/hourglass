import { defineConfig } from 'astro/config';

// https://astro.build/config
// NORTH STAR (spec §0): one living world. A single app page mounts the scene island once and never
// re-mounts it; Home(hero) -> Setup -> Session are states layered inside it.
// Static output (Astro's default) = zero JS by default; the scene (Three.js WebGL) + timer hydrate as
// vanilla islands. Keep the plate the LCP (preloaded); the WebGL glitter/sun/moon defer-inits over it.
export default defineConfig({
  // site: 'https://sustaintimer.com',  // set once the domain is bought (SEO/canonical/sitemap)
});
