# Color Themes (v1) — Design Spec (Sustain)

> **Status:** scope LOCKED 2026-06-19 (founder approved the 8-theme lineup +
> "à la carte + in Pro"). Build order item #2 from the monetization spec
> (`docs/superpowers/specs/2026-06-19-monetization-and-v1-paid-tier-design.md` §7),
> on top of the entitlement engine
> (`docs/superpowers/specs/2026-06-19-entitlement-engine-design.md`).
>
> **What this is:** 8 premium color themes (+ the free **Sand** default), each a
> complete *cohesive mood* — light + dark app palette **and** a matching
> hourglass skin — that recolors the whole app live. Sold à la carte (one
> `theme.<id>` non-consumable each) **and** all bundled into Pro.
>
> **Research basis** (`2026-06-19` web research): beloved palettes (Catppuccin,
> Nord, Rosé Pine, Tokyo Night, Everforest, Dracula, Gruvbox) earn loyalty by
> being one *intentional, soothing, eye-comfortable* mood with a clear identity;
> cosmetic themes genuinely convert (Apollo); 2026 trends favor premium dark
> mode, jewel tones, warm neutrals/nature, soft-tech pastels; color psychology:
> blue/green = calm+focus, purple = luxury, black = sophistication, muted base +
> one accent = focus. Each theme below maps to a proven, distinct mood.

---

## 1. The lineup (9 looks: Sand free + 8 premium)
Each theme is one mood, none overlapping Sand's pale desert. Palettes below are
**research-seeded starting points, tuned on-device with the founder** (the
hourglass is the hero — color must look premium in his eyes, like Sand was
tuned). Each theme supplies the FULL `HgTokens` set (light + dark) + a
`HourglassSkin` (light + dark).

| id | name | mood / lineage | dark accent | hourglass material |
|---|---|---|---|---|
| `sand` | Sand | warm desert (default, free) | sand | sand |
| `obsidian` | Obsidian | cool blue-black, nocturnal premium (Nord/Tokyo Night) | silver-blue | quicksilver |
| `sage` | Sage | calm pine/forest (Everforest) | soft sage | gold-green wheat |
| `rose` | Rosé | elegant warm rose (Rosé Pine) | antique rose | rose-gold |
| `indigo` | Indigo | deep sapphire jewel, luxe (Velvet Night) | violet-periwinkle | starlight pale-gold |
| `dusk` | Dusk | soft lavender/mauve pastel, wellness calm | misty lavender | pale orchid |
| `tide` | Tide | deep luxe teal/ocean (Luxe Teal) | aqua-teal | seafoam pearl |
| `noir` | Noir | true black + warm gold, luxury | gold | molten gold |
| `mocha` | Mocha | dark espresso + caramel, cozy warm (Catppuccin Mocha) | caramel | warm cream |

### 1.1 Starting palettes (core tokens — tune on device)
Format per theme: **Dark** `{bg, surface, surfaceRaised, textPrimary,
textSecondary, textMuted, accent, accentMuted, onAccent, hairline}` · **Light**
`{bg, surface, textPrimary, textSecondary, accent, accentMuted, hairline}` ·
**Hourglass** `{sand(dark), sand(light), glassTint(dark)=0x16FFFFFF,
glassTint(light)=0x14<dark-surface>}`. Shared/derived per theme (not repeated):
`backdrop` = darker bg (dark) / lighter bg (light); `surfaceSunken` = a step
below bg; `focusRing` = `accent`; `glow` = accent @ ~12% (dark) / ~8% (light);
`scrim` = `0xB3000000` (dark) / `0x40000000` (light); `success/warning/danger` =
reuse Sand's semantic trio (functional, not brand). `glassOutline` = accent or
hairline at ~0x33.

