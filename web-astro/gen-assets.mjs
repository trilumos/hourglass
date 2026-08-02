// Compress plates → WebP, moon → WebP, and generate tiny blur-up LQIP data URIs. Run from web-astro/.
// One-off asset build (kept in repo for regenerating if plates change): `node gen-assets.mjs`.
import sharp from 'sharp';
import { writeFileSync } from 'fs';

const PLATES = ['pre-dawn', 'sunrise', 'midday', 'sunset', 'twilight', 'midnight'];
// Sources stay in _internal/ (the design record); only the compressed WebP ships in public/.
const srcDir = '../_internal/site/assets/plates';
const dir = 'public/plates-phases';
const lqip = [];

for (const p of PLATES) {
  const src = `${srcDir}/${p}.jpg`;
  const out = await sharp(src).webp({ quality: 84 }).toFile(`${dir}/${p}.webp`);
  const tiny = await sharp(src).resize(64).webp({ quality: 50 }).toBuffer();
  lqip.push(`data:image/webp;base64,${tiny.toString('base64')}`);
  console.log(`${p}.webp  ${(out.size / 1024).toFixed(0)}KB   lqip ${tiny.length}B`);
}

const moon = await sharp('../_internal/web-prototype/plates/moon-tex.png').webp({ quality: 90 }).toFile('public/plates/moon-tex.webp');
console.log(`moon-tex.webp ${(moon.size / 1024).toFixed(0)}KB`);

// Social share card: 1200x630 from the sunset plate. JPG, not WebP — some scrapers still won't decode WebP.
const og = await sharp(`${srcDir}/sunset.jpg`)
  .resize(1200, 630, { fit: 'cover', position: 'centre' })
  .jpeg({ quality: 82, mozjpeg: true }).toFile('public/og-cover.jpg');
console.log(`og-cover.jpg ${(og.size / 1024).toFixed(0)}KB`);

writeFileSync(
  'src/scene/lqip.js',
  '// AUTO-GENERATED (gen-assets.mjs). Tiny blur-up placeholders, base64, index-aligned to PLATES.\n' +
  'export const LQIP = ' + JSON.stringify(lqip) + ';\n'
);
console.log('wrote src/scene/lqip.js');
