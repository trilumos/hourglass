// Verbatim GLSL extracted from web-prototype/hybrid.html (spec §6.1).
// Do NOT edit the shader body — it is finely hand-tuned. Plumbing lives elsewhere.

export const VERT = `varying vec2 vUv; void main(){ vUv=uv; gl_Position=vec4(position.xy,0.,1.); }`;

export const FRAG = `
    precision highp float; varying vec2 vUv;
    uniform sampler2D uTex, uTex2, uMask; uniform float uMix;
    uniform float uTime,uGl,uGd,uGs,uHor,uSill;
    uniform float uPathX,uPathW,uPersp,uGlen,uGthk,uGdrift;
    uniform vec2 uCelA,uCelB;
    uniform float uCelAamt,uCelBamt,uCelAtype,uCelBtype,uMoonK,uAspect;
    uniform float uLite;          // 1 = constrained device: skip sun/moon + glitter (plate crossfade only)
    uniform float uMoonR,uMoonSoft,uMoonTexAmt,uMoonWarm,uMoonHaze,uMoonWarmH;
    uniform vec3  uMoonWarmCol;
    uniform float uMoonGlowW,uMoonGlowA,uMoonFarW,uMoonFarA;
    uniform sampler2D uMoonTex;
    uniform vec3  uMoonCol,uMoonGlowCol,uMoonFarCol;
    uniform float uSunSize,uCoreW,uCoreA,uNearW,uNearA,uFarW,uFarA;
    uniform vec3  uCoreCol,uNearCol,uFarCol;
    uniform float uCelAalt,uCelBalt;
    uniform vec3 uLightCol;      // colour of whichever body is up (warm sun / cool moon)

    // A sun (type=1, warm disc) or moon (type=0, cool + real phase). Soft glow,
    // never drawn over the hourglass glass. Light is from the LEFT, so the moon
    // is lit on its left and its crescent opens right — matching every plate.
    // The glow's INTENSITY is constant while the body is up — only amt fades it,
    // and only below the horizon. What changes through the day is COLOUR: orange-
    // yellow at the horizon, yellow-white at noon. Earlier versions ramped intensity
    // by altitude as well and it read wrong at every hour; a bright sun that merely
    // changes hue is both simpler and what actually happens.
    // one mare — a LOBED basin in disc space, not a circle. The angular wobble is
    // what stops these reading as pasted-on dots; real basins have ragged outlines.
    // The 6% edge is about a pixel at the moon's on-screen size: antialiased, crisp.
    float hash(vec2 p){ return fract(sin(dot(p,vec2(41.3,289.1)))*43758.5453); }

    vec3 celestial(vec3 base, vec2 uv, vec2 pos, float type, float amt, float glassMask,
                   float altF){
      if(amt<=0.001) return base;
      // The two bodies get their own radii. Physically the sun is the distant one,
      // so its DISC is small — what makes it read as huge is its glow, not its
      // size. The moon is near: a big disc, but dim, so almost no glow.
      float rad = (type>0.5) ? uSunSize : uMoonR;
      vec2 d=(uv-pos); d.x*=uAspect; float r=length(d); float nr=r/rad;
      // HARD clip at the horizon — nothing of the body (disc, crescent or glow)
      // may render below the water line; it must vanish as it sets.
      float aboveH = smoothstep(uHor-0.0012, uHor+0.0012, uv.y);
      float vis=amt*(1.0-glassMask);                              // GLOW scales with brightness
      // The DISC is a solid body — never see-through. Using amt for its opacity
      // made the rising/setting sun 15% transparent. Opacity is binary-ish:
      // fully opaque whenever the body is up at all.
      float solid=smoothstep(0.02,0.15,amt)*(1.0-glassMask);
      vec3 col=base;
      if(type>0.5){
        // SUN — TWO ZONES, both fully author-controlled per time of day.
        //   SUN AREA  the body + its own glow, drawn as a MIX so its apparent size
        //             is a pure function of radius and cannot track the sky behind.
        //   FAR GLOW  the warmth thrown across the whole image, screened so it tints
        //             the sky rather than blooming into a blob.
        // Every value here is blended on the JS side from the three SUN_KEYS, so
        // the founder's sunrise / midday / sunset settings are what actually render.
        float disc = exp(-nr*uCoreW)*uCoreA;             // white centre
        float near = exp(-nr*uNearW)*uNearA;             // the sun's own glow
        // NO hard clamp. clamp() made sunA sit at exactly 1.0 across a wide plateau
        // and then fall — and that shoulder was the "distinct border". This
        // approaches 1 asymptotically, so there is no edge anywhere in the falloff.
        float sunA = 1.0 - exp(-(disc + near));
        vec3  sunC = mix(uNearCol, uCoreCol, 1.0 - exp(-disc));
        col = mix(col, sunC, sunA * vis * aboveH);

        // --- far glow: the image-wide warmth, screened so it tints rather than blooms
        float far = exp(-nr*uFarW)*uFarA;
        col = 1.0 - (1.0-col)*exp(-uFarCol*far*vis*aboveH);
      } else {
        // MOON — a PAINTED texture, not a generated surface. Procedural passes went
        // selenographic maria (read as a stain), then ring craters (read as
        // pimples). At ~60px on screen there is no maths that beats artwork.
        float moonlight = 0.25 + 0.75*uMoonK;
        vec2 md = d/rad;                                        // disc space, rides with the body
        // md is -1..1 across the disc and the texture is cropped to exactly that,
        // so the artwork lands on the body with no scaling to get wrong.
        vec4 mt = texture2D(uMoonTex, md*0.5 + 0.5);
        float tl = dot(mt.rgb, vec3(0.299,0.587,0.114));        // its own shading
        // uMoonTexAmt 1 = full painted detail, 0 = flat shaded disc.
        // uMoonCol tints it; white leaves the artwork exactly as painted.
        vec3 body = mix(vec3(tl), mt.rgb, uMoonTexAmt) * uMoonCol;

        // LOW-MOON TREATMENT — two separate real effects, both strongest at the
        // horizon and gone by uMoonWarmH. A cold blue-white moon sitting in a peach
        // dawn sky is exactly what reads as pasted on.
        float lowF = 1.0 - smoothstep(0.0, uMoonWarmH, altF);

        // 1. EXTINCTION. A low moon is reddened by the same air mass that reddens a
        //    low sun — it genuinely goes orange near the horizon. A FIXED warm
        //    colour, not the sky's: measured at the moon's own position the night
        //    sky is deep blue (hue R-B of -1.9 to -3.7), so tinting by the sky
        //    would turn the moon BLUE, the opposite of the intent.
        body = clamp(mix(body, body*uMoonWarmCol*1.18, lowF*uMoonWarm), 0.0, 1.0);

        // 2. HAZE. It also loses contrast against the sky, and that lost contrast is
        //    what actually dissolves the cutout edge. Sampled from the plate at the
        //    moon's position, clamped to just above the horizon — at moonrise the
        //    disc's centre sits ON the water line and the sea is the wrong colour.
        vec2  sp  = vec2(pos.x, max(pos.y, uHor + 0.012));
        vec3  sky = mix(texture2D(uTex, sp).rgb, texture2D(uTex2, sp).rgb, uMix);
        body = mix(body, sky, lowF*uMoonHaze*0.55);

        // the texture carries its own clean edge; uMoonSoft can feather it further
        float shape = mt.a * smoothstep(1.0, 1.0-uMoonSoft, nr);
        col = mix(col, body, shape*aboveH*solid);               // solid, never see-through

        // GLOW LAST, and NOT masked to the disc exterior — letting the halo wash
        // across the limb is what dissolves the pasted-on look. Two layers, same
        // structure as the sun: a halo around the body, and a wide spill into the
        // sky. Always far below the sun's brightness.
        // The glow warms with the disc — warming only the body while its halo
        // stayed blue would look stranger than not warming at all.
        vec3 gc = mix(uMoonGlowCol, uMoonGlowCol*uMoonWarmCol*1.18, lowF*uMoonWarm);
        vec3 fc = mix(uMoonFarCol,  uMoonFarCol *uMoonWarmCol*1.18, lowF*uMoonWarm);
        float halo = exp(-nr*uMoonGlowW)*uMoonGlowA;
        float spill= exp(-nr*uMoonFarW )*uMoonFarA;
        vec3 mg = (gc*halo + fc*spill) * vis * aboveH * moonlight;
        col = 1.0 - (1.0-col)*exp(-mg);
      }
      return col;
    }
    // one twinkling 4-point star per grid cell — smooth pop in/out, old-anime.
    // dens scales with distance: more, finer glints crowding toward the horizon.
    float starLayer(vec2 uv, float cells, float seed, float dens){
      vec2 gp = uv*vec2(cells*1.9, cells);   // wider cells (water is wide)
      vec2 id = floor(gp), f = fract(gp)-0.5;
      float on = step(1.0-uGd*dens, hash(id+seed));      // only some cells sparkle
      // life: mostly dark, quick bright flash, gentle fade (eased, smooth)
      float per = 1.6 + 2.6*hash(id+seed+5.5);
      float t   = uTime*uGs/per + hash(id+seed+9.9);
      float ph  = fract(t), cyc = floor(t);              // which life this is
      float life = smoothstep(0.0,0.12,ph) * (1.0-smoothstep(0.12,0.55,ph));
      // Each glint is BORN, slides a little toward the shore across its own
      // lifetime, then dies — the field itself never streams. Re-seeding the
      // position per CYCLE stops a cell from firing in the same spot every time,
      // which is what made it read as fixed.
      vec2 jit = (vec2(hash(id+seed+3.1+cyc*1.7),
                       hash(id+seed+7.2+cyc*3.3))-0.5)*0.7;
      jit.y -= ph*uGdrift;               // grid y rises with vUv.y, so shoreward is -y
      vec2 d = f - jit;
      // HORIZONTAL glint — a flat dash lying on the water, not a 4-point star.
      // Water reflects the sky in flat facets, so real glitter reads as short
      // horizontal strokes.
      float dash = smoothstep(uGlen,0.0,abs(d.x)) * smoothstep(uGthk,0.0,abs(d.y));
      return dash * life * on;
    }
    void main(){
      // water band: between sill (low) and horizon (high), vUv.y from bottom.
      float band = smoothstep(uSill-0.01,uSill+0.03,vUv.y) * (1.0-smoothstep(uHor-0.03,uHor,vUv.y));
      // depth: 0 at the horizon, 1 at the near shore. Everything about water
      // perspective keys off this.
      float depth = clamp((uHor - vUv.y)/max(uHor-uSill,0.001), 0.0, 1.0);

      // crossfade the two bracketing phase plates (pixel-aligned → no ghosting)
      vec4 col = mix(texture2D(uTex, vUv), texture2D(uTex2, vUv), uMix);
      // The SEA MASK is hand-drawn, so it is exact. Colour heuristics cannot be:
      // "bluish" also matches blue shadow on the cliffs and rocks, which is why
      // R = the hand-drawn sea region · G = the hourglass glass.
      // A "bluish pixel" test was tried and dropped: at sunrise/sunset the sea
      // reflects an orange sky, so red exceeds blue and it returned 0 — killing the
      // sea effects exactly at the horizon, where they matter most. The traced
      // region is exact at every time of day; trust it alone.
      vec2  mk = texture2D(uMask, vUv).rg;
      float water = mk.r;
      float glass = mk.g;

      // ── LITE TIER ───────────────────────────────────────────────────────────
      // On a constrained device (uLite = 1) the sun/moon and the water glitter are skipped and only the
      // PLATE and its crossfade remain — the founder's call, and the two effects below are exactly the
      // expensive ones: celestial() runs twice, and the glitter evaluates two starLayer() grids, each a
      // hash-per-cell twinkle. Everything above this point (plate sample, phase crossfade, tone) is
      // untouched, which is why the sky still moves through the day on a phone.
      //
      // uLite is a UNIFORM, so the branch is coherent across every fragment — there is no warp
      // divergence and the GPU genuinely skips the work rather than executing both sides.
      //
      // DESKTOP IS BYTE-FOR-BYTE UNCHANGED: uLite is 0 there, so this is the identical code path with
      // the identical inputs. Nothing inside the branch was edited.
      if (uLite < 0.5) {
        // Sun/moon in the sky — the setting body fades out while the rising one
        // fades in (A = phase leaving, B = phase arriving).
        col.rgb = celestial(col.rgb, vUv, uCelA, uCelAtype, uCelAamt, glass, uCelAalt);
        col.rgb = celestial(col.rgb, vUv, uCelB, uCelBtype, uCelBamt, glass, uCelBalt);

        // GLITTER PATH — real sun-glitter is a column pointing at the light, not an
        // even wash. uPathX will later be driven by the rendered sun's position.
        // A wide path degrades naturally to "no path" — no branch needed.
        float px = (vUv.x-uPathX)/max(uPathW,0.02);
        float path = exp(-px*px);
        // denser + finer toward the horizon
        float dens = mix(1.0, 1.0+1.2*uPersp, 1.0-depth);
        float g = starLayer(vUv,26.0,0.0,dens) + starLayer(vUv,40.0,13.7,dens)*0.7;
        // faint, additive white — a glint, not a glow.
        // Glitter is a mirror-angle specular: it only exists when the eye, the
        // facet and the light line up. Curved glass destroys that alignment, so it
        // is killed inside the hourglass — while the wave lines above, which are
        // the water's own appearance, pass straight through.
        // glints carry the LIGHT's colour — a low orange sun makes orange glints
        col.rgb += g * uGl * water * (1.0-glass) * mix(0.30,1.0,path) * 0.55
                 * mix(vec3(1.0,0.99,0.94), uLightCol, 0.85);
      }

      // No sun/moon water reflection. Several passes at a specular column all read
      // as a smudge that either camouflaged the sun or looked painted-on; the
      // glitter above already carries the light's colour across the sea, which is
      // what actually sells it. Cut rather than kept at low strength.
      gl_FragColor = col;
    }`;
