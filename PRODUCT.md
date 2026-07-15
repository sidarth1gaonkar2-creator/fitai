# Product

## Register

product

## Platform

ios

## Users

Committed lifters — people already training several times a week who want measurable progression, competition, and a tough-love push. The primary context is mid-workout at the gym: phone in one hand, resting between sets, logging fast and glancing at targets from arm's length. Secondary contexts are the couch (reviewing progress, chatting with the AI coach, browsing the community) and the kitchen (logging food). Sign-in is required; these are invested users, not drive-by trackers.

## Product Purpose

DrillFit is a strength and nutrition tracker that ranks lifters the way the military ranks soldiers: ten enlisted ranks from Private to Sergeant Major of the Army, earned by crossing real, bodyweight-adjusted strength standards. Every logged set is scored; crossing a threshold is a promotion. Around that core sit an AI coach with a drill-sergeant edge, nutrition and supplement tracking, streaks, a community feed with challenges and leaderboards, and an earned-coin theme store. The paid tier, Airborne, unlocks 100 AI-coach messages a day and the standard theme packs — and deliberately nothing else. Success right now is App Store downloads: the app's job is a great first session that proves the rank mechanic immediately, with retention carried by streaks, promotions, and the coach.

## Positioning

Most fitness apps just track. DrillFit makes you earn it.

## Brand Personality

Commanding, relentless, occasionally hilarious — a drill sergeant, not a cheerleader. The voice praises only completed work ("SOLID WORK, SOLDIER"), calls out weak points by name, and never begs. The drill sergeant lives in the paint AND the copy: the visual language itself reads as military field equipment, and the words snap to match. Chrome is quiet; ceremonies are not — promotions, rank-ups, and streak milestones stay loud and earned.

## Anti-references

- Apple Fitness: the rings, the vivid-accents-on-black lineage, the system-blue default the app currently wears.
- Generic Material trackers.
- Pastel wellness apps.
- Inter-and-purple-gradient AI slop.
- Generic SaaS fitness: purple gradients, rounded pastel cards, stock smiling joggers.
- Sterile data tracker: MyFitnessPal-style utilitarian gray — all spreadsheet, no personality.

## Design Principles

- **The sergeant lives in the paint and the copy.** The Field Manual aesthetic (see DESIGN.md) is the app's visual identity, not a skin on top of default iOS. This supersedes the older code rule that the persona lives in messages only.
- **Chrome is quiet, ceremonies are not.** Day-to-day surfaces are disciplined and unadorned; PROMOTED overlays, rank-ups, and streak milestones are loud, theatrical, and always earned.
- **Data-entry ergonomics beat theme.** Logging a set mid-workout must stay fast, one-handed, and legible at arm's length. When theme and ergonomics conflict, ergonomics wins.
- **Rank is sacred.** Rank progression UI never shows purchase affordances. Airborne never touches rank, coins, or streaks — you lift your way up, full stop.
- **Numbers you can trust.** Bodyweight-adjusted scoring against real standards, presented honestly. Stats read like instrument panels, not decorations.

## Accessibility & Inclusion

WCAG AA. Dynamic Type support and reduced-motion alternatives are requirements for all new and reworked UI — both are currently absent from the codebase (fixed point sizes, no `disableAnimations` handling) and are known gaps to close during the Field Manual migration. Body text must hold 4.5:1 contrast; the olive secondary tone is reserved for large or non-essential text only.
