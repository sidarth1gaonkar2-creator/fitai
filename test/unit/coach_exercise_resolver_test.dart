import 'package:flutter_test/flutter_test.dart';

import 'package:fitai/data/exercise_library.dart';
import 'package:fitai/features/ai_coach/domain/coach_exercise_resolver.dart';
import 'package:fitai/features/ranks/domain/exercise_standards.dart';
import 'package:fitai/models/enums.dart';

void main() {
  group('snapToLibrary', () {
    test('exact and case-insensitive name match', () {
      expect(snapToLibrary('Barbell Bench Press')?.id, 'barbell_bench_press');
      expect(snapToLibrary('barbell bench press')?.id, 'barbell_bench_press');
    });

    test('tight fuzzy snaps an extra-word variant', () {
      // "Tricep Rope Pushdown" → "Tricep Pushdown" (library tokens ⊆ proposal).
      expect(snapToLibrary('Tricep Rope Pushdown')?.id, 'tricep_pushdown');
    });

    test('does NOT force a wrong/ambiguous match', () {
      // Abbreviations whose tokens don't all appear in a library name must not
      // snap — a wrong snap is worse than leaving it custom.
      expect(snapToLibrary('Incline DB Bench'), isNull);
      expect(snapToLibrary('DB Shoulder Press'), isNull);
      expect(snapToLibrary('Some Totally Invented Move'), isNull);
    });
  });

  group('resolveProposedExercise — three tiers', () {
    test('Tier 1: library match snaps to the canonical name', () {
      final r = resolveProposedExercise('Tricep Rope Pushdown');
      expect(r.tier, 1);
      expect(r.name, 'Tricep Pushdown');
    });

    test('Tier 2: off-library + declared muscle → custom under that group', () {
      final r = resolveProposedExercise('Cable Y-Raise',
          notes: '[shoulders] light burnout');
      expect(r.tier, 2);
      expect(r.group, RankGroup.shoulders);
      expect(r.name, 'Cable Y-Raise'); // kept as a custom
      expect(r.notes, 'light burnout'); // tag stripped
    });

    test('Tier 2: muscle-tag aliases roll up correctly', () {
      expect(resolveProposedExercise('X', notes: '[front delt]').group,
          RankGroup.shoulders);
      expect(resolveProposedExercise('Y', notes: '[tris]').group,
          RankGroup.arms);
      expect(resolveProposedExercise('Z', notes: '[lower back]').group,
          RankGroup.back);
    });

    test('Tier 3: off-library + no valid muscle → unresolved (never Chest)', () {
      final r = resolveProposedExercise('Mystery Machine Thing');
      expect(r.tier, 3);
      expect(r.group, isNull);
      // A cardio tag is not rankable → still Tier 3, not a bogus group.
      expect(resolveProposedExercise('Sprint Drill', notes: '[cardio]').tier, 3);
    });
  });

  group('catalogue is fine-muscle precise', () {
    test('separates Triceps from Biceps (the push≠biceps guarantee)', () {
      expect(coachExerciseCatalogue, contains('Triceps:'));
      expect(coachExerciseCatalogue, contains('Biceps:'));
      // The Triceps line lists tricep work, never a curl.
      final triLine = coachExerciseCatalogue
          .split('\n')
          .firstWhere((l) => l.startsWith('Triceps:'));
      expect(triLine, contains('Tricep Pushdown'));
      expect(triLine.toLowerCase(), isNot(contains('curl')));
    });

    test('excludes cardio and covers the library', () {
      expect(coachExerciseCatalogue.toLowerCase(), isNot(contains('treadmill')));
      // Every rankable (non-cardio) library exercise appears by name.
      final rankable = exerciseLibrary.where((e) =>
          e.primaryMuscles.isNotEmpty &&
          e.primaryMuscles.first != MuscleGroup.cardio);
      for (final e in rankable) {
        expect(coachExerciseCatalogue, contains(e.name),
            reason: '${e.name} missing from catalogue');
      }
    });
  });

  group('concrete push-day trace (item 5)', () {
    // Resolve a push day and confirm each lands under Arms / Shoulders / Chest
    // — NOT all Chest.
    RankGroup groupOf(ResolvedExercise r) {
      if (r.tier == 2) return r.group!;
      // Tier 1: group derived from the snapped library exercise.
      final def = snapToLibrary(r.name)!;
      return rankGroupForMuscle(def.primaryMuscles.first)!;
    }

    test('triceps/shoulders/chest resolve to distinct correct groups', () {
      expect(groupOf(resolveProposedExercise('Tricep Rope Pushdown')),
          RankGroup.arms);
      expect(groupOf(resolveProposedExercise('Seated Dumbbell Shoulder Press')),
          RankGroup.shoulders);
      expect(groupOf(resolveProposedExercise('Incline Barbell Bench Press')),
          RankGroup.chest);
      // Off-catalogue abbreviation with a declared muscle still avoids Chest.
      expect(
          resolveProposedExercise('DB Shoulder Press', notes: '[shoulders]')
              .group,
          RankGroup.shoulders);
    });
  });
}
