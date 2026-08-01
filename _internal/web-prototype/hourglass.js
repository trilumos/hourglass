// Port of lib/hourglass/hourglass_painter.dart -> HTML5 Canvas 2D.
//
// Deliberately a TRANSLATION, not a redesign: same curves, same constants, same
// two-phase pile, same travelling-wave top surface, same accelerating grain
// spray. Flutter's Canvas maps ~1:1 onto Canvas2D (Path->Path2D, Gradient.linear
// ->createLinearGradient), so the shapes are identical by construction. Where a
// value looks arbitrary here it is arbitrary THERE too — it was tuned by eye on
// the app and must not drift, or web and app stop being the same object.
//
// Only real divergence: Dart's math.Random(seed) can't be reproduced exactly, so
// the grain spray uses mulberry32. Different numbers, identical character — it's
// noise either way.

// ---- colour helpers ---------------------------------------------------------

/** '#RRGGBB' | {r,g,b} -> {h,s,l} with h in [0,1]. */
function rgbToHsl(r, g, b) {
  r /= 255; g /= 255; b /= 255;
  const max = Math.max(r, g, b), min = Math.min(r, g, b);
  const l = (max + min) / 2;
  if (max === min) return { h: 0, s: 0, l };
  const d = max - min;
  const s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
  let h;
  if (max === r) h = ((g - b) / d + (g < b ? 6 : 0)) / 6;
  else if (max === g) h = ((b - r) / d + 2) / 6;
  else h = ((r - g) / d + 4) / 6;
  return { h, s, l };
}

function hslToRgb(h, s, l) {
  if (s === 0) { const v = Math.round(l * 255); return { r: v, g: v, b: v }; }
  const hue2rgb = (p, q, t) => {
    if (t < 0) t += 1;
    if (t > 1) t -= 1;
    if (t < 1 / 6) return p + (q - p) * 6 * t;
    if (t < 1 / 2) return q;
    if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
    return p;
  };
  const q = l < 0.5 ? l * (1 + s) : l + s - l * s;
  const p = 2 * l - q;
  return {
    r: Math.round(hue2rgb(p, q, h + 1 / 3) * 255),
    g: Math.round(hue2rgb(p, q, h) * 255),
    b: Math.round(hue2rgb(p, q, h - 1 / 3) * 255),
  };
}

function hexToRgb(hex) {
  const s = hex.replace('#', '');
  return {
    r: parseInt(s.slice(0, 2), 16),
    g: parseInt(s.slice(2, 4), 16),
    b: parseInt(s.slice(4, 6), 16),
  };
}

/**
 * Vary ONLY HSL lightness so a gold stays gold. Lerping a colour toward
 * black/white desaturates and muddies it — same reason the Dart does this.
 */
function deeper(hex, amount) {
  const { r, g, b } = hexToRgb(hex);
  const { h, s, l } = rgbToHsl(r, g, b);
  const c = hslToRgb(h, s, clamp(l * (1 - amount), 0, 1));
  return `rgb(${c.r},${c.g},${c.b})`;
}

function lighter(hex, amount) {
  const { r, g, b } = hexToRgb(hex);
  const { h, s, l } = rgbToHsl(r, g, b);
  const c = hslToRgb(h, s, clamp(l + (1 - l) * amount, 0, 1));
  return `rgb(${c.r},${c.g},${c.b})`;
}

function rgba(hex, a) {
  const { r, g, b } = hexToRgb(hex);
  return `rgba(${r},${g},${b},${a})`;
}

const clamp = (x, lo, hi) => Math.min(hi, Math.max(lo, x));

/** Smoothstep — matches _smooth() in the Dart. */
const smooth = (x) => { const c = clamp(x, 0, 1); return c * c * (3 - 2 * c); };

