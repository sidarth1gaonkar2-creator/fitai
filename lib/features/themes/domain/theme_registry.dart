import 'package:flutter/painting.dart';

import '../../../core/theme/surface_texture.dart';
import 'app_theme_data.dart';

// Night Ops surface texture — dark tactical camo darkened toward near-black
// (NVG/HUD grain, derived from design-refs/Nightops texture skin.jpg). Every
// tone is capped at #1C1C1C so text over the lightest lobe holds WCAG AA
// (bone 13.6:1, amber 9.4:1).
// Density raised so the camo scatter fills the near-solid voids the original
// left between shards. The knob is subtler than it looks: tones are painted
// opaque in order (darkest → lightest), so simply raising the COUNT floods the
// top tone and flattens the tile toward uniform. The fix is SMALLER shards at a
// higher count — each covers less, so more tonal patches stay visible and the
// gaps break up. Radius range narrowed from 0.045–0.13 to 0.025–0.08 and the
// count raised 72 → 120 per tone (216 → 360 shards total). Same seed, so the
// layout is deterministic and never shimmers on repaint. Contrast is unchanged
// (same near-black tones) — more shapes, not louder ones. Generation is a
// one-time bake into the cached tile, so per-frame cost is unchanged.
const SurfaceTexture _nightOpsTexture = SurfaceTexture(
  id: 'night_ops',
  base: Color(0xFF050505),
  tones: [Color(0xFF0D0D0D), Color(0xFF151515), Color(0xFF1C1C1C)],
  blobsPerTone: 120,
  minRadiusFactor: 0.025,
  maxRadiusFactor: 0.08,
  tileSize: 480,
  seed: 7,
);

// Woodland surface texture — US M81 woodland camo (design-refs/
// WTP-1000-US-Woodland-M81-Camo.jpg) at proper character: four distinct HUES,
// not Night Ops's four neutral greys. That hue variety is what makes it read
// as field camo while every tone stays dark enough for AA.
//
// Where Night Ops darkened its reference toward near-black, Woodland keeps the
// print's warmth and caps LIGHTNESS instead. The khaki lobe (#524A2C) is the
// lightest thing text can land on. The binding text tone is `alert`, not bone
// and not muted bone — being the darkest tone, it fails first, and it sets the
// ceiling at L <= 0.0801 for every ground and card surface in this skin.
//
// Shape differs from Night Ops by design: medium, smooth-edged lobes (M81 is a
// soft print, not grain) instead of fine hard-edged ones. Sized so ~2 tile
// repeats cross a phone screen — big enough to read as camo shapes, small
// enough that several land in view. The near-black lobe is painted LAST, the
// way the real four-colour print overlays its black.
const SurfaceTexture _woodlandTexture = SurfaceTexture(
  id: 'woodland',
  base: Color(0xFF313A1E), // dominant olive drab
  tones: [
    Color(0xFF453823), // brown
    Color(0xFF524A2C), // khaki/tan — lightest lobe; the AA worst case
    Color(0xFF1B1F10), // near-black M81 overlay, painted on top
  ],
  blobsPerTone: 24, // fewer, larger shapes than Night Ops's 72 fine ones
  tileSize: 420,
  seed: 7,
  smooth: true, // soft printed-fabric edges, not tactical grain
  minRadiusFactor: 0.07,
  maxRadiusFactor: 0.18,
);

/// Static catalogue of all themes shipped with the app. Order here defines
/// the order shown in the store grid. The first entry MUST be the default
/// (free, always owned) so [defaultTheme] never returns null.
///
/// Since reskin batch #3 the Accent Swap Rule (DESIGN.md) holds for real:
/// every pack is an accent swap riding Field Manual chrome. Surfaces
/// (ink/field/field-raised), bone text, hairline borders, and the FM success
/// green are identical across packs — a pack contributes only its accent
/// family (accent, accentLight, accentPressed, lightAccent) and its identity
/// (id, name, price, isPremium). The packs' own surface colours — pure
/// blacks, tinted darks — are gone by design, not by accident.
///
/// accentPressed is derived per pack: each channel of the accent × 0.82
/// (≈18% darker), the same ratio that takes brass 0xFFC8A24B to
/// brass-pressed 0xFFA38443.

