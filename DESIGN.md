---
name: DrillFit iOS App
description: Field Manual target spec — military field equipment, not a fitness app
colors:
  ink: "#1A1C1A"
  field: "#21241F"
  field-raised: "#2A2E26"
  bone: "#E8E4D8"
  muted-bone: "#CDC8BA"
  brass: "#C8A24B"
  brass-pressed: "#A38443"
  olive: "#6B7257"
  alert: "#C24A38"
  rank-pvt: "#A8A06A"
  rank-pfc: "#C9B97A"
  rank-spc: "#3FBF4A"
  rank-cpl: "#3B6FC4"
  rank-sgt: "#4A90D9"
  rank-ssg: "#A05FC9"
  rank-sfc: "#8E6FD0"
  rank-msg: "#D4882A"
  rank-1sg: "#E0A93A"
  rank-sma: "#D14B3A"
typography:
  display:
    fontFamily: "Oswald (condensed grotesque; bundle via pubspec)"
    fontSize: "28-34pt, Dynamic Type scaled"
    fontWeight: 700
    lineHeight: 1.05
    letterSpacing: "0.01em"
  headline:
    fontFamily: "Oswald (condensed grotesque; bundle via pubspec)"
    fontSize: "20-24pt, Dynamic Type scaled"
    fontWeight: 600
    letterSpacing: "0.02em"
  title:
    fontFamily: "Oswald (condensed grotesque; bundle via pubspec)"
    fontSize: "16-17pt, Dynamic Type scaled"
    fontWeight: 600
    letterSpacing: "0.02em"
  body:
    fontFamily: "Inter (humanist sans; bundle via pubspec)"
    fontSize: "15-17pt, Dynamic Type scaled"
    fontWeight: 400
    lineHeight: 1.45
  label:
    fontFamily: "JetBrains Mono (bundle via pubspec)"
    fontSize: "11-13pt, Dynamic Type scaled"
    fontWeight: 700
    letterSpacing: "0.12em"
rounded:
  sm: "4px"
  md: "8px"
  lg: "12px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "16px"
  lg: "24px"
  section: "32px"
components:
  button-primary:
    backgroundColor: "{colors.brass}"
    textColor: "{colors.ink}"
    rounded: "{rounded.sm}"
    padding: "14px 24px"
  button-primary-pressed:
    backgroundColor: "{colors.brass-pressed}"
  button-secondary:
    backgroundColor: "transparent"
    textColor: "{colors.bone}"
    rounded: "{rounded.sm}"
    padding: "14px 24px"
  card-surface:
    backgroundColor: "{colors.field}"
    rounded: "{rounded.md}"
    padding: "{spacing.md}"
  stat-readout:
    textColor: "{colors.bone}"
    typography: "{typography.label}"
---

# Design System: DrillFit iOS App

