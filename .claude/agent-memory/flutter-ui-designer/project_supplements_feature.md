---
name: Supplements Feature
description: Supplement tracking with daily checklist, 30-day consistency, hardcoded library + API catalog, Isar persistence
type: project
---

## Overview
Users manage a personal supplement stack, check off daily intake from the dashboard, and track 30-day adherence.

## Isar Models (lib/models/)

**Supplement** — name, dosage (String), unit (String), timing (SupplementTiming enum), isActive (bool)
**SupplementLog** — supplementId (indexed), date (indexed), timeTaken (DateTime?), taken (bool)

Relationship: Many SupplementLogs → One Supplement via supplementId

## Enum (lib/models/enums.dart)

SupplementTiming: morning, afternoon, evening, withMeal, beforeBed
Extension: `.label` returns display string ("With Meal", "Before Bed", etc.)

## Supplement Library (lib/data/supplement_library.dart)

Hardcoded catalog of 20+ supplements (SupplementDefinition class):
Creatine, Whey Protein, Vitamin D3, Fish Oil, Magnesium, Zinc, Vitamin C, Multivitamin, Caffeine, Melatonin, Ashwagandha, Collagen, BCAA, Citrulline Malate, Pre-Workout, Glutamine, Probiotics, Beta-Alanine, Iron, Electrolytes

Each has: name, dosage, unit, timing, category, benefits[], sideEffects[], foodSources[]

## API Service (lib/services/supplement_api_service.dart)

- Base URL: https://vitamins-and-supplements.vercel.app
- Endpoints: /api/supplement/, /api/vitamin/
- Requires SUPPLEMENT_API_TOKEN from .env
- In-memory cache with 30-minute TTL
- Parallel fetch of supplements + vitamins, sorted by rating
- ApiSupplement class: name, rating, recommendation, tags, benefits, whoShouldUse, dose, timing, suggestions, url, isVitamin

## Providers (lib/providers/supplement_providers.dart)

- `supplementCatalogProvider` — Hardcoded library + API merged, de-duplicated, Turkish content filtered
- `allSupplementsProvider` — All supplements from Isar
- `activeSupplementsProvider` — Only isActive==true
- `todaySupplementLogsProvider` — Today's logs (date range filter)
- `supplementChecklistProvider` — Joins active supplements + today's logs → List<SupplementChecklistItem>
- `supplementConsistencyProvider(supplementId)` — 30-day adherence % (0.0–1.0)

Functions: toggleSupplementTaken(), addSupplement(), deactivateSupplement(), reactivateSupplement(), deleteSupplement()

## Screens (lib/features/supplements/presentation/)

**SupplementsScreen** — Full management: active/inactive sections, 30-day consistency per supplement, add/pause/delete actions, shimmer loading, empty state with CTA

**AddSupplementSheet** (widget) — Modal with 2 modes:
- Library mode: browse catalog (hardcoded + API), rating badges, detail sheet on tap
- Custom mode: form (name, dose, unit, timing via CupertinoSlidingSegmentedControl)

**SupplementChecklistCard** (widget) — Dashboard card showing today's checklist with animated checkboxes, strike-through on taken, count display (taken/total)

**SupplementConsistencyCard** (widget) — 30-day adherence bar, color-coded (green ≥80%, yellow ≥50%, red <50%)

## Route

`/supplements` — SupplementsScreen (slideUpTransitionPage, accessed from dashboard)