// ── Shared Field Manual chrome (every pack rides these) ─────────────────────
const Color _ink = Color(0xFF1A1C1A);
const Color _field = Color(0xFF21241F);
const Color _fieldRaised = Color(0xFF2A2E26);
const Color _bone = Color(0xFFE8E4D8);
const Color _mutedBone = Color(0xFFCDC8BA);
// Lifted olive: the FM olive raised to hold ≥4.5:1 on ink so inactive tab
// labels stay AA-legible (base olive #6B7257 is 3.4:1 — structure only, per
// the Olive Floor Rule).
const Color _liftedOlive = Color(0xFF8C9377);
const Color _hairline = Color(0x1FE8E4D8); // bone @12%
const Color _separator = Color(0x14E8E4D8); // bone @8%
const Color _fmSuccess = Color(0xFF3FBF4A);

// Dress Blues surface textures — the ceremonial parade uniform
// (design-refs/uniform.png, gold braid, brass buttons). TWO materials, unlike
// the other skins:
//
// The ground is navy TWILL (design-refs/dark navy twill fabric texture.png):
// fine diagonal ribs whose tones sit barely above the base. That restraint is
// the point — this skin's premium quality comes from refinement, not from
// ruggedness, so the texture must give depth without ever reading as pattern.
// Camo lobes at any parameter setting would read as field kit, not parade
// dress, which is why the directional weave generator exists.
//
// A BRUSHED-METAL band (design-refs/navy blue brushed metal texture.png) is
// laid across the top of the ground and faded out into the twill — the
// hardware register of the brass button and belt plate above the cloth.
// Both textures are deliberately near the threshold of visibility. A first
// pass ran the twill at pitch 6 with tone deltas up to +13/channel and it read
// as diagonal SCRATCHES — the exact failure this skin can't afford, since a
// visible pattern is ruggedness and ruggedness is the other two skins' job.
// Refinement means the weave is felt, not seen: fine pitch, deltas of 2–5.
const SurfaceTexture _dressBluesTwill = SurfaceTexture(
  id: 'dress_blues_twill',
  base: Color(0xFF161B2C),
  tones: [Color(0xFF171C2E), Color(0xFF191E32)],
  tileSize: 480,
  seed: 7,
  pattern: SurfaceTexturePattern.twillWeave,
  ribPitch: 3, // 480 % 3 == 0, so the diagonal wraps seamlessly
);

// The header band sits just above the twill, so it reads as a sheen catching
// the light across the top rather than as a separate lighter plate. Tuned
// twice: the first pass was a distinct plate (#1E2540 base, streaks to
// #2C3557) that looked like scan-line corruption; the correction went so far
// the band vanished, which would have shipped a twill-only skin while
// claiming two materials. This is the middle — perceptible, never noisy.
const SurfaceTexture _dressBluesMetal = SurfaceTexture(
  id: 'dress_blues_metal',
  base: Color(0xFF1C2139),
  tones: [Color(0xFF1F2540), Color(0xFF222948)],
  tileSize: 480,
  seed: 11,
  pattern: SurfaceTexturePattern.brushedMetal,
  ribPitch: 3,
);

