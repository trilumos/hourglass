# Vercel / Geist — Design Reference

> Downloaded/synthesized 2026-06-15 from vercel.com/geist and design-system
> teardowns. Kept in-repo as the reference for our minimal, premium,
> productivity feel. We borrow Vercel's *structure and restraint* and warm the
> *temperature* (see docs/design-language.md → "Warm Precision").

## Principles
1. **Restraint as a feature — "less but better."** Color is punctuation, not
   decoration; accent appears only on primary action / active state / links.
2. **Dark mode is canonical**, light is the derivative. (Matches our dark-first.)
3. **High contrast + accessibility as the foundation** — contrast carries
   hierarchy, replacing ornament.
4. **Content-first, chrome-last.** Borders are hairlines at very low opacity
   (~8% on dark); no gradients on core UI, minimal shadows, no illustrations.
5. **Precision via tokens.** A small disciplined set — 8px spacing grid, fixed
   type scale, short radius scale — reused everywhere; nothing arbitrary.
6. **Grid discipline.** Alignment and rhythm do the heavy lifting; layouts read
   as engineered.
7. **Monospaced/tabular numerals** for crisp, trustworthy numbers.
8. **Speed/performance is a design value** — visual minimalism keeps rendering
   fast and calm.

## Color & dark approach (borrow the structure, warm the hue)
- Vercel: pure `#000` canvas + a *pure-neutral* gray ramp + blue `#0070F3`
  accent. Reads precise but cold.
- **Ours:** warm near-black canvas (`#0A0907`), a warm-tinted near-black surface
  ladder, warm-sand accent (`#E8C9A0`) as the single punctuation color. Same
  restraint, opposite temperature.
- Hierarchy by foreground opacity tiers (~90 / ~60 / ~40) + low-opacity
  hairlines, **not** shadows.
- Subtle full-screen ambient gradient (light-from-above), not a glowing blob.

## Typography
- **Geist Sans + Geist Mono**, designed for developers/designers, OFL 1.1
  (commercial-safe to bundle). We adopt **Geist Sans** as the primary UI font for
  the minimal/premium/productivity feel. Geist Mono is reserved for the future
  timer numerals (tabular).

## Spacing / radius / motion
- **8px grid:** 4, 8, 12, 16, 24, 32, 48, 64, 96. Generous whitespace.
- **Type scale:** 12 / 14 / 16 / 18 / 24 / 32 / 48 / 64; tight tracking on large
  display, slightly negative on body.
- **Radius — we diverge softer:** Vercel trends sharp (0/4/6/8); we use
  12/16/20/pill (warm, never cold/sharp).
- **Motion:** short, eased, never bouncy. 150–250ms UI; the one slow signature is
  the gravity-true sand fall.

## Sources
vercel.com/geist/introduction · vercel.com/font · github.com/vercel/geist-font
(OFL 1.1) · seedflip.co/blog/vercel-design-system · designsystems.one/design-systems/vercel-geist
