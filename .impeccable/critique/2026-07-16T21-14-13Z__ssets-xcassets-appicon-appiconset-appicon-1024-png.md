---
target: DrillFit iOS app icon (Field Manual brass chevron)
total_score: 14
p0_count: 1
p1_count: 1
timestamp: 2026-07-16T21-14-13Z
slug: ssets-xcassets-appicon-appiconset-appicon-1024-png
---
Method: dual-agent (A: a2492aa2add058358 · B: af6951c1fd55facc3)

# Critique — DrillFit iOS app icon (Field Manual, brass chevron stack on ink)

Target: `ios/Runner/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png` (master), previews in `tool/app_icon/previews/`.

## Design Health Score (adapted to a static app icon)

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | n/a | static icon |
| 2 | Match System / Real World | 4 | authentic E-5 chevron grammar; brass-on-ink = insignia hardware; up = promotion |
| 3 | User Control and Freedom | n/a | static icon |
| 4 | Consistency and Standards | 3 | legacy asset-catalog format still shipping old icon (P0); no iOS 18 dark/tinted variants (P2) |
| 5 | Error Prevention | n/a | static icon |
| 6 | Recognition Rather Than Recall | 3 | instant match to site/in-app insignia; bare silhouette shared with generic "upload/boost" glyphs — palette differentiates |
| 7 | Flexibility and Efficiency | n/a | static icon |
| 8 | Aesthetic and Minimalist Design | 4 | one glyph, two hues, flat stroke, no badge/text/bevel |
| 9 | Error Recovery | n/a | static icon |
| 10 | Help and Documentation | n/a | static icon |
| **Total** | | **14/16 applicable** | **Good** |

## Anti-Patterns Verdict

**LLM assessment (A):** Passes on execution. The layout ("single centered glyph, dark ground, radial glow") is the AI-icon template, but the discipline is not: real brand-mark geometry (byte-identical site-logo paths), one flat brass stroke (#C8A24B sampled exact everywhere), no bevel/metallic gradient/badge ring/long-shadow, two-tone material ground with zero banding. Clears all anti-references: no system blue, no Apple Fitness lineage, no purple-gradient slop. iOS test: a fluent iPhone user would trust it — gold-on-near-black reads premium/serious.

**Deterministic scan (B):** `detect.mjs` ran clean on `icon.svg` (exit 0, `[]`) — expected limited relevance for a native icon. Technical compliance all green: 1024×1024, 3-channel (no alpha), sRGB 8-bit PNG, full-bleed opaque corners at ink, brass vs ink contrast 7.12:1 (≥3:1 WCAG 1.4.11 non-text; also clears 4.5:1), pipeline bit-for-bit reproducible (identical SHA256 across runs). Geometry identical to site logo up to scale/translation; sole deviation stroke 4.8 vs 3.4 (+41%), intentional and documented in the generator.

**Where they agree:** 60px legibility gate passes — A visually (three distinct chevrons, no fill-in, no shimmer; chosen 4.8/58% beats wispy 4.2/56% and congesting 5.4/60%); B numerically (5.09px stroke, 4.56px clear gap at 60px). **Where B caught what A couldn't quantify:** the "restrained glow" measures 2/255 warm shift — it is metrologically invisible (P3).

## Overall Impression

The brand mark doing its actual job: site logo, home screen, and in-app rank insignia now share one chevron grammar, and the mark literally means "promotion." Old icon (six blue chevrons + dumbbell) → new (three brass chevrons, no cliché) is a categorical upgrade. Biggest opportunity: it isn't wired into the build yet.

## What's Working

1. The variant sheet proves the weight decision (4.8/58% vs evidenced rejects) — process rigor most icon work skips.
2. Palette discipline under a cliché layout — flat stroke, material ground, nothing to confess under measurement (except the glow, which confesses by not existing).
3. One grammar across three surfaces; the icon rehearses the rank mechanic daily.

## Priority Issues

- **[P0] New icon not in the build**: Contents.json references only legacy Icon-App-*.png (all still the old blue icon); AppIcon-1024.png is an orphan. Fix: modernize to Xcode single-size format, delete per-size litter. *(wiring step of this mission)*
- **[P1] Mark sits optically low**: pixel-mass centroid 7.8px below canvas center (bottom third 9% heavier — apex tapers, caps don't). Fix: nudge mark up ~8–12px at 1024, flip-test, re-verify 60px.
- **[P2] No iOS 18 dark/tinted variants**: auto-derived tinting is a guess, not a decision. Fix: author explicit dark (already-dark artwork) and tinted (grayscale) variants in the single-size catalog.
- **[P3] The glow is a fiction**: 7% peak opacity → 2/255 measured. Quiet Chrome doctrine: delete it; the ink→field lift already does the job honestly.
- **[P3] Round caps vs "regulation equipment"**: slightly consumer-soft; justified by site-mark fidelity + 60px rasterization. Revisit only if the site mark ever sharpens.

## Minor Observations

- Verify against pure white (App Store grid) in addition to the bone-ish light preview row.
- 60px never ships on modern iPhones (120/180 @2x/3x) — it's the right stress gate, not a target.
- Six chevrons (old) → three (new) is itself a brand correction: three is a rank; six was wallpaper.

## Questions to Consider

1. Earned alternate app icons per achieved rank (`setAlternateIconName`) — the most on-brand retention play imaginable for "you earn it"?
2. If the glow measures 2/255, who was it for — the icon, or the story about the icon?
