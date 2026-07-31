# Restaurant micronutrients — sourcing playbook

The standing method for attaching micronutrients to `lib/data/restaurant_menus.dart`.
It supersedes the Wave 2 Batch 1/2 briefs, whose rule 5 mandated a kcal anchor
that has since been retired. Anything in an older brief that contradicts this
file is wrong.

Prior art: `report_mcdonalds_micros.txt` (pilot), `report_micros_batch1.txt`,
`report_micros_batch2.txt`, `report_micros_tier2_anchor.txt` (the anchor audit),
`report_micros_anchor_fix.txt` (the correction pass).

## Non-negotiable rules

1. **Every value fetched live. Nothing from model memory.** If a value cannot be
   fetched, leave it null and record why. Null > guess, always. Never write `0`
   for "unknown" — `0` is only for a nutrient the source explicitly publishes
   as zero.

2. **Field discipline.** The UI "est." marker hard-codes this split.
   - **Tier 1** — `fiber`, `sodium`, `vitaminDMcg`, `calciumMg`, `ironMg`,
     `potassiumMg`: ONLY from the chain's own published data. Never USDA. If the
     chain doesn't publish it, it stays null.
   - **Tier 2** — `vitaminCMg`, `magnesiumMg`, `zincMg`, `vitaminB12Mcg`,
     `folateMcg`: from USDA FoodData Central, `estimated = y`.
   - A chain that publishes a Tier 2 field itself (Taco Bell publishes the full
     FDA panel; Chipotle and Subway publish vitamin C) makes that value **Tier 1
     chain-published**. It is not a derived value, it is not in scope for any
     re-derivation, and it must not be recomputed. Tag it `Tier1-<Chain>`.

3. **Macros are not touched.** Micro passes only add or correct micro fields.

4. **Store published panel values, not label-engine internals.** If a chain's
   calculator exposes higher-precision pre-rounding numbers, store what the
   chain publishes on the panel.

5. **%DV → absolute** (only when the chain gives %DV without absolutes): FDA DVs
   vitD 20 mcg, calcium 1300 mg, iron 18 mg, potassium 4700 mg. State the basis
   assumed; if genuinely ambiguous and material, prefer null.

## Tier 2 basis hierarchy — BINDING

A Tier 2 value is USDA-per-100 g scaled by a **serving mass**. That mass comes
from exactly one of the following, in order. Record which one in the citation.

### 1. Chain-published serving weight — preferred

The chain's own per-item mass (grams or ounces), or a sum of the chain's own
published component weights. Published cup **volume** qualifies for a fluid
whose mass is the liquid itself.

Do not use a published weight that is not a serving mass:
- **ice-inclusive cup volume** (Chick-fil-A publishes lemonade/iced tea as full
  cup mass with no deduction for ice),
- **a fluid-ounce figure sitting in a grams column** (Burger King's drinks
  section — and several cells there are outright corrupt: Medium Unsweetened
  Iced Tea reads `3.036`),
- **foamed-milk drinks**, where liquid volume overstates milk mass.

Cross-validate every name match on published calories, tolerance
`max(6 kcal, 6%)`. A match that fails the calorie check is **rejected**, not
trusted — this is what catches a component being matched to a whole-sandwich row.

### 2. Solved-mineral anchor

Solve the mass from a nutrient the chain publishes, against the USDA reference's
per-100 g figure:

```
grams = chain-published nutrient / USDA nutrient-per-100g x 100
```

Accept only when **both** hold:
- two published minerals (**sodium** and **potassium**) solve independently and
  agree within **15%**, and
- an **independent calorie cross-check** agrees within **15%**.

Calories take no part in deriving the mass — they only test it. Agreement on a
nutrient that was not used in the solve is the evidence that the USDA reference
really is the same food. This is why it is not a kcal anchor.

**Calcium and iron are not solvers.** The app stores them converted from the
chain's rounded %DV and USDA's fortification for the same item differs, so they
scatter — McDonald's Hamburger solves to 12 g on calcium against ~100 g on
everything else.