- **Obsidian** — Dark: bg `#0E1117`, surface `#161B24`, raised `#1E2530`,
  text `#E6EAF2`/`#A6AFBF`/`#6E7686`, accent `#9DB8E0`, accentMuted `#25303F`,
  onAccent `#0B0F16`, hairline `#232A36`. Light: bg `#F4F6FA`, surface `#FFFFFF`,
  text `#141821`/`#4C5566`, accent `#3E5C86`, accentMuted `#DCE5F2`,
  hairline `#DEE4EE`. Hourglass sand `#C9D6EC` / `#6E86AE`.
- **Sage** — Dark: bg `#11160F`, surface `#1A2117`, raised `#222B1D`,
  text `#E7EDE2`/`#A8B3A0`/`#717C6A`, accent `#A3C58C`, accentMuted `#2A331F`,
  onAccent `#11160F`, hairline `#262E20`. Light: bg `#F3F6EF`, surface `#FFFFFF`,
  text `#161B12`/`#4F5848`, accent `#5E7B43`, accentMuted `#E0E8D4`,
  hairline `#DEE5D3`. Hourglass sand `#CBD9A8` / `#8A9A55`.
- **Rosé** — Dark: bg `#17110F`, surface `#211915`, raised `#2A1F1B`,
  text `#F0E6E4`/`#BBA8A4`/`#87746F`, accent `#D6A8A0`, accentMuted `#382626`,
  onAccent `#170F0E`, hairline `#2E2422`. Light: bg `#FAF2F0`, surface `#FFFFFF`,
  text `#1F1513`/`#5C4D49`, accent `#A65F58`, accentMuted `#F1DBD6`,
  hairline `#ECD9D4`. Hourglass sand `#E6C4A8` / `#C08A6E`.
- **Indigo** — Dark: bg `#0E1020`, surface `#161A30`, raised `#1E2440`,
  text `#E7E9F7`/`#A6ABCF`/`#6E7299`, accent `#9C8CF0`, accentMuted `#262A4D`,
  onAccent `#0B0D1A`, hairline `#232845`. Light: bg `#F3F3FB`, surface `#FFFFFF`,
  text `#131526`/`#4C4F6E`, accent `#5B4BC4`, accentMuted `#E2DEF7`,
  hairline `#DEDFF1`. Hourglass sand `#E8E0B4` / `#A99A60`.
- **Dusk** — Dark: bg `#16131C`, surface `#201C29`, raised `#292333`,
  text `#ECE7F2`/`#B3A9C0`/`#7E7390`, accent `#C3A8E0`, accentMuted `#322940`,
  onAccent `#16131C`, hairline `#2B2535`. Light: bg `#F7F3FB`, surface `#FFFFFF`,
  text `#1A1521`/`#564C62`, accent `#7E5CA8`, accentMuted `#EADFF4`,
  hairline `#E7DEF0`. Hourglass sand `#DCC8EC` / `#A98AC0`.
- **Tide** — Dark: bg `#0A1618`, surface `#112224`, raised `#182E30`,
  text `#E0EEEC`/`#9FB6B3`/`#6A807D`, accent `#5FC2B6`, accentMuted `#1C3331`,
  onAccent `#07100F`, hairline `#1E302F`. Light: bg `#EEF6F4`, surface `#FFFFFF`,
  text `#0E1A19`/`#46544F`, accent `#1F7D74`, accentMuted `#D6EAE6`,
  hairline `#D7E6E2`. Hourglass sand `#BFE3D9` / `#6FA89D`.
- **Noir** — Dark: bg `#000000`, surface `#0E0E0E`, raised `#161616`,
  text `#F2EFE6`/`#ADA893`/`#75715F`, accent `#D9B871`, accentMuted `#2E2716`,
  onAccent `#14110A`, hairline `#201F1C`. Light: bg `#F6F4EE`, surface `#FFFFFF`,
  text `#14130F`/`#524E43`, accent `#997523`, accentMuted `#ECE0C4`,
  hairline `#E5DFD0`. Hourglass sand `#E8C66E` / `#B5892F`. (AMOLED-true-black
  dark; warm paper light.)
