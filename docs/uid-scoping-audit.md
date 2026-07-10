# UID-Scoping Audit — Account-Scoping All Device-Local State

**Date:** 2026-07-10 · **HEAD:** `f51cc79` (v1.1.2, build 93) · **Status:** AUDIT ONLY — no code changed.
**Goal:** eliminate the same-device cross-account data-bleed class before RevenueCat/monetization (wallet integrity is a hard prerequisite).

---

## 1. Inventory of device-local per-user state

### 1a. Isar collections (23 total, one unnamed "default" instance, `isar_service.dart`)

| Collection | Contents | Classification |
|---|---|---|
| `UserProfile` | name/age/sex/weight/height/goal/TDEE — read via `where().anyId().findFirst()` (one global row) | **must-scope** |
| `Workout` / `WorkoutExercise` / `WorkoutSet` | full workout history | **must-scope** |
| `NutritionLog` / `Meal` / `FoodEntry` | full nutrition history | **must-scope** |
| `WeightEntry` | weight-over-time log | **must-scope** |
| `PersonalRecord` | strength PRs | **must-scope** |
| `CompletedDay` | any-activity streak days | **must-scope** |
| `SavedMeal` / `SavedMealItem` | saved meal templates | **must-scope** |
| `CustomMealPlan` / `CustomMealPlanMeal` / `CustomMealPlanFood` | AI/custom meal plans | **must-scope** |
| `Supplement` / `SupplementLog` | supplement checklist + log | **must-scope** |
| `SavedWorkoutTemplate` | workout templates (local-only v1) | **must-scope** |
| `OnboardingProgress` | partial onboarding draft (written post-auth) | **must-scope** |
| `UserRank` | military rank state (singleton via `where().findFirst()`) | **must-scope** |
| `UserThemeState` | **the coins wallet** + owned/equipped themes — global singleton `id = 1` | **must-scope** (monetization-critical) |
| `AIMessage` | AI-coach chat | **already scoped** — indexed `uid` field, every query `.uidEqualTo(uid)`, legacy purge flag `aiCoachUnscopedPurged` (June 2026 fix) |
| `CachedMenuItem` | restaurant-menu API cache, 7-day TTL | **global-ok** (app-wide cache) |