Single-ingredient items are where this shines: Dunkin's Original Blend solves to
422.4 g from their published 207 mg potassium and cross-checks to 2% against
their own 14 fl oz cup.

### 3. Protein-matched scaling — meat-derived micros ONLY

```
grams = chain-published protein / USDA protein-per-100g x 100
```

Applies to **`zincMg` and `vitaminB12Mcg` only**, and only where those micros
genuinely travel with animal protein. Two triggers:
- no mass basis exists from 1 or 2, or
- basis 1's mass **overstates the meat fraction** — predicted protein
  (`grams/100 x USDA protein-per-100g`) runs more than 10% above what the chain
  publishes. Then basis 1 stands for the other three fields and basis 3 replaces
  it for zinc and B-12.

Eligibility: the reference must be animal-protein-bearing — protein ≥ 7 g/100 g
plus an animal signal in the reference description, the menu item name, or
B-12 ≥ 0.2 mcg/100 g. Fluid dairy is admitted below the density cut, since its
zinc and B-12 track its mass exactly.

This is **not** a general mass solve. A doughnut's zinc travels with flour, a
bagel's with enriched grain, a portion of fries' with potato — none are
meat-derived, and all fall to null instead.

### 4. Null

### The kcal anchor is retired

Never a basis, at any tier, for any field. Deriving serving grams from calories
misreads the energy of added fat and oil as more reference food. It produced 45
rows asserting more mass than the serving physically contains (Panda Eggplant
Tofu at 2.1x the food present, Chipotle Sofritas 180.7 g of tofu in a 113.4 g
serving) and it fails in the opposite direction on lean items, silently
understating them.

## Mass-sanity check — hard gate

**Any derived serving-gram figure that exceeds the chain's published serving
weight for that item is a defect, not a value.** Null it. Never ship it, never
round it into range.

Run file-wide before every commit. Required result: **zero violations**.

Two implementation notes that matter:
- Untrustworthy published weights cannot anchor a portion and cannot condemn one
  either. Exclude them from both roles explicitly, or the check inverts and
  condemns a correct value against a corrupt one.
- Values are stored to one decimal. Inverting a stored value back to grams
  amplifies that rounding, so test whether the stored value is **reachable**
  from the published mass (`value <= published/100 x per100g + 0.05`), not
  whether the inverted mass lands exactly on it. Subway Tomatoes zinc is truly
  0.0595 mg, stores as `0.1`, and naively inverts to 58.8 g against a 35 g
  portion.

## Other standing rules

- **Folate** is USDA "Folate, total" (µg), never DFE. This understates folate
  for fortified/enriched items — a known, accepted caveat.
- **Round to 1 decimal**; keep integers where whole (no `X.0` literals).
- **Calorie drift table** for every matched item: app kcal vs current published
  kcal, with the current item name. If composition materially changed, leave all
  micros null and flag it.
- **Cross-chain byte-identical literals are a live hazard.** Several chains ship
  components with identical names — American, Provolone, Lettuce, Water. Batch 1
  filed Subway's four cheese rows under Taco Bell because a heading-based scan
  attributed them by position. Attribute by the in-band `Tier1-<Chain>` source
  tag, and confirm against the enclosing category in the Dart file.
- **Subway footlongs are exactly 2x the 6-inch row**, per Subway's own guide.

## Verification before commit

Per chain, atomically (macros and micros for a literal move together):

```bash
flutter analyze          # 27 issues is the current baseline
flutter test             # 14 onboarding widget failures are the known baseline
grep -c "MenuItem(" lib/data/restaurant_menus.dart    # 1299
```

Plus, over the whole file:
- **mass-sanity check** — zero violations;
- **positional field diff** old vs new — every non-Tier-2 field byte-identical,
  parsed item count unchanged. Reflow is acceptable; a changed non-Tier-2 value
  is not.