- **Mocha** — Dark: bg `#18120E`, surface `#221A14`, raised `#2C211A`,
  text `#EFE6DC`/`#B6A593`/`#82715F`, accent `#D7A66B`, accentMuted `#38291B`,
  onAccent `#160F09`, hairline `#2C231B`. Light: bg `#F6F0E8`, surface `#FFFFFF`,
  text `#1B140D`/`#574A3C`, accent `#9B6B35`, accentMuted `#EBDDC6`,
  hairline `#E8DCCB`. Hourglass sand `#ECD3AE` / `#C39A63`.

---

## 2. Architecture (skins are data; the app already recolors from `themeId`)
`app.dart` already builds `MaterialApp.theme/darkTheme` from
`HgThemes.byId(themeId)`, so adding themes is mostly **data** plus three wiring
points.

- **`HgTheme` gains a hourglass skin per brightness** (`lib/app/tokens.dart`):
  add `final HourglassSkin lightSkin; final HourglassSkin darkSkin;` and
  `HourglassSkin skinFor(Brightness b)`. (Move `HourglassSkin` so `tokens.dart`
  can reference it, or keep it where it is and import — `HourglassSkin` lives in
  `lib/hourglass/`; `tokens.dart` importing it is fine.)
- **Define all 9 themes in `HgThemes.all`** with full light+dark `HgTokens` +
  light/dark `HourglassSkin`. `HourglassSkin.classic`/`classicLight` become
  Sand's skins.
- **`activeThemeProvider`** (`Provider<HgTheme>`, new, in
  `lib/app/theme_providers.dart`): returns, in priority order: (1) the
  **preview** theme if previewing (`previewThemeProvider != null` — see §3.1),
  regardless of ownership; else (2) `HgThemes.byId(themeController.themeId)` **if
  owned** (`entitlementsProvider.ownsTheme(id)`); else (3) **Sand**. This is the
  single source of truth the app + hourglass read.
- **`previewThemeProvider`** (`Notifier<String?>`, new): the id of the theme
  currently being previewed, or null. **In-memory only** (never persisted → a
  relaunch is never stuck in preview). Set by "Preview", cleared by "Exit" or
  when a purchase makes the theme owned.
- **`app.dart`** watches `activeThemeProvider` (instead of `byId(themeId)`) so a
  lapsed entitlement quietly reverts the whole app to Sand.
- **Hourglass skin wiring:** the hourglass callers — Home, Session, Completion,
  Onboarding (all already Consumers) — pass
  `skin: ref.watch(activeThemeProvider).skinFor(Theme.of(context).brightness)`
  to `HourglassView`. The no-skin fallback in `HourglassView` stays Sand's
  classic/classicLight (safe for tests/preview).
- **`kCatalogThemeIds`** (`lib/billing/billing_config.dart`) gets the 8 ids, so
  the engine's `pro → owns all themes` lights up automatically.

---

## 3. Themes screen (browse / preview / apply / buy)
New `lib/ui/themes_screen.dart`, reached from a **"Themes"** row in Settings
(Display section). Built to high craft with the **impeccable** skill.
- A scrollable grid of **preview tiles**: a small static hourglass in the
  theme's skin + a 3-swatch palette chip (bg / surface / accent) + the name + a
  state badge: **Owned**, **In Pro**, or the **price**.
- Tap a tile → a preview sheet showing the look bigger, with the right action:
  - **Owned** → **Apply** (`themeController.setTheme(id)`; app recolors live; a
    check marks the active one).
  - **Not owned** → **Preview** (try it on, §3.1) plus **Buy <price>** (à la
    carte, §4) and **Get Pro** (opens the existing paywall; Pro unlocks all).
- The **active** theme is clearly marked. **Sand** is always Owned/free.
- Restore is NOT duplicated here (it lives in the paywall).

