// Compress plates → WebP, moon → WebP, and generate tiny blur-up LQIP data URIs. Run from web-astro/.
// One-off asset build (kept in repo for regenerating if plates change): `node gen-assets.mjs`.
import sharp from 'sharp';
import { writeFileSync } from 'fs';

const PLATES = ['pre-dawn', 'sunrise', 'midday', 'sunset', 'twilight', 'midnight'];
const dir = 'public/plates-phases';
const lqip = [];

for (const p of PLATES) {
  const src = `${dir}/${p}.jpg`;
  const out = await sharp(src).webp({ quality: 84 }).toFile(`${dir}/${p}.webp`);
  const tiny = await sharp(src).resize(64).webp({ quality: 50 }).toBuffer();
  lqip.push(`data:image/webp;base64,${tiny.toString('base64')}`);
  console.log(`${p}.webp  ${(out.size / 1024).toFixed(0)}KB   lqip ${tiny.length}B`);
}

const moon = await sharp('public/plates/moon-tex.png').webp({ quality: 90 }).toFile('public/plates/moon-tex.webp');
console.log(`moon-tex.webp ${(moon.size / 1024).toFixed(0)}KB`);

writeFileSync(
  'src/scene/lqip.js',
  '// AUTO-GENERATED (gen-assets.mjs). Tiny blur-up placeholders, base64, index-aligned to PLATES.\n' +
  'export const LQIP = ' + JSON.stringify(lqip) + ';\n'
);
console.log('wrote src/scene/lqip.js');