const List<AppThemeData> themeRegistry = [
  // 1. Default — the Field Manual: brass on ink, the app's brand issue
  // (DESIGN.md). The id stays 'midnight_blue' so installs that persisted the
  // old default in UserThemeState keep resolving to the default theme.
  AppThemeData(
    id: 'midnight_blue',
    name: 'Field Manual',
    accent: Color(0xFFC8A24B), // brass
    accentLight: Color(0xFFE0C27E),
    success: _fmSuccess,
    surfaceTint: Color(0xFFC8A24B),
    darkBackground: _ink,
    darkSurface: _field,
    lightAccent: Color(0xFF8A6937), // brass-ink, AA on white
    price: 0,
    accentPressed: Color(0xFFA38443), // brass × 0.82 — the reference ratio
    darkText: _bone,
    darkTextSecondary: _mutedBone,
    darkTextTertiary: _liftedOlive,
    darkSurfaceElevated: _fieldRaised,
    darkBorder: _hairline,
    darkSeparator: _separator,
  ),

  // 2. Slate — monochrome / minimalist. Free unlock on first launch.
  AppThemeData(
    id: 'slate',
    name: 'Slate',
    accent: Color(0xFF8E8E93),
    accentLight: Color(0xFFA0A0A5),
    success: _fmSuccess,
    surfaceTint: Color(0xFF8E8E93),
    darkBackground: _ink,
    darkSurface: _field,
    lightAccent: Color(0xFF636366), // WCAG AA-safe on white
    price: 0,
    accentPressed: Color(0xFF747479), // 0x8E8E93 × 0.82
    darkText: _bone,
    darkTextSecondary: _mutedBone,
    darkTextTertiary: _liftedOlive,
    darkSurfaceElevated: _fieldRaised,
    darkBorder: _hairline,
    darkSeparator: _separator,
  ),

  // 3. Emerald — green energy.
  AppThemeData(
    id: 'emerald',
    name: 'Emerald',
    accent: Color(0xFF30D158),
    accentLight: Color(0xFFA8F0C1),
    success: _fmSuccess,
    surfaceTint: Color(0xFF30D158),
    darkBackground: _ink,
    darkSurface: _field,
    lightAccent: Color(0xFF248A3D), // darker green for AA contrast
    price: 500,
    accentPressed: Color(0xFF27AB48), // 0x30D158 × 0.82
    darkText: _bone,
    darkTextSecondary: _mutedBone,
    darkTextTertiary: _liftedOlive,
    darkSurfaceElevated: _fieldRaised,
    darkBorder: _hairline,
    darkSeparator: _separator,
  ),

  // 4. Sunset — warm amber.
  AppThemeData(
    id: 'sunset',
    name: 'Sunset',
    accent: Color(0xFFFF9F0A),
    accentLight: Color(0xFFFFD60A),
    success: _fmSuccess,
    surfaceTint: Color(0xFFFF9F0A),
    darkBackground: _ink,
    darkSurface: _field,
    lightAccent: Color(0xFFC76E00),
    price: 500,
    accentPressed: Color(0xFFD18208), // 0xFF9F0A × 0.82
    darkText: _bone,
    darkTextSecondary: _mutedBone,
    darkTextTertiary: _liftedOlive,
    darkSurfaceElevated: _fieldRaised,
    darkBorder: _hairline,
    darkSeparator: _separator,
  ),

  // 5. Crimson — red.
  AppThemeData(
    id: 'crimson',
    name: 'Crimson',
    accent: Color(0xFFFF453A),
    accentLight: Color(0xFFFF6B6B),
    success: _fmSuccess,
    surfaceTint: Color(0xFFFF453A),
    darkBackground: _ink,
    darkSurface: _field,
    lightAccent: Color(0xFFC2261B),
    price: 750,
    accentPressed: Color(0xFFD13930), // 0xFF453A × 0.82
    darkText: _bone,
    darkTextSecondary: _mutedBone,
    darkTextTertiary: _liftedOlive,
    darkSurfaceElevated: _fieldRaised,
    darkBorder: _hairline,
    darkSeparator: _separator,
  ),

  // 6. Ocean — aqua / cyan.
  AppThemeData(
    id: 'ocean',
    name: 'Ocean',
    accent: Color(0xFF64D2FF),
    accentLight: Color(0xFF40C8E0),
    success: _fmSuccess,
    surfaceTint: Color(0xFF64D2FF),
    darkBackground: _ink,
    darkSurface: _field,
    lightAccent: Color(0xFF0080A8),
    price: 750,
    accentPressed: Color(0xFF52ACD1), // 0x64D2FF × 0.82
    darkText: _bone,
    darkTextSecondary: _mutedBone,
    darkTextTertiary: _liftedOlive,
    darkSurfaceElevated: _fieldRaised,
    darkBorder: _hairline,
    darkSeparator: _separator,
  ),

  // 7. Lavender — purple.
  AppThemeData(
    id: 'lavender',
    name: 'Lavender',
    accent: Color(0xFFBF5AF2),
    accentLight: Color(0xFFDA9FFA),
    success: _fmSuccess,
    surfaceTint: Color(0xFFBF5AF2),
    darkBackground: _ink,
    darkSurface: _field,
    lightAccent: Color(0xFF8E2BC2),
    price: 1000,
    accentPressed: Color(0xFF9D4AC6), // 0xBF5AF2 × 0.82
    darkText: _bone,
    darkTextSecondary: _mutedBone,
    darkTextTertiary: _liftedOlive,
    darkSurfaceElevated: _fieldRaised,
    darkBorder: _hairline,
    darkSeparator: _separator,
  ),

  // 8. Neon Pulse — premium, magenta + indigo.
  AppThemeData(
    id: 'neon_pulse',
    name: 'Neon Pulse',
    accent: Color(0xFFFF2D55),
    accentLight: Color(0xFF5E5CE6),
    success: _fmSuccess,
    surfaceTint: Color(0xFFFF2D55),
    darkBackground: _ink,
    darkSurface: _field,
    lightAccent: Color(0xFFD60036),
    price: 2000,
    isPremium: true,
    accentPressed: Color(0xFFD12546), // 0xFF2D55 × 0.82
    darkText: _bone,
    darkTextSecondary: _mutedBone,
    darkTextTertiary: _liftedOlive,
    darkSurfaceElevated: _fieldRaised,
    darkBorder: _hairline,
    darkSeparator: _separator,
  ),

  // 9. Stealth — premium, monochrome gunmetal. The accent is a lifted cool
  // grey, not the near-black 0xFF48484A it shipped as: on FM chrome that old
  // tone was 1.7:1 on field (invisible as text/border/icon). Lifted to
  // 0xFF8A9098 — still a desaturated gunmetal, distinct from Slate's neutral
  // 0xFF8E8E93 by its cooler blue cast — which reads 4.88:1 on field and
  // 5.33:1 on ink, and clears the 0.18-luminance onAccent flip (ink on accent).
  AppThemeData(
    id: 'stealth',
    name: 'Stealth',
    accent: Color(0xFF8A9098),
    accentLight: Color(0xFFB0B4BA),
    success: _fmSuccess,
    surfaceTint: Color(0xFF8A9098),
    darkBackground: _ink,
    darkSurface: _field,
    lightAccent: Color(0xFF4B5058), // darker gunmetal, AA on white
    price: 2000,
    isPremium: true,
    accentPressed: Color(0xFF71767D), // 0x8A9098 × 0.82
    darkText: _bone,
    darkTextSecondary: _mutedBone,
    darkTextTertiary: _liftedOlive,
    darkSurfaceElevated: _fieldRaised,
    darkBorder: _hairline,
    darkSeparator: _separator,
  ),

  // 10. Night Ops — the first FULL SKIN (not an accent swap): a pure-black
  // OLED tactical skin with a night-vision HUD readout feel. It restyles
  // surfaces (true #000 ground), geometry (near-zero regulation corners), and
  // type (display face → mono terminal) on top of an amber tactical accent —
  // the new full-skin tier above the Accent Swap Rule (DESIGN.md). Insignia
  // keep their tier colours and the Airborne mount stays brass (both drawn
  // from constants a skin can't touch), so the sacred carve-outs hold.
  //
  // ECONOMY: a $2.99 CASH pack (cashPriceCents), NOT a coin theme —
  // price 0 keeps it out of isStandardCoinTheme / Airborne unlocks. IAP is
  // deferred; ownedByDefault grants it for on-device preview until StoreKit
  // is wired. Every colour holds WCAG AA on true black (bone 16.8:1, amber
  // 11.6:1, ink-on-amber 8.7:1).
  AppThemeData(
    id: 'night_ops',
    name: 'Night Ops',
    accent: Color(0xFFFF3B3B), // infrared reticle red — 5.94:1 on #000 (AA)
    accentLight: Color(0xFFFF7A7A),
    success: _fmSuccess,
    surfaceTint: Color(0xFFFF3B3B),
    darkBackground: Color(0xFF000000), // true black, OLED
    darkSurface: Color(0xFF0A0A0A), // whisper-lift so cards read
    lightAccent: Color(0xFFB3261E), // dark red, AA on white (light retired)
    price: 0, // sold for cash, not coins — see cashPriceCents
    cashPriceCents: 299,
    ownedByDefault: true, // previewable on device; IAP deferred
    accentPressed: Color(0xFFD13030), // red × 0.82 — the reference ratio
    // Accent is red, so route destructive/alert OFF red to amber — a HUD
    // caution tone, distinct from the reticle-red accent (alert collision).
    darkAlert: Color(0xFFFFB000),
    darkText: _bone,
    darkTextSecondary: _mutedBone,
    darkTextTertiary: _liftedOlive,
    darkSurfaceElevated: Color(0xFF161616),
    darkBorder: Color(0x3DE8E4D8), // bone @24% — HUD viewport hairline on black
    darkSeparator: Color(0x1FE8E4D8), // bone @12%
    // Full-skin overrides — the material, not just the accent:
    surfaceTexture: _nightOpsTexture, // tactical camo grain behind backgrounds
    cardBrackets: true, // HUD viewport frame + corner brackets on cards
    accentGlow: true, // amber blooms on true black (HUD signal)
    cardRadius: 2, // sharp regulation corners (FM 8)
    sheetRadius: 4, // (FM 12)
    buttonRadius: 2, // (FM 4)
    displayFontFamily: 'JetBrainsMono', // terminal HUD headers (FM Oswald)
  ),

  // 12. Woodland — the second FULL SKIN: "issued field gear". The warm
  // counterpart to Night Ops's cold OLED HUD. Where Night Ops is a targeting
  // display (true black, sharp 2px corners, HUD brackets, glowing infrared),
  // Woodland is worn kit (warm olive-drab, soft 14px corners, matte panels,
  // no glow anywhere). Sold for COINS at the premium tier — earned, not IAP.
  //
  // Doctrine note: DESIGN.md §6 says "no camo textures". The full-skin tier
  // (introduced by Night Ops) is the documented carve-out — a premium skin may
  // change the MATERIAL, not just the accent. Woodland leans on it hardest, so
  // the restraint rule is enforced structurally instead of by convention: the
  // texture is a screen-ground material only, and every card/sheet fill is
  // near-solid, so camo never lands under a number the user trains against.
  AppThemeData(
    id: 'woodland',
    name: 'Woodland',
    accent: Color(0xFFC2D473), // olive-khaki; hue 71° vs brass 42°, success 126°
    accentLight: Color(0xFFD6E39A),
    // Success lifts off FM's #3FBF4A so it clears AA on these warmer, lighter
    // surfaces. It stays a true green (hue 126°) while the accent sits at
    // hue 71° — a 55° gap, so "selected" never reads as "succeeded".
    success: Color(0xFF7FDA88),
    surfaceTint: Color(0xFFC2D473),
    // Olive drab with real chroma (hue 79°), not a neutral dark that happens
    // to be green-tinted. FM's ink is already tinted, so matching its hue and
    // only lifting lightness made Woodland read as "FM, greener" — it has to
    // win on saturation. Verified: mean-colour separation from FM 7.9 -> 39.7.
    darkBackground: Color(0xFF313A1E), // deep olive drab — warm, never black
    darkSurface: Color(0xFF3B4524), // canvas-pouch panel
    lightAccent: Color(0xFF4A5825), // dark olive, AA on white (light retired)
    price: 2000,
    isPremium: true,
    accentPressed: Color(0xFF9FAE5E), // accent × 0.82 — the reference ratio
    // FM's brick red (#C24A38) only reaches 2.85–3.54:1 even on FM's own
    // darker surfaces; on Woodland's lighter warm ground it fails outright.
    // Routed to a faded stencil-warning coral that clears AA on every surface
    // including the worst camo lobe — and reads as weathered paint. This is
    // also the tone that BINDS the whole skin: being the darkest text tone it
    // caps every surface at L <= 0.0801.
    darkAlert: Color(0xFFF8B0A0),
    darkText: _bone,
    darkTextSecondary: _mutedBone,
    darkTextTertiary: Color(0xFFC3CBA6), // lifted olive for these surfaces
    darkSurfaceElevated: Color(0xFF47522B),
    // Warm tan hairline instead of bone-alpha: the stitched edge of canvas
    // webbing rather than a machined bezel. Carried at a higher alpha than the
    // other skins' borders on purpose — over a patterned ground a card sits on
    // a LIGHTER tan lobe in one place and a DARKER black lobe in another, so a
    // faint hairline lets the panel edge dissolve wherever the two happen to
    // match. The border is what keeps a card reading as a card.
    darkBorder: Color(0x59D8C9A8),
    darkSeparator: Color(0x33D8C9A8),
    // Full-skin overrides — the material, not just the accent:
    surfaceTexture: _woodlandTexture,
    cardBrackets: false, // matte issued gear — the HUD frame is Night Ops only
    accentGlow: false, // glow is Night-Ops HUD doctrine; worn gear is matte
    cardRadius: 14, // softened, worn corners (FM 8, Night Ops 2)
    sheetRadius: 20, // (FM 12, Night Ops 4)
    buttonRadius: 10, // (FM 4, Night Ops 2)
    // Type stays Oswald (no stencil face is bundled, and true stencil counters
    // hurt legibility at label sizes). The stencil register comes from weight
    // and tracking instead: every display style at 700, tracked wide so
    // headers read as stamped crate marking, not condensed chrome.
    headlineWeight: 700, // FM 600
    titleWeight: 700, // FM 600
    displayTrackingEm: 0.08, // FM ≈0.011em — the signature move
  ),

  // 13. Dress Blues — the AIRBORNE-EXCLUSIVE FLAGSHIP full skin. Ceremonial
  // parade uniform: deep dress navy, gold-braid accent, brass trim.
  //
  // The design risk here is the opposite of the other two full skins. Night
  // Ops and Woodland earn their premium feel through rugged MATERIAL; if
  // Dress Blues tried that it would just be a navy theme with a texture.
  // Its premium quality has to come from REFINEMENT, so it is built from
  // three restrained moves rather than one loud one:
  //   1. a barely-there twill weave (depth, not pattern),
  //   2. metallic brass TRIM — the gold hairline on every card and divider,
  //      which is the actual ceremonial signal, and
  //   3. crisp geometry and open, formal tracking; nothing busy.
  //
  // The trim costs no new painter code: CupertinoCard already strokes
  // `palette.border`, so pointing darkBorder at gold puts a brass hairline on
  // every card, sheet and separator app-wide.
  AppThemeData(
    id: 'dress_blues',
    name: 'Dress Blues',
    // Gold braid, not FM brass. Same hue family by definition — braid IS
    // brass-family — but lifted well clear in luminance (0.518 vs 0.386) so
    // it reads as polished bullion against navy rather than as FM's accent.
    accent: Color(0xFFD9BC6A),
    accentLight: Color(0xFFEBD79B),
    success: Color(0xFF5BD16A),
    surfaceTint: Color(0xFFD9BC6A),
    darkBackground: Color(0xFF161B2C), // deepest dress navy
    darkSurface: Color(0xFF1E2540), // card / panel
    lightAccent: Color(0xFF7A5E1B), // dark gold, AA on white (light retired)
    // NOT sold: price 0 with airborneExclusive, so isCoinPurchasable() is
    // false and every purchase path refuses it. Not ownedByDefault either —
    // it re-locks the moment the subscription lapses.
    price: 0,
    airborneExclusive: true,
    accentPressed: Color(0xFFB29A57), // gold × 0.82 — the reference ratio
    // FM's brick red is far too dark to hold AA on navy; lifted to a
    // parade-sash red that clears 4.76:1 even on the lightest metal streak.
    darkAlert: Color(0xFFF0857A),
    darkText: _bone,
    darkTextSecondary: _mutedBone,
    darkTextTertiary: Color(0xFFA6B0CE), // steel blue — the uniform's shadow
    darkSurfaceElevated: Color(0xFF29314F),
    // THE BRASS TRIM. Gold at 60% is a hairline of bullion on every card and
    // sheet; separators run weaker so rows stay quiet. This is the single
    // highest-leverage line in the skin.
    darkBorder: Color(0x99D9BC6A),
    darkSeparator: Color(0x4DD9BC6A),
    // Two materials: twill ground, brushed-metal header band faded into it.
    surfaceTexture: _dressBluesTwill,
    headerTexture: _dressBluesMetal,
    headerBandHeight: 260,
    cardBrackets: false, // brackets are Night Ops's HUD signature
    accentGlow: false, // and glow is HUD doctrine, not ceremony
    cardRadius: 6, // crisp and precise (FM 8, Night Ops 2, Woodland 14)
    sheetRadius: 10,
    buttonRadius: 3,
    // Refinement reads as lighter and more open, not heavier: the display
    // face drops to 600 (FM 700) and the tracking opens to a formal,
    // inscription-like 0.05em — half of Woodland's stencil 0.08em.
    displayWeight: 600,
    displayTrackingEm: 0.05,
  ),
];

/// The default theme — guaranteed to be in [themeRegistry] (first entry).
/// Every user owns this theme implicitly. Mirrors the registry's Field
/// Manual entry exactly.
const AppThemeData defaultTheme = AppThemeData(
  id: 'midnight_blue',
  name: 'Field Manual',
  accent: Color(0xFFC8A24B),
  accentLight: Color(0xFFE0C27E),
  success: _fmSuccess,
  surfaceTint: Color(0xFFC8A24B),
  darkBackground: _ink,
  darkSurface: _field,
  lightAccent: Color(0xFF8A6937),
  price: 0,
  accentPressed: Color(0xFFA38443),
  darkText: _bone,
  darkTextSecondary: _mutedBone,
  darkTextTertiary: _liftedOlive,
  darkSurfaceElevated: _fieldRaised,
  darkBorder: _hairline,
  darkSeparator: _separator,
);

/// Resolves a theme by ID, falling back to [defaultTheme] when the ID isn't
/// in the registry (e.g. a removed theme that's still equipped on an old
/// install).
AppThemeData themeById(String id) {
  for (final t in themeRegistry) {
    if (t.id == id) return t;
  }
  return defaultTheme;
}
