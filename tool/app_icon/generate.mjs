// DrillFit app icon generator — Field Manual language (DESIGN.md).
// Emits: icon.svg (master), the 1024x1024 sRGB no-alpha PNGs (universal +
// explicit dark + tinted iOS 18 variants) into the iOS appiconset, and masked
// legibility previews at 180/120/60 px.
//
//   npm install && node generate.mjs
//
// The mark is the DrillFit brand chevron stack (drillfit-site logo geometry:
// 28-unit chevrons, 9-unit rise, 10-unit spacing, round caps/joins), scaled
// onto ink with a restrained radial lift toward field. No text, no wings —
// jump-wings belong to Airborne surfaces only.

import { mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import sharp from 'sharp';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const APPICONSET = path.resolve(
  HERE,
  '../../ios/Runner/Assets.xcassets/AppIcon.appiconset',
);
const OUT_ICON = path.join(APPICONSET, 'AppIcon-1024.png');
const OUT_DARK = path.join(APPICONSET, 'AppIcon-1024-dark.png');
const OUT_TINTED = path.join(APPICONSET, 'AppIcon-1024-tinted.png');
const PREVIEW_DIR = path.join(HERE, 'previews');

// ---- palette (DESIGN.md) ----------------------------------------------------
const INK = '#1A1C1A';
const FIELD = '#21241F';
const BRASS = '#C8A24B';

// ---- mark geometry (site-logo units: chevron width 28, rise 9, pitch 10) ----
const SIZE = 1024;
// Stroke in logo units (site uses 3.4 at nav size; icons want a touch more
// muscle — tuned against the 60 px legibility gate).
const STROKE = Number(process.env.ICON_STROKE ?? 4.8);
// Fraction of the canvas the mark's ink width occupies.
const MARK_WIDTH_FRAC = Number(process.env.ICON_SCALE ?? 0.58);

const CHEV_W = 28; // x: 6..34 in logo space
const RISE = 9;
const PITCH = 10;
const APEX_X = 20;
const TOP_APEX_Y = 11;

const capR = STROKE / 2;
const inkW = CHEV_W + STROKE; // round caps extend by capR each side
const inkTop = TOP_APEX_Y - capR; // round apex join extends up by ~capR
const inkBottom = TOP_APEX_Y + RISE + 2 * PITCH + capR; // bottom baseline + cap
const S = (SIZE * MARK_WIDTH_FRAC) / inkW;
const markH = (inkBottom - inkTop) * S;

// Optical center: the stack is bottom-heavy (top chevron tapers to an apex,
// bottom terminates in full-width caps), so geometric centering reads low.
// Nudge up ~1% of canvas to put the pixel-mass centroid on center.
const OPTICAL_NUDGE_Y = -10;
const tx = SIZE / 2 - APEX_X * S;
const ty = SIZE / 2 - ((inkTop + inkBottom) / 2) * S + OPTICAL_NUDGE_Y;

const chevron = (y) =>
  `M${APEX_X - CHEV_W / 2} ${y} L${APEX_X} ${y - RISE} L${APEX_X + CHEV_W / 2} ${y}`;

const markGroup = (stroke) => `<g transform="translate(${tx.toFixed(2)} ${ty.toFixed(2)}) scale(${S.toFixed(4)})"
     fill="none" stroke="${stroke}" stroke-width="${STROKE}"
     stroke-linecap="round" stroke-linejoin="round">
    <path d="${chevron(TOP_APEX_Y + RISE)}"/>
    <path d="${chevron(TOP_APEX_Y + RISE + PITCH)}"/>
    <path d="${chevron(TOP_APEX_Y + RISE + 2 * PITCH)}"/>
  </g>`;

// Universal (and dark): brass mark on ink with a subtle radial lift toward
// field. No glow — Quiet Chrome; glow is for earned ceremonies only.
const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${SIZE}" height="${SIZE}" viewBox="0 0 ${SIZE} ${SIZE}">
  <defs>
    <radialGradient id="lift" cx="50%" cy="42%" r="72%">
      <stop offset="0%" stop-color="${FIELD}"/>
      <stop offset="100%" stop-color="${INK}"/>
    </radialGradient>
  </defs>
  <rect width="${SIZE}" height="${SIZE}" fill="url(#lift)"/>
  ${markGroup(BRASS)}
</svg>
`;

// iOS 18 tinted variant: grayscale — light glyph on black; the system maps
// luminance to its tint. Authored explicitly so mono rendering is a decision,
// not an auto-derivation.
const tintedSvg = `<svg xmlns="http://www.w3.org/2000/svg" width="${SIZE}" height="${SIZE}" viewBox="0 0 ${SIZE} ${SIZE}">
  <rect width="${SIZE}" height="${SIZE}" fill="#000000"/>
  ${markGroup('#E6E6E6')}
</svg>
`;

// iOS-style corner mask (rounded rect at Apple's ~22.37% radius).
const maskSvg = (px) => {
  const r = (px * 0.2237).toFixed(2);
  return Buffer.from(
    `<svg xmlns="http://www.w3.org/2000/svg" width="${px}" height="${px}"><rect width="${px}" height="${px}" rx="${r}" ry="${r}" fill="#fff"/></svg>`,
  );
};

const maskedPng = async (masterPng, px) =>
  sharp(masterPng)
    .resize(px, px)
    .composite([{ input: maskSvg(px), blend: 'dest-in' }])
    .png()
    .toBuffer();

async function main() {
  await mkdir(PREVIEW_DIR, { recursive: true });
  await mkdir(path.dirname(OUT_ICON), { recursive: true });

  await writeFile(path.join(HERE, 'icon.svg'), svg);
  await writeFile(path.join(HERE, 'icon-tinted.svg'), tintedSvg);

  // Master: full-bleed square, sRGB, 8-bit, NO alpha (App Store requirement).
  const rasterize = (svgText, background) =>
    sharp(Buffer.from(svgText), { density: 72 })
      .flatten({ background })
      .removeAlpha()
      .toColourspace('srgb')
      .png({ compressionLevel: 9 })
      .toBuffer();
  const masterPng = await rasterize(svg, INK);
  await writeFile(OUT_ICON, masterPng);
  // Dark variant: same artwork — the icon is dark by doctrine.
  await writeFile(OUT_DARK, masterPng);
  await writeFile(OUT_TINTED, await rasterize(tintedSvg, '#000000'));

  // Legibility previews: masked renders at 180/120/60 on dark + light grounds,
  // plus a 4x nearest-neighbour blowup of the 60 px render.
  const sizes = [180, 120, 60];
  const masked = {};
  for (const px of sizes) {
    masked[px] = await maskedPng(masterPng, px);
    await writeFile(path.join(PREVIEW_DIR, `icon-${px}.png`), masked[px]);
  }
  const zoom60 = await sharp(masked[60])
    .resize(240, 240, { kernel: 'nearest' })
    .png()
    .toBuffer();
  await writeFile(path.join(PREVIEW_DIR, 'icon-60-4x.png'), zoom60);

  const PAD = 24;
  const rowH = 240 + PAD * 2;
  const sheetW = PAD + (180 + PAD) + (120 + PAD) + (60 + PAD) + (240 + PAD);
  const row = (bg) =>
    sharp({ create: { width: sheetW, height: rowH, channels: 3, background: bg } })
      .composite([
        { input: masked[180], left: PAD, top: PAD },
        { input: masked[120], left: PAD + 180 + PAD, top: PAD + 30 },
        { input: masked[60], left: PAD + 180 + PAD + 120 + PAD, top: PAD + 60 },
        { input: zoom60, left: PAD + 180 + PAD + 120 + PAD + 60 + PAD, top: PAD },
      ])
      .png()
      .toBuffer();
  const dark = await row({ r: 13, g: 13, b: 13 });
  const light = await row({ r: 229, g: 227, b: 220 });
  await sharp({
    create: { width: sheetW, height: rowH * 2, channels: 3, background: '#000' },
  })
    .composite([
      { input: dark, left: 0, top: 0 },
      { input: light, left: 0, top: rowH },
    ])
    .png()
    .toFile(path.join(PREVIEW_DIR, 'sheet.png'));

  console.log(
    `stroke=${STROKE} scale=${MARK_WIDTH_FRAC} markW=${Math.round(inkW * S)}px markH=${Math.round(markH)}px strokePx=${(STROKE * S).toFixed(1)} (${((STROKE * S) / 17.07).toFixed(1)}px @60)`,
  );
  console.log(`icon  -> ${OUT_ICON}`);
  console.log(`sheet -> ${path.join(PREVIEW_DIR, 'sheet.png')}`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