### 3.1 Previewing a locked theme ("try it on")
Nobody buys a look they can't feel, so a locked theme can be previewed live
across the whole app — but never used as free themed usage.
- **Tap Preview** → `previewThemeProvider` is set to that id → `activeThemeProvider`
  returns it, so the **entire app and the real hourglass instantly render in the
  theme** while the user browses Home, Insights, Settings, etc. Purely visual; it
  does **not** grant entitlement and is never persisted.
- A persistent **preview bar** overlays the app (e.g. bottom): "Previewing
  Obsidian" + **Get it** (→ the theme's buy / Get Pro options) + **Exit**
  (clears `previewThemeProvider` → reverts to owned/Sand). Relaunching the app
  also clears it (in-memory only).
- **Core-loop guard (anti-abuse):** while previewing, starting a session must NOT
  give real themed usage. Any "Begin" launches a **capped preview session**: the
  Session screen in `previewMode` that runs ~**10 seconds** to show the themed
  hourglass/session, then ends with a small "Enjoying Obsidian? Get it / Exit
  preview" prompt. A preview session **records nothing** — no Focus Score,
  streak, Today, or history (`SessionFinalizer.persist` is skipped). So preview
  shows the look in motion (the hero moment) without letting anyone focus for
  free in a paid theme.
- Buying (à la carte or Pro) during preview → the theme becomes owned →
  `previewThemeProvider` clears → it's simply the applied theme (no more bar, no
  cap). Exiting without buying → back to the owned/Sand look.

---

## 4. À-la-carte billing extension
The engine sells only Pro plans today; extend it for per-theme non-consumables.
- **`BillingService`**: add `Future<List<ThemeProduct>> themeProducts()` (price +
  id per purchasable theme) and `Future<PurchaseOutcome> purchaseTheme(String
  id)`. `ThemeProduct { String themeId; String priceString; Object raw; }`.
- **`RevenueCatBillingService`**: fetch via `Purchases.getProducts([...theme
  product ids])` → `StoreProduct`s; purchase via
  `Purchases.purchase(PurchaseParams.storeProduct(p))`. Each theme product grants
  the `theme_<id>` entitlement (configured in RevenueCat); the existing customer-
  info listener updates `entitlementsProvider`, so the new theme unlocks live and
  the Themes screen re-renders. Outcomes reuse `PurchaseOutcome` (success →
  applied/owned; cancelled silent; pending; error).
- **`FakeBillingService`**: returns a scriptable theme-product list + outcome, and
  grants the `theme_<id>` on success, for tests.
- **Pro still unlocks all** (no per-theme purchase needed when `pro`); the buy
  button only shows for non-Pro, non-owned themes.
- **Key-less today:** with no key, `themeProducts()` returns empty → tiles show
  "In Pro" / locked, Buy is unavailable, dev-unlock previews them. Real selling
  needs the founder's Play Console + RevenueCat setup (§7).

---

## 5. Ownership, selection, fallback rules
- Apply only owned themes; `themeController.setTheme(id)` persists `themeId`
  (already does). Light/dark/system (`ThemeMode`) stays orthogonal.
- **Fallback:** `activeThemeProvider` returns Sand whenever the selected theme
  isn't owned (never bought / Pro lapsed / refund). The stored `themeId` is kept
  (so re-purchasing/renewing restores their look) but not *applied* while
  unowned.
- Selecting a locked theme from the grid opens its purchase options, never
  applies it.

---

## 6. Testing (all mocked; no network)
- **Theme catalog:** every `HgThemes.all` entry has non-null light/dark tokens +
  light/dark skins; `byId` falls back to Sand for unknown ids; `skinFor` returns
  the right skin per brightness.
- **`activeThemeProvider`:** returns the selected theme when owned; Sand when not
  owned; Sand when entitlements still loading. Reacts to entitlement + themeId
  changes.