/** Deterministic PRNG standing in for Dart's math.Random(seed). */
function mulberry32(seed) {
  return function () {
    seed |= 0; seed = (seed + 0x6D2B79F5) | 0;
    let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

// ---- skins (ported from hourglass_skin.dart) --------------------------------

export const SKINS = {
  // Dark-tuned: white glass tints, warm golden sand.
  classic: {
    id: 'classic',
    sandColor: '#EACA78',   // warm GOLDEN sand (not grey-beige)
    glassTint: '#FFFFFF',
    glassOutline: 'rgba(255,255,255,0.20)',
    neckWidth: 0.012,
  },
  // Light-tuned: the white glass is invisible on pale ground, so it goes DARK
  // and the sand deepens to read on warm paper. Shape/animation identical.
  classicLight: {
    id: 'classic',
    sandColor: '#E0A82C',
    glassTint: '#1F1B14',
    glassOutline: 'rgba(31,27,20,0.20)',
    neckWidth: 0.012,
  },
};

// ---- the painter ------------------------------------------------------------

/**
 * @param progress 0 = top full, 1 = pile full
 * @param time     elapsed seconds — drives the spray and the surface swell
 * @param ambient  sand falls forever, top stays full, nothing accumulates
 */
export function paintHourglass(ctx, w, h, { progress, time, skin, ambient = false }) {
  const cx = w / 2;
  const maxHalf = w * 0.30;
  const neckHalf = w * skin.neckWidth;
  const topPad = h * 0.04;
  const usableH = h - topPad * 2;
  const drain = clamp(progress, 0, 1);

  const yToPx = (y) => topPad + y * usableH;
  const rx = (half) => cx + half;
  const lx = (half) => cx - half;

  ctx.clearRect(0, 0, w, h);

  // --- elegant elongated glass ---
  const glass = new Path2D();
  glass.moveTo(cx, yToPx(0.0));
  glass.bezierCurveTo(rx(maxHalf * 0.86), yToPx(0.010), rx(maxHalf), yToPx(0.05), rx(maxHalf), yToPx(0.14));
  glass.bezierCurveTo(rx(maxHalf), yToPx(0.30), rx(neckHalf), yToPx(0.40), rx(neckHalf), yToPx(0.5));
  glass.bezierCurveTo(rx(neckHalf), yToPx(0.60), rx(maxHalf), yToPx(0.70), rx(maxHalf), yToPx(0.86));
  glass.bezierCurveTo(rx(maxHalf), yToPx(0.95), rx(maxHalf * 0.86), yToPx(0.990), cx, yToPx(1.0));
  glass.bezierCurveTo(lx(maxHalf * 0.86), yToPx(0.990), lx(maxHalf), yToPx(0.95), lx(maxHalf), yToPx(0.86));
  glass.bezierCurveTo(lx(maxHalf), yToPx(0.70), lx(neckHalf), yToPx(0.60), lx(neckHalf), yToPx(0.5));
  glass.bezierCurveTo(lx(neckHalf), yToPx(0.40), lx(maxHalf), yToPx(0.30), lx(maxHalf), yToPx(0.14));
  glass.bezierCurveTo(lx(maxHalf), yToPx(0.05), lx(maxHalf * 0.86), yToPx(0.010), cx, yToPx(0.0));
  glass.closePath();

  // The Dart's glassTint carries its own alpha but withValues(alpha:) REPLACES
  // it — so the gradient is simply the tint hue at 0.10 -> 0.02.
  const gg = ctx.createLinearGradient(lx(maxHalf), yToPx(0.0), rx(maxHalf), yToPx(1.0));
  gg.addColorStop(0, rgba(skin.glassTint, 0.10));
  gg.addColorStop(1, rgba(skin.glassTint, 0.02));
  ctx.fillStyle = gg;
  ctx.fill(glass);

  // ---- pile geometry (two-phase volume-driven cone -> fill) ----
  const floorY = yToPx(1.0);
  const f0 = 0.30;
  const s = 0.62;
  const pileW = maxHalf * 0.92;
  const coneR = drain <= 0 ? 0 : (drain <= f0 ? pileW * Math.sqrt(drain / f0) : pileW);
  const coneMax = clamp(s * pileW, 0, usableH * 0.14);
  const coneH = drain <= f0
    ? coneMax * Math.sqrt(clamp(drain / f0, 0, 1))
    : coneMax * (1 - 0.5 * clamp((drain - f0) / (1 - f0), 0, 1));
  const maxFill = floorY - yToPx(0.66); // pile tops out below the neck
  const baseRise = maxFill * smooth(clamp((drain - f0) / (1 - f0), 0, 1));

  const pileHeightAt = (x) => {
    const dr = Math.abs(x - cx);
    const bump = (coneR <= 0 || dr >= coneR)
      ? 0
      : coneH * Math.pow(Math.cos((dr / coneR) * Math.PI / 2), 1.2);
    return baseRise + bump;
  };

  // Ambient: nothing accumulates, so grains fall the full lower chamber.
  const landY = ambient ? floorY : floorY - pileHeightAt(cx);

  ctx.save();
  ctx.clip(glass);

  // TOP liquid: a kinematic travelling swell crossing the surface.
  if (drain < 1.0) {
    const restSurf = yToPx(0.12 + 0.38 * drain); // 12% headroom, drains to the neck
    const neckPx = yToPx(0.5);
    const waveLen = w * 0.85;
    const kk = 2 * Math.PI / waveLen;
    // Fade to flat over the last 15% so no band pops out at 100%.
    const waveFade = 1 - smooth((drain - 0.85) / 0.15);
    const amp = maxHalf * 0.075 * waveFade;

    const drawWaveLayer = (dy, speed, phase0, fillStyle) => {
      const phi = 2 * Math.PI * speed * time + phase0;
      const nPts = 40;
      const pts = [];
      for (let i = 0; i <= nPts; i++) {
        const x = w * i / nPts;
        pts.push({ x, y: restSurf + dy - amp * Math.sin(kk * x - phi) });
      }
      const p = new Path2D();
      p.moveTo(pts[0].x, pts[0].y);
      // Catmull-Rom -> cubic bezier, exactly as the Dart does.
      for (let i = 0; i < pts.length - 1; i++) {
        const p0 = pts[i === 0 ? 0 : i - 1];
        const p1 = pts[i];
        const p2 = pts[i + 1];
        const p3 = pts[i + 2 >= pts.length ? pts.length - 1 : i + 2];
        const c1 = { x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6 };
        const c2 = { x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6 };
        p.bezierCurveTo(c1.x, c1.y, c2.x, c2.y, p2.x, p2.y);
      }
      // Taper the sand INTO the aperture rather than capping it flat at the neck
      // (a flat cap read as a rigid horizontal line).
      const rise = usableH * 0.028 * waveFade;
      const mouth = neckHalf * 1.8;
      p.lineTo(w, neckPx);
      p.lineTo(cx + mouth, neckPx - rise);
      p.quadraticCurveTo(cx + mouth * 0.5, neckPx, cx, neckPx);
      p.quadraticCurveTo(cx - mouth * 0.5, neckPx, cx - mouth, neckPx - rise);
      p.lineTo(0, neckPx);
      p.closePath();
      ctx.fillStyle = fillStyle;
      ctx.fill(p);
    };

    // Back layer: light sand, peeks higher, brightened IN-HUE so it doesn't
    // desaturate into the front surface and vanish.
    drawWaveLayer(-amp * 1.1, 0.24, 0.6, lighter(skin.sandColor, 0.46));

    // Front (bulk): 3-stop vertical gradient, light at the surface -> dark at the neck.
    const fg = ctx.createLinearGradient(cx, restSurf, cx, neckPx);
    fg.addColorStop(0.0, lighter(skin.sandColor, 0.14));
    fg.addColorStop(0.5, hexOrRgb(skin.sandColor));
    fg.addColorStop(1.0, deeper(skin.sandColor, 0.20));
    drawWaveLayer(0.0, 0.34, 4.0, fg);
  }

  // BOTTOM pile (never in ambient — nothing accumulates).
  if (!ambient && drain > 0) {
    const pile = new Path2D();
    const pn = 72;
    for (let i = 0; i <= pn; i++) {
      const x = w * i / pn;
      const sy = floorY - pileHeightAt(x);
      if (i === 0) pile.moveTo(x, sy); else pile.lineTo(x, sy);
    }
    pile.lineTo(w, floorY);
    pile.lineTo(0, floorY);
    pile.closePath();

    const pileTopY = floorY - Math.max(pileHeightAt(cx), 1);
    const pg = ctx.createLinearGradient(cx, pileTopY, cx, floorY);
    pg.addColorStop(0.0, lighter(skin.sandColor, 0.26));
    pg.addColorStop(0.5, hexOrRgb(skin.sandColor));
    pg.addColorStop(1.0, deeper(skin.sandColor, 0.22));
    ctx.fillStyle = pg;
    ctx.fill(pile);
  }

  // FALLING SAND: a thin central column of matte grains that ACCELERATE under
  // gravity (slow+packed at the hole, fast+sparse at the pile). No glow, no cone.
  if (ambient || (drain > 0 && drain < 1)) {
    const holeY = yToPx(0.5);
    const gapNow = landY - holeY;
    const gapFade = clamp(gapNow / (usableH * 0.06), 0, 1);
    const drainCutoff = 0.92;
    const supplyFade = clamp(1 - (drain - drainCutoff) / (1 - drainCutoff), 0, 1);
    const gate = gapFade * supplyFade;

    if (gate > 0.01 && gapNow > 1) {
      const grainCount = 80;
      const fallPeriod = ambient ? 0.78 : 0.5; // ambient falls calmer
      const v0Frac = 0.10; // small exit speed; the rest is gravity (phase^2)
      const colHalf = neckHalf * 1.3;
      const rng = mulberry32(7);

      for (let i = 0; i < grainCount; i++) {
        const lane = rng() * 2 - 1;
        const laneR = rng();
        const sizeR = rng();
        const speedR = 0.8 + 0.4 * rng();
        const offR = rng();
        const phase = ((time / (fallPeriod * speedR)) + offR) % 1.0;
        const fall = v0Frac * phase + (1 - v0Frac) * phase * phase;
        const py = holeY + fall * gapNow;
        if (py >= landY) continue; // landed -> don't draw into the pile
        const px = cx + Math.abs(lane) * lane * colHalf + Math.sin(phase * 2 * Math.PI + i) * 0.5;
        const r = clamp((1.05 - 0.4 * fall) * (0.55 + 0.4 * sizeR), 0.4, 1.1);
        const a = clamp((1 - 0.16 * fall) * (0.82 + 0.18 * laneR) * gate, 0, 1);
        const drop = clamp((py - holeY) / (floorY - holeY), 0, 1);
        const aFade = ambient ? 0.78 * (1 - smooth((drop - 0.42) / 0.58)) : 1.0;
        ctx.fillStyle = rgba(skin.sandColor, a * aFade);
        ctx.beginPath();
        ctx.arc(px, py, r, 0, Math.PI * 2);
        ctx.fill();
      }

      // IMPACT SCATTER: grains the stream kicks off the pile apex. Each is a tiny
      // ballistic hop; g is chosen so it lands exactly at p=1 -> v·sinθ·p·(1−p).
      // Count and energy GROW with the pile: a small pile barely stirs.
      const fill = clamp(drain, 0, 1);
      const scatterN = ambient ? 0 : Math.round(3 + 13 * fill);
      const hScale = maxHalf * (0.10 + 0.40 * fill) * 2.2;
      const vScale = usableH * (0.010 + 0.055 * fill) * 2.2;
      const erng = mulberry32(31);

      for (let i = 0; i < scatterN; i++) {
        const dir = i % 2 === 0 ? -1 : 1; // alternate sides -> always balanced
        const ang = (20 + 65 * erng()) * Math.PI / 180;
        const v = 0.55 + 0.45 * erng();
        const sizeR = erng();
        const per = 0.30 + 0.35 * erng();
        const offR = erng();
        const p = ((time / per) + offR) % 1.0;
        const vsin = v * Math.sin(ang);
        const yUp = vsin * p * (1 - p);
        const ex = cx + dir * (v * Math.cos(ang)) * p * hScale;
        const ey = landY - yUp * vScale;
        const surf = floorY - pileHeightAt(ex);
        if (ey >= surf) continue; // fallen back onto the slope -> gone
        const r = 0.25 + 0.35 * sizeR;
        const a = clamp((1 - p) * 0.8 * gate, 0, 1);
        if (a <= 0.02) continue;
        ctx.fillStyle = rgba(skin.sandColor, a);
        ctx.beginPath();
        ctx.arc(ex, ey, r, 0, Math.PI * 2);
        ctx.fill();
      }
    }
  }

  ctx.restore();

  // ---- glass highlights on top ----
  const spec = new Path2D();
  spec.moveTo(lx(maxHalf * 0.62), yToPx(0.06));
  spec.bezierCurveTo(lx(maxHalf * 0.92), yToPx(0.12), lx(maxHalf * 0.55), yToPx(0.30), lx(neckHalf * 1.5), yToPx(0.46));
  ctx.save();
  ctx.filter = 'blur(2px)'; // stands in for MaskFilter.blur
  ctx.strokeStyle = 'rgba(255,255,255,0.16)';
  ctx.lineWidth = 3;
  ctx.lineCap = 'round';
  ctx.stroke(spec);
  ctx.restore();

  ctx.strokeStyle = skin.glassOutline;
  ctx.lineWidth = 1.2;
  ctx.stroke(glass);
}

function hexOrRgb(hex) {
  const { r, g, b } = hexToRgb(hex);
  return `rgb(${r},${g},${b})`;
}