> **TARGET SPEC — not the current state.** The shipping app still wears an iOS-generic skin (system blue #0A84FF, Apple grouped surfaces, Poppins/League Spartan, Fitness-style rings). This document is the direction: new screens are built to it, reworked screens migrate to it. Where this spec and current code disagree, the spec wins. It also supersedes the old rule in `lib/features/ranks/domain/drill_sergeant.dart` that the persona lives "in MESSAGES only" — per PRODUCT.md, the drill sergeant now lives in the paint AND the copy.

## 1. Overview

**Creative North Star: "The Field Manual"**

DrillFit should look like military field equipment, not like a fitness app. The design language extends drillfit.com's Field Manual aesthetic into a daily-use tool: near-black ink and field surfaces, bone text, brass as the primary accent for actions and emphasis, olive for secondary structure, alert red used sparingly. Weights, streaks, and targets read like instrument panels — monospace readouts on dark equipment panels. Rank insignia are first-class UI citizens, color-coded per tier. Texture cues come from the manual — stamped labels, thin rules, mono eyebrows — used with restraint: this is regulation equipment, not cosplay.

Chrome is quiet; ceremonies are not. Day-to-day surfaces are disciplined and unadorned, but PROMOTED overlays, rank-ups, and streak milestones stay loud, theatrical, and always earned. And ergonomics outrank theme: logging a set mid-workout must stay fast, legible at arm's length, WCAG AA, and Dynamic-Type safe — when the Field Manual look and one-handed speed conflict, speed wins.

This system explicitly rejects (PRODUCT.md anti-references): Apple Fitness, generic Material trackers, pastel wellness apps, and Inter-and-purple-gradient AI slop. No system blue as brand color, no default Apple surfaces, no Fitness-ring lineage.

**Key Characteristics:**
- Ink/field dark equipment surfaces with bone text and one brass voice
- Monospace instrument readouts for every number the user trains against
- Condensed uppercase display type for headers, rank names, and commands
- Rank insignia as color-coded, first-class UI citizens
- Quiet chrome, loud earned ceremonies

## 2. Colors

The site's Field Manual palette, promoted to app chrome: a two-step dark ground, bone text, brass command accent, and a strict 10-color rank ramp.

### Primary
- **Brass** (#C8A24B): the default accent — primary buttons, active tab, selected states, emphasis, focus. On ink it reads as engraved hardware. Brass Pressed (#A38443) is the pressed/held state.

### Secondary
- **Olive** (#6B7257): secondary structure — inactive meta, dividers-with-presence, tertiary labels at large sizes. Never body text (it fails 4.5:1 on ink at reading sizes; use Muted Bone instead).
- **Alert Red** (#C24A38): sparing — destructive actions, missed-target callouts, the occasional stamp. Not an accent.

### Tertiary
- **Rank ramp** (rank-pvt #A8A06A → rank-sma #D14B3A): one color per enlisted tier, used on insignia, rank abbreviations, and promotion ceremonies. The ladder heats up as you climb — aged brass at Private, burning red at the apex (product decision, reskin batch #3). The palette is shared with drillfit.com's ladder but runs in the opposite order there; the site re-syncs to this direction as a follow-up.

### Neutral
- **Ink** (#1A1C1A): screen background.
- **Field** (#21241F): cards, panels, sheets — one tonal step up.
- **Field Raised** (#2A2E26): the rare second step — active input surfaces, pressed cards.
- **Bone** (#E8E4D8): primary text and icons. **Muted Bone** (#CDC8BA): secondary text that must still be read.
- Borders: bone at low alpha (rgba(232,228,216,0.08–0.16)), hairline weight.

### Named Rules
**The Accent Swap Rule.** Theme packs survive as accent swaps inside Field Manual chrome: ink/field surfaces, bone text, type, and insignia are constant; a pack replaces brass with its accent (emerald, crimson, ocean, …) and its pressed variant. Brass is the default issue. The coin/Airborne economy is untouched.
**The One Voice Rule.** Exactly one accent is live at a time (brass, or the equipped pack's accent). Rank colors belong to insignia and ceremonies; alert red belongs to consequences. No screen mixes accents.
**The Airborne Brass Rule.** The Airborne insignia mount (a subscriber's earned rank, brass-mounted) is always brass regardless of the equipped theme pack — an Accent Swap carve-out; never tint the mount to the pack accent. It renders only on the user's own current earned rank, never on locked/future rungs or beside a purchase affordance (rank stays earned, never bought).
**The Olive Floor Rule.** Olive never carries reading text. Secondary copy is Muted Bone (≥4.5:1 on ink); olive is for large labels and structure only.

## 3. Typography

**Display Font:** Oswald-class condensed grotesque (bundle via pubspec; Oswald preferred to match the site)
**Body Font:** Inter-class humanist sans (matches drillfit.com body)
**Label/Mono Font:** JetBrains Mono-class monospace

**Character:** The sergeant's bark (condensed uppercase display), the briefing (quiet humanist body), and the instrument panel (mono digits). All three roles scale with Dynamic Type — sizes in this spec are reference points at the default text size, not fixed values.

### Hierarchy
- **Display** (700, ~28–34pt, uppercase): screen titles, rank names on ceremony screens, PROMOTED overlays.
- **Headline** (600, ~20–24pt, uppercase): section headers, card group titles.
- **Title** (600, ~16–17pt, uppercase, +0.02em): card headings, exercise names, list row leads.
- **Body** (400, ~15–17pt, line-height 1.45): coach chat, descriptions, settings, notes. Sentence case, never uppercase.
- **Label / Readout** (JetBrains Mono 700, ~11–13pt, +0.12em, uppercase): weights, reps, streaks, targets, timers, rank abbreviations, eyebrows. Tabular figures; numbers align in columns.

### Named Rules
**The Instrument Panel Rule.** Every number the user trains against — weight, reps, streak, target, timer — sets in mono, sized to be read at arm's length mid-set. If a stat is glanceable, it's a readout; if it's a readout, it's mono.
**The Bark Budget Rule.** Uppercase display type is for commands, designations, and ceremonies. Body copy, coach chat, and anything conversational stays sentence-case Inter — the sergeant shouts headlines, not paragraphs.

## 4. Elevation

Flat, tonal, disciplined. Depth is the ink → field → field-raised ladder plus hairline bone-alpha borders; UI chrome casts no shadows. Ceremonies are the exception: promotion overlays and streak milestones may use glow (rank-color drop-shadows, brass bloom) as theatrical light — briefly, loudly, and only when earned. Modality (sheets, dialogs) is conveyed by a scrim over ink, not by shadow stacks.

### Named Rules
**The Quiet Chrome / Loud Ceremony Rule.** Resting surfaces are flat and shadowless. Glow and spectacle are reserved for earned moments — PROMOTED, rank-up, streak milestone — and end when the moment does.

## 5. Components

### Buttons
- **Shape:** sharp (4px)
- **Primary:** brass fill, ink text, condensed uppercase label, 14px 24px padding, ≥44pt touch target
- **Pressed:** brass-pressed fill with haptic; no scale bounce
- **Secondary:** transparent with hairline bone-alpha border; pressed tints field-raised
- **Destructive:** alert red fill or text per severity

### Cards / Containers
- **Corner Style:** 8px; 12px for sheets
- **Background:** field on ink; field-raised only for active/pressed surfaces
- **Shadow Strategy:** none (see Elevation)
- **Border:** 1px rgba(232,228,216,0.08–0.16)
- **Internal Padding:** 16px

### Inputs / Fields (set logging is the sacred flow)
- **Style:** field-raised fill, hairline border, mono text for numeric entry, big steppers — thumb-reachable, one-handed
- **Focus:** border shifts to the live accent; no glow
- **Error:** alert red border + plain-language message; never color alone

### Navigation
- Bottom tab bar on ink with hairline top border; active tab in the live accent with a condensed uppercase label, inactive in olive. Screen headers: Display uppercase title, optional mono eyebrow above (`DASHBOARD — 06:00`-style designations, used with restraint).

### Rank Insignia (signature component)
Chevron insignia drawn in the tier's rank color, rendered at every size from list-row 20pt to ceremony full-screen. Insignia are UI citizens: they appear on the dashboard, exercise rows, leaderboards, and profiles — always in their tier color, never recolored by theme packs.

### Stat Readout (signature component)
A labeled mono figure on a field panel: olive/mono eyebrow label (large size), bone mono value with tabular figures (`225 LB`, `×5`, `DAY 30`). Readouts compose into instrument rows on the dashboard and the active-workout screen.

### Ceremony Overlay (signature component)
Full-screen earned moment: ink scrim, oversized insignia in tier color with glow, Display uppercase headline ("PROMOTED — SERGEANT (E5)"), drill-sergeant line below in body type. Loud by design; skippable; fully honors reduced-motion (crossfade instead of choreography).

## 6. Do's and Don'ts

### Do:
- **Do** build new screens to this spec and migrate reworked screens toward it; the iOS-generic look is the outgoing state, not a second theme.
- **Do** set every trained-against number in mono at arm's-length sizes (The Instrument Panel Rule).
- **Do** keep logging a set fast, one-handed, and ≥44pt per target — ergonomics outrank theme every time they conflict.
- **Do** scale all type with Dynamic Type and ship a reduced-motion alternative (crossfade or instant) with every animation — both are hard requirements on new work.
- **Do** keep ceremonies loud and earned: rank-ups and streak milestones get spectacle; nothing else does.
- **Do** keep theme packs as accent swaps only — surfaces, type, and insignia never change with a pack (The Accent Swap Rule).

### Don't:
- **Don't** use Apple Fitness as a reference — no ring lineage, no vivid-accents-on-black system look (PRODUCT.md anti-reference, verbatim).
- **Don't** ship generic Material trackers, pastel wellness apps, or Inter-and-purple-gradient AI slop (PRODUCT.md anti-references, verbatim).
- **Don't** use system blue (#0A84FF) as a brand color or default Apple grouped surfaces as chrome.
- **Don't** show purchase affordances anywhere in rank progression UI — rank is sacred; Airborne never touches rank, coins, or streaks.
- **Don't** let olive carry body text, or any text fall below 4.5:1 on its surface.
- **Don't** play the military theme as cosplay — no camo textures, no gratuitous stamps on every panel. One stamp is a mark; five is a costume.
- **Don't** celebrate the unearned — no confetti for opening the app, no praise for incomplete work.