- **Entitlement gating:** `ownsTheme(id)` true when `pro`, or when `theme_<id>`
  active; Sand always owned (covered in entitlements tests, extend for catalog
  ids).
- **Billing (Fake):** `purchaseTheme` success grants `theme_<id>` and emits;
  cancelled/error leave ownership unchanged; `themeProducts` maps prices.
- **Themes screen (widget):** owned theme shows Apply and applies; locked shows
  Preview + Buy + Get Pro; Pro user shows all Owned; active theme marked; tapping
  Apply changes `activeThemeProvider`.
- **Preview:** setting `previewThemeProvider` makes `activeThemeProvider` return
  that theme even when unowned; clearing reverts to owned/Sand; a purchase
  clears it; it is not persisted. **Preview session:** `SessionScreen` in
  `previewMode` caps at ~10s and does not call `SessionFinalizer.persist` (no
  record written) — assert no session is persisted and the buy/exit prompt shows.
- **App recolor:** `app.dart` uses `activeThemeProvider` (smoke: selecting a
  theme changes `MaterialApp` tokens; lapsed → Sand).
- Serial `flutter test --concurrency=1`; `flutter analyze` clean.

---

## 7. Founder setup later (to sell à la carte; no code changes)
Play Console: create 8 **non-consumable** theme products (`theme.obsidian`,
`theme.sage`, `theme.rose`, `theme.indigo`, `theme.dusk`, `theme.tide`,
`theme.noir`, `theme.mocha`), priced per region. RevenueCat: a `theme_<id>`
entitlement per theme, each attached to its product (and the `pro` entitlement
already grants all in code). Add the product ids to the app's theme-product id
list. Until then: themes show "In Pro", dev-unlock previews them.

---

## 8. Files
**Modify:** `lib/app/tokens.dart` (HgTheme skins + all 9 themes), `lib/app/app.dart`
(watch `activeThemeProvider`), `lib/billing/billing_config.dart`
(`kCatalogThemeIds` + theme product ids), `lib/billing/billing_service.dart`
(+ `ThemeProduct`, `themeProducts`, `purchaseTheme`),
`lib/billing/revenuecat_billing_service.dart` + `fake_billing_service.dart`
(implement them), the 4 hourglass callers (pass `skin:`),
`lib/ui/settings_screen.dart` (Themes row), `lib/hourglass/hourglass_skin.dart`
(keep classic/classicLight as Sand's, or relocate), `lib/ui/session_screen.dart`
(+ `previewMode`: ~10s cap + skip persist), the "Begin" entry points (route to a
preview session when `previewThemeProvider != null`).
**Create:** `lib/app/theme_providers.dart` (`activeThemeProvider` +
`previewThemeProvider`), `lib/ui/themes_screen.dart` (+ preview tile/sheet),
`lib/ui/widgets/preview_bar.dart` (the app-wide preview overlay), tests for each.

---

## 9. Build order (for the plan)
1. `HgTheme` skin fields + `skinFor`; define all 8 palettes + skins in
   `HgThemes.all` (full token sets) — TDD the catalog integrity.
2. `activeThemeProvider` (ownership-gated, Sand fallback) + wire `app.dart` +
   `kCatalogThemeIds` + the 4 hourglass callers. Tests.
3. À-la-carte billing extension (`ThemeProduct`/`themeProducts`/`purchaseTheme`
   in interface + fake + RevenueCat). Tests with the fake.
4. Themes screen (grid + preview sheet + Apply/Buy/Get Pro) + Settings entry;
   gating. Widget tests. Polish with impeccable.
5. Live preview: `previewThemeProvider` + app-wide preview bar + `SessionScreen`
   `previewMode` (~10s cap, no persist) + route Begin to it while previewing.
   Tests.
6. On-device palette tuning pass with the founder (the hero must look premium).
7. Full analyze + tests + deploy + commit.
