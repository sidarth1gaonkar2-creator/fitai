---
name: Personal Records Hall
description: PR tracking with migration from workout history, sortable/filterable gallery, celebration notifications
type: project
---

## Isar Model (lib/models/personal_record.dart)

**PersonalRecord** — exerciseName, weightKg, bestReps, dateAchieved, muscleGroup

Schema registered in IsarService: PersonalRecordSchema

## Migration Service (lib/services/pr_migration_service.dart)

One-time migration run at app startup (in main.dart):
- Scans all existing Workout → WorkoutExercise → WorkoutSet records
- Extracts best lifts per exercise (heaviest weight)
- Creates PersonalRecord entries
- Runs only once (tracked via SharedPreferences flag)

## Providers (lib/providers/personal_records_hall_providers.dart)

- `allPersonalRecordsProvider` — All PRs from Isar
- `prSortModeProvider` — StateProvider: byDate, byMuscleGroup, alphabetical
- `prFilterMuscleProvider` — StateProvider<MuscleGroup?> for filtering
- `filteredPRsProvider` — Computed: applies sort + filter

## Screens (lib/features/progress/presentation/)

- **PRHallScreen** — Browsable gallery of all personal records
  - Sort options: by date, muscle group, alphabetical
  - Filter by muscle group
  - PR cards showing exercise name, weight, reps, date
- **PRCard** (widget) — Individual PR display
- **PRBanner** (widget) — Celebratory banner shown when new PR is set
- **PRConfettiOverlay** (widget) — Confetti animation on new PR

## Notifications
- `showPRNotification(exerciseName, weight)` in NotificationService
- Triggered when a new PR is detected during workout logging