Verified: `UserProfile` is read ownerlessly at `onboarding_gate_provider.dart:47`; the `localOwner == null` **claim branch is at `onboarding_gate_provider.dart:56-63`** (claims the profile for whoever signs in next and, via lines 92-101, backfills their health data to that account's Firestore doc). `UserThemeState` singleton confirmed at `theme_providers.dart:59-63` (`getSync(1)`); awards flow `workouts_controller.dart:470 → :486-498 → UserThemeStateNotifier.awardCoins`.

### 1b. SharedPreferences keys — complete list with call sites

**MUST-SCOPE (per-uid):**

| Key | Call sites | Why |
|---|---|---|
| `gym_streak_current` | `gym_streak_provider.dart:26,30,36` | B inherits A's streak → wrong coin multiplier |
| `gym_streak_last_awarded_epoch_day` | `gym_streak_provider.dart:27,31,37-41` | same; also blocks B's award on A's award day |
| `training_schedule_configured` | `training_schedule_provider.dart:64,71,79,85` | B lands with streak mechanic pre-armed on A's schedule |
| `notif_workout_days` | `notification_providers.dart:123,153` (via `_load`/`_save`) | **dual role**: drives notifications AND is the streak schedule source of truth (PR4a). B editing days corrupts A's break detection |
| `last_celebrated_rank_index` | `workout_logging_screen.dart:286,288` | rank-up celebration fires wrongly / never for B |
| `saved_quick_adds_v1` | `saved_quick_add_providers.dart:16,36,71,81,89,95-97` | A's quick-add foods appear for B |
| `custom_exercise_groups_v1` | `custom_exercise_provider.dart:26,73` | A's custom exercises (and muscle mappings) appear for B |
| Remaining `notif_*` family (17 keys: workout/breakfast/lunch/dinner enabled+hour+minute, water, streak, pr, supplement, challenge, rest_days) | `notification_providers.dart:120-177` (single `_load`/`_save` pair) | per-user preferences; **cheap to scope wholesale** because reads/writes are centralized in one notifier |
| `drill_sergeant_enabled` / `drill_sergeant_intensity` / `drill_sergeant_full_metal` / `morning_motivation_enabled` / `morning_motivation_time` | `drill_sergeant_providers.dart:7-11,80-135` | per-user voice/notification prefs |

**ALREADY SCOPED:** `hidden_posts_$uid` (`community_providers.dart:123` — the existing per-uid key pattern to copy), `aiCoachUnscopedPurged` (one-time global purge flag, correct as global).

**GLOBAL-OK (device-level, deliberately survives sign-out):**

| Key | Call sites | Rationale |
|---|---|---|
| `theme_mode` | `settings_providers.dart:18-28` | light/dark is a device setting (equipped *theme* is per-user via UserThemeState) |
| `unit_system` | `unit_system_provider.dart:5-33` | device display preference (defensible either way; keep global v1) |
| `tutorial_completed` | `tutorial_providers.dart:8-44` | "has this device seen the tour" |
| `health_*` (11 keys) | `health_providers.dart:98-166` | HealthKit is inherently device-owner-level (Apple Health belongs to the phone's owner) |
| `notif_diag_ring_v1` | `notif_diag_log.dart:19-99` | device diagnostics ring buffer |
| `barcode_negative_cache` | `nutrition_providers.dart:183-212` | API cache |
| `exercisedb_v1_*` | `exercisedb_service.dart:40,167-196` | API cache |
| `pr_migration_done`, `weight_migration_done` | `main.dart:141-156` | one-time data-fix flags (see §3 note) |

**RETIRE:**

| Key | Call sites | Why |
|---|---|---|
| `localProfileOwnerUid` | `onboarding_gate_provider.dart:16,50,63,79`; `onboarding_controller.dart:156` | obsolete once storage itself is uid-scoped; **never cleared anywhere today** |
| `currency_coins`, `currency_log` | `currency_service.dart:13-14,32-70` | **dead code** — the only live use of `CurrencyService` is the static `coinsPerPR` constant (`workouts_controller.dart:491`); the prefs-backed wallet was superseded by `UserThemeState.coins` |

### 1c. File/cache state outside Isar+prefs

- `rank_card_preview.dart:91` — `getTemporaryDirectory()` for share-card PNGs: **global-ok** (ephemeral tmp).
- No other file caches (`path_provider` used only by `isar_service.dart` + the above).

### 1d. Current sign-out leak summary (verified against HEAD)

- Settings sign-out (`settings_screen.dart:814-817`): `isar.clear()` only — **destroys the signing-out user's own data** (incl. coins wallet!) yet **leaves every pref**: next account inherits A's gym streak, armed schedule, training days, quick-adds, custom exercises, rank-celebration index, drill-sergeant settings.
- Passive sign-out (token expiry/revocation → `authStateChanges` emits null → router redirect, `app_router.dart:67-78`): **nothing is cleared at all** — full Isar + prefs bleed to the next account.
- `localProfileOwnerUid` is never removed on any path except delete-account's blanket `prefs.clear()`.

---

## 2. Isar scoping design

### Option (a) — `ownerUid` field + indexed filtered queries

- Add `@Index() String ownerUid` to **21 models** → full `build_runner` regen (safe per the AIMessage precedent: only `isar_generator` runs — but 21 `.g.dart` files churn).
- Every read must add `.filter().ownerUidEqualTo(uid)`; every `put()` must stamp `ownerUid`.
- **Measured blast radius:** 201 non-generated `isar.<collection>` call sites; minus `aIMessages` (7, done) and `cachedMenuItems` (4, global) = **190 call sites across 24 files** must each be touched and each is an individual silent-leak bug if missed. Per-collection: workouts 25, nutritionLogs 25, userProfiles 17, personalRecords 14, supplements 11, workoutExercises 10, supplementLogs 10, foodEntrys 10, workoutSets 9, savedMeals 9, savedMealItems 9, completedDays 8, weightEntrys 6, meals 6, customMealPlans 6, userRanks 3, savedWorkoutTemplates 3, onboardingProgress 3, userThemeStates 2, customMealPlanMeals 2, customMealPlanFoods 2.
- Chronic tax: every future query must remember the filter. `where().anyId()` / `getSync(1)` singleton patterns (`UserProfile`, `UserThemeState`, `UserRank`) need redesign anyway (singleton-per-uid ≠ Isar id 1).

### Option (b) — per-uid Isar instance (named DB file per account) ✅ RECOMMENDED

Isar v3.1 (`pubspec.yaml:16`) supports named instances: `Isar.open(schemas, name: 'u_<uid>', directory: dir)` → `u_<uid>.isar` alongside today's `default.isar`.

- **Query sites that change: 0 of 201.** The `isarProvider` facade keeps its exact name and `Provider<Isar>` type; only what's behind it changes. Every one of the 190 leaky sites is fixed structurally — a leak becomes *impossible to write*, not merely "remembered against".
- **Codegen impact: none.** No model changes, no `.g.dart` regen — which matters given the known isar_generator/codegen fragility in this repo.
- Singleton patterns (`anyId().findFirst()`, `getSync(1)`) become **correct as-is**: one profile/wallet/rank row *per instance*.
- Sign-out no longer destroys data: A's DB file simply stops being the active instance → **restore-on-return works** (today `isar.clear()` permanently destroys A's coins/history — unacceptable once coins are purchasable).
- `AIMessage.uid` becomes redundant (harmless; drop in a later schema bump alongside the dormant `gems` field).
- Trade-offs, honestly: (1) `CachedMenuItem` cache gets duplicated per account — accepted, it's a 7-day-TTL convenience cache; (2) one `.isar` file per account ever signed in on the device — bounded, deleted on account-deletion; (3) instance lifecycle management is new machinery (below) — but it is ~6 files of infrastructure vs. 190 call-site edits.

**Files that change under (b)** (the complete list):

1. `lib/core/database/isar_service.dart` — `initialize({String? uid})` opens `u_<uid>` (or `anon` when signed out).
2. `lib/providers/isar_provider.dart` — becomes a thin facade over an instance-manager (`StateProvider<Isar>`-style holder the session coordinator updates); public shape `Provider<Isar>` unchanged.
3. `lib/main.dart` — bootstrap already resolves auth before `runApp` (`bootSignedInProvider`, `main.dart:190-196`): open the uid-correct instance at boot; run the legacy-DB move (§3) *before* first open; point the `pr/weight` migrations at the active instance.
4. `lib/app.dart` — session coordinator: `ref.listen(currentUserIdProvider, …)` (natural home — `app.dart:32` already hosts the launch `gymStreak.reconcile()` hook). Handles open-new → publish → close-old on every uid transition.
5. `lib/features/settings/presentation/settings_screen.dart` — sign-out drops `isar.clear()` (:815); delete-account replaces `prefs.clear()` (:878) with targeted teardown (§4).
6. **NEW** `lib/core/database/isar_uid_migration.dart` — the one-time `default.isar` → owner move (§3).
7. (PR-C) `lib/providers/onboarding_gate_provider.dart` — retire the claim branch; local profile in the uid's own instance is trivially trusted.

---

## 3. Migration plan for existing installed users (v1.1.x → v1.2)

**Hook location:** in the `main.dart` bootstrap, *after* `SharedPreferences` load and *before* the first `Isar.open` (must run while no instance holds the file). Guarded by a new flag `isar_uid_migration_done`; records `isar_uid_migration_owner` for diagnostics. Idempotent: flag is set only after verified success.

**Mechanism (preferred):** file move — close nothing (nothing is open yet), rename `default.isar` → `u_<owner>.isar` (delete any stale `.isar.lock`). Instant, total, no row-copy drift. *Verify on device that Isar v3 treats instance name ≡ file name (it does per Isar 3.1 file layout, but this is a hard gate for the implementation PR).* **Fallback:** open both instances, row-copy all 23 collections in per-collection `writeTxn`s, verify counts (esp. `UserThemeState.coins`), then delete `default.isar`. Source is never deleted before the copy is verified.

**Owner attribution rule** (the heart of not reproducing the claim bug):

> The legacy DB is assigned to `prefs.localProfileOwnerUid` if set; else to the **currently-signed-in uid at migration time** if signed in; else it is **parked, unclaimed — never assigned to a future sign-in.**

- **(a) Signed-in user with a local profile:** `localProfileOwnerUid` is almost always already set (the v1.1.x gate/onboarding set it on every signed-in launch — `onboarding_gate_provider.dart:63,79`, `onboarding_controller.dart:156`). Move `default.isar` → `u_<owner>.isar`. If owner ≠ current uid (shared device, other user's parked data): move to the *recorded owner's* name — the current user starts fresh, correctly. If `localOwner == null` (upgraded straight from a pre-owner-key build): claim for the **currently signed-in** uid. This is *not* the claim-for-next-user bug: the data was this user's live working set at upgrade time, and the v1.1.x gate would have claimed it for this same uid on this same launch anyway. Post-migration, unowned data can never exist again.
- **(b) Signed-out with leftover rows:** if `localOwnerUid` is set (the common case — passive sign-outs never cleared prefs), move to that owner; they get their data back on next sign-in. If genuinely unowned (rare: pre-owner-key build → signed out → upgrade), **park `default.isar` untouched and never claim it** — the next signer-in starts fresh. Documented data-orphaning in an edge case, traded deliberately against cross-account bleed.
- **(c) Fresh install:** no `default.isar`; nothing to migrate. Sign-in opens an empty `u_<uid>.isar`; set the migration flag immediately.

**`pr_migration_done` / `weight_migration_done`:** stay global. Existing users' data was already fixed in the default instance and moves fixed; fresh per-uid instances are born empty and contain nothing to fix.

**Prefs migration (PR-B):** same owner rule. For each must-scope key present globally: copy value → `<key>_<owner>`, then delete the global key; guarded by `prefs_uid_migration_done`. Copy-then-delete + flag-set-last = idempotent under mid-migration kill.

---

## 4. Sign-out centralization

**Every sign-out path today:**

| # | Path | Local clearing today |
|---|---|---|
| 1 | Settings → `_confirmSignOut` (`settings_screen.dart:784-820`) | `isar.clear()` only; prefs untouched |
| 2 | Settings → `_confirmDeleteAccount` (`settings_screen.dart:828-898`) | `isar.clear()` + `prefs.clear()` (nukes device settings too) |
| 3 | Passive: token expiry/revocation → `authStateChanges` null → router redirect (`app_router.dart:67-78`) | **nothing** |
| 4 | Raw `AuthService.signOut()` (`auth_service.dart:173-176`) | nothing by design (service is storage-agnostic) |

**Proposed choke point:** a single **session coordinator** listening to `currentUserIdProvider` at app root (`app.dart`, beside the existing launch reconcile hook). Because it reacts to the *auth state itself*, all four paths — including passive revocation, today's total-leak path — converge through it with no per-call-site discipline needed. On uid transition it: swaps the active Isar instance (open new → publish → close old), lets uid-keyed providers rebuild naturally, re-runs `notificationSettingsProvider.syncSchedules()` for the incoming user, and runs `gymStreak.reconcile()`.

- **UI sign-out** reduces to `authService.signOut()` (+ dialog copy change — data is now *preserved for your account*, not cleared).
- **What gets cleared on sign-out: nothing is destroyed.** Per-account state is isolated by construction; in-memory session state resets via provider rebuilds.
- **What deliberately survives (device-level):** `theme_mode`, `unit_system`, `tutorial_completed`, `health_*`, `notif_diag_ring_v1`, API caches (`exercisedb_v1_*`, `barcode_negative_cache`, `CachedMenuItem`), migration flags.
- **Delete-account** keeps an explicit extra step at its call site (it is destruction, not sign-out): close + delete `u_<uid>.isar`, remove all `*_<uid>` pref keys — and **stop using `prefs.clear()`**, which today wrongly wipes device settings and diagnostic state.

---

## 5. Streak/prefs uid-scoped key scheme

**Scheme:** suffix pattern already proven in this codebase — `hidden_posts_$uid` (`community_providers.dart:123`). Adopt uniformly: `<base>_<uid>`; a shared helper `String scopedKey(String base, String uid)` in one place.

| Base key | New key | Read/write sites that change |
|---|---|---|
| `gym_streak_current` | `gym_streak_current_<uid>` | `GymStreakNotifier._load` / `_persist` (`gym_streak_provider.dart:26-41`); notifier gains uid via `ref.watch(currentUserIdProvider)` in its provider (`:95-98`) → auto-rebuild on account switch (exact AIMessage pattern) |
| `gym_streak_last_awarded_epoch_day` | `…_<uid>` | same two methods |
| `training_schedule_configured` | `…_<uid>` | `TrainingScheduleConfiguredNotifier` ctor/`markConfigured`/`reset` (`training_schedule_provider.dart:71-87`); provider watches uid (`:90-94`) |
| `notif_workout_days` + whole `notif_*` family | `…_<uid>` | **one** `_load`/`_save` pair (`notification_providers.dart:120-178`) + provider watches uid; `syncSchedules` re-runs via the session coordinator on switch |
| `last_celebrated_rank_index` | `…_<uid>` | `workout_logging_screen.dart:286,288` (2 lines; uid available from `currentUserIdProvider`) |
| `saved_quick_adds_v1` | `…_<uid>` | `saved_quick_add_providers.dart` — 7 call sites, all in one file |
| `custom_exercise_groups_v1` | `…_<uid>` | `custom_exercise_provider.dart:26,73` + provider watches uid |
| `drill_sergeant_*`, `morning_motivation_*` | `…_<uid>` | `drill_sergeant_providers.dart` single load + 5 setters |

Signed-out reads (uid == null): providers return defaults / stay dormant (streak mechanic already no-ops when unconfigured). No `anon`-suffixed keys — nothing user-scoped should persist from a signed-out session.

---

## 6. Risk list & test plan

**Risks (ranked):**

1. **Coins corruption** (monetization-blocking): `UserThemeState` row must survive the DB move exactly once. Mitigations: file-move (atomic at FS level) preferred; row-copy fallback verifies `coins` value + row counts before deleting source; migration flag set last; never claim-then-overwrite.
2. **Isar name↔file assumption**: rename semantics must be device-verified before shipping; row-copy fallback exists. Hard gate in the implementation PR.
3. **Use-after-close on instance swap**: a provider holding the old `Isar` (esp. active `watch*` streams) after close → crash. Mitigations: swap only during auth transitions (router is off the shell, watchers are being torn down); publish new instance before closing old; verify all watchers reach Isar via `isarProvider` (audit says yes — all 201 sites do); worst-case: defer `close()` to next transition (bounded handle leak) — decide in implementation.
4. **Wrong-owner claim on shared device** (migration edge): bounded by the §3 rule (recorded owner wins; claim only for *currently-signed-in* user; never for a future user). Residual risk equals the bug the v1.1.x gate already has, for one launch, then vanishes forever.
5. **Streak legitimacy vs. restore**: A returns after days away → `reconcile()` may *legitimately* reset the streak (missed scheduled days). Not a bug — but the test plan must not misread it as data loss.
6. **Privacy expectation change**: sign-out no longer wipes the device ("Local data will be cleared" dialog copy is now false). Update copy; consider a separate "Remove my data from this device" action as a follow-up ticket.
7. **Mid-migration kill**: both migrations are copy-then-delete, flag-set-last, idempotent on re-run.
8. **Passive sign-out mid-workout**: logging controller reads `isarProvider` per call — writes after swap land in `anon`. Acceptable (session is over), but device-test it doesn't crash.

**Device test plan (in order):**

1. **Upgrade, signed-in:** install build 93 → sign in A → log workout + nutrition + earn coins + set training days + build streak → record exact coins/streak/PR values → install new build → verify identical values; `u_A.isar` exists, `default.isar` gone.
2. **Isolation:** sign out A → sign in B → verify: onboarding gate fires (no profile), zero workouts/nutrition/coins/streak, no training days configured, no quick-adds/custom exercises, no rank state. B completes onboarding, logs data, earns coins.
3. **Restore:** sign out B → sign in A → A's profile, history, PRs, coins, training days all restored (streak per risk #5 — verify same-day).
4. **Cross-check:** back to B → B's data intact and none of A's.
5. **Delete-account:** delete B → `u_B.isar` gone, B's `*_<uid>` prefs gone, device settings (theme/units/tutorial) intact, A completely unaffected on next sign-in.
6. **Passive revocation** (the currently-fully-leaky path): while A signed in with data, revoke refresh tokens in Firebase console → app lands on /welcome → sign in B → isolation verified.
7. **Fresh install** → sign-in → onboarding → data lands in `u_<uid>` from the first write.
8. **Regression:** `flutter test --no-test-assets` — only the 14 pre-existing onboarding baseline failures allowed; `flutter analyze` clean.

---

## 7. PR split proposal

| PR | Content | Why this boundary |
|---|---|---|
| **PR-A — Isar instance scoping + migration** | Per-uid instance manager behind unchanged `isarProvider`; `default.isar` → owner move with §3 attribution rule; session coordinator in `app.dart`; sign-out drops `isar.clear()`; delete-account targeted teardown; dialog copy | The schema/storage foundation — highest risk, most testing, zero query-site churn. Independently shippable and independently verifiable with tests 1-7 |
| **PR-B — SharedPreferences scoping** | `scopedKey` helper; scope the §5 table (streak, schedule-configured, notif family, drill-sergeant, rank-celebration, quick-adds, custom exercises); prefs migration keyed to the same owner rule; notifiers rebuild on uid | Mechanically simple but reuses PR-A's attribution rule and session coordinator — must land after A |
| **PR-C — Cleanup** | Retire `onboarding_gate_provider` claim branch + `localProfileOwnerUid`; delete dormant `CurrencyService` prefs wallet (`currency_coins`/`currency_log`, keep `coinsPerPR`); note `AIMessage.uid` + `gems` for the next schema bump; docs | Only safe once A+B are verified in the field — the claim branch is the live safety net until then |

**Order: A → B → C**, each with the device-test pass. A and B could ship in one release; C waits one release for field confirmation.

---

*Sources: all claims verified against HEAD `f51cc79` on 2026-07-10 — file:line references are to that commit. Background context cross-checked and corrected against the June 2026 audit (AIMessage fix, dormant gems, PR4a/4b streak design).*
