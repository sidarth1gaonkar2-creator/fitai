import '../../../data/exercise_library.dart';
import '../../../models/enums.dart';
import '../../ranks/domain/exercise_standards.dart';

/// Grounds AI-proposed exercises in the fine-muscle-tagged library so a "push
/// day" reliably trains chest/shoulders/triceps (not biceps) and every logged
/// exercise rolls up to the RIGHT muscle group instead of silently defaulting
/// to Chest.
///
/// Two pieces:
///  * [coachExerciseCatalogue] — a compact, fine-muscle-grouped list of every
///    library exercise, injected into the AI system prompt so the model can
///    pick by muscle and use canonical names.
///  * [resolveProposedExercise] — the apply-time three-tier resolver:
///      T1 confident library match → snap to the canonical exercise (muscle
///         known from the library),
///      T2 no match but a valid declared muscle (in `notes`) → custom under
///         that muscle's group,
///      T3 neither → unresolved (caller leaves it unranked; never Chest).

// ─── Fine-muscle display labels (for the catalogue + tag parsing) ────────────
const Map<MuscleGroup, String> _muscleLabel = {
  MuscleGroup.chest: 'Chest',
  MuscleGroup.upperBack: 'Upper Back',
  MuscleGroup.lats: 'Lats',
  MuscleGroup.lowerBack: 'Lower Back',
  MuscleGroup.shoulders: 'Shoulders',
  MuscleGroup.biceps: 'Biceps',
  MuscleGroup.triceps: 'Triceps',
  MuscleGroup.forearms: 'Forearms',
  MuscleGroup.quads: 'Quads',
  MuscleGroup.hamstrings: 'Hamstrings',
  MuscleGroup.glutes: 'Glutes',
  MuscleGroup.calves: 'Calves',
  MuscleGroup.abs: 'Abs',
  MuscleGroup.obliques: 'Obliques',
};

/// Order the catalogue by rank group so push/pull/legs muscles sit together.
const List<MuscleGroup> _catalogueOrder = [
  MuscleGroup.chest,
  MuscleGroup.shoulders,
  MuscleGroup.triceps,
  MuscleGroup.upperBack,
  MuscleGroup.lats,
  MuscleGroup.lowerBack,
  MuscleGroup.biceps,
  MuscleGroup.forearms,
  MuscleGroup.quads,
  MuscleGroup.hamstrings,
  MuscleGroup.glutes,
  MuscleGroup.calves,
  MuscleGroup.abs,
  MuscleGroup.obliques,
];

/// The fine-muscle-grouped exercise catalogue, built once from
/// [exerciseLibrary]. Each rankable exercise is bucketed by its FIRST primary
/// muscle so the model sees, e.g., the full Triceps list distinct from Biceps.
final String coachExerciseCatalogue = _buildCatalogue();

String _buildCatalogue() {
  final byMuscle = <MuscleGroup, List<String>>{};
  for (final ex in exerciseLibrary) {
    if (ex.primaryMuscles.isEmpty) continue;
    final primary = ex.primaryMuscles.first;
    if (primary == MuscleGroup.cardio) continue; // not rankable
    byMuscle.putIfAbsent(primary, () => []).add(ex.name);
  }
  final lines = <String>['EXERCISE LIBRARY (use these EXACT names):'];
  for (final muscle in _catalogueOrder) {
    final names = byMuscle[muscle];
    if (names == null || names.isEmpty) continue;
    lines.add('${_muscleLabel[muscle]}: ${names.join(', ')}');
  }
  return lines.join('\n');
}

/// System-prompt guidance telling the model to select by muscle, use exact
/// catalogue names, and (only when going off-catalogue) declare the muscle.
const String coachWorkoutSelectionGuidance =
    'EXERCISE SELECTION: Build each workout from the muscles it should train '
    '(push = chest + shoulders + triceps; pull = back + biceps; legs = quads + '
    'hamstrings + glutes + calves; never put a pull muscle like biceps in a '
    'push day). Choose exercises from the EXERCISE LIBRARY below and use their '
    'EXACT exerciseName. Only if no library exercise fits, you may propose one '
    'not listed — and then you MUST begin its `notes` with the target muscle in '
    'square brackets, one of: chest, shoulders, triceps, biceps, lats, upper '
    'back, lower back, quads, hamstrings, glutes, calves, abs, obliques, '
    'forearms — e.g. "[triceps] heavy rope variation".';

// ─── Resolution ──────────────────────────────────────────────────────────────

/// Outcome of resolving one proposed exercise.
class ResolvedExercise {
  const ResolvedExercise({
    required this.name,
    required this.group,
    required this.tier,
    required this.notes,
  });

  /// Canonical library name (T1) or the original proposed name (T2/T3).
  final String name;

  /// Resolved rank group: from the library (T1, left null — derived downstream),
  /// the declared muscle (T2), or null (T3 → leave unranked).
  final RankGroup? group;

  /// 1 = library match, 2 = custom under declared group, 3 = unresolved.
  final int tier;

  /// Notes with any leading `[muscle]` tag stripped (so it isn't shown raw).
  final String? notes;
}

/// Resolves [proposedName] (+ optional [notes]) against the library.
ResolvedExercise resolveProposedExercise(String proposedName, {String? notes}) {
  final name = proposedName.trim();
  final parsed = _parseMuscleTag(notes);

  // Tier 1 — confident library match.
  final match = snapToLibrary(name);
  if (match != null) {
    return ResolvedExercise(
      name: match.name,
      group: null, // derived from the library exercise downstream
      tier: 1,
      notes: parsed.stripped,
    );
  }

  // Tier 2 — off-library but the model declared a valid (rankable) muscle.
  final group =
      parsed.muscle != null ? rankGroupForMuscle(parsed.muscle!) : null;
  if (group != null) {
    return ResolvedExercise(
        name: name, group: group, tier: 2, notes: parsed.stripped);
  }

  // Tier 3 — unresolved. Caller must NOT default to Chest.
  return ResolvedExercise(
      name: name, group: null, tier: 3, notes: parsed.stripped);
}

/// Matches [proposed] to a library exercise: exact → case-insensitive → slug →
/// TIGHT token-subset fuzzy. Returns null rather than force a loose/ambiguous
/// match (a wrong snap is worse than leaving it custom).
ExerciseDefinition? snapToLibrary(String proposed) {
  final lower = proposed.toLowerCase().trim();
  if (lower.isEmpty) return null;

  for (final ex in exerciseLibrary) {
    if (ex.name.toLowerCase() == lower || ex.id.toLowerCase() == lower) {
      return ex;
    }
  }
  final slug = _slug(lower);
  for (final ex in exerciseLibrary) {
    if (_slug(ex.name.toLowerCase()) == slug || _slug(ex.id) == slug) return ex;
  }

  // Tight fuzzy: every token of a library name appears in the proposed name
  // ("Tricep Rope Pushdown" → "Tricep Pushdown"). Require ≥2 library tokens so
  // single-word names can't over-match, and reject ambiguous ties.
  final pTokens = _tokens(proposed);
  if (pTokens.isEmpty) return null;
  ExerciseDefinition? best;
  var bestLen = 0;
  var bestTies = 0;
  for (final ex in exerciseLibrary) {
    final lTokens = _tokens(ex.name);
    if (lTokens.length < 2) continue;
    if (lTokens.every(pTokens.contains)) {
      if (lTokens.length > bestLen) {
        bestLen = lTokens.length;
        best = ex;
        bestTies = 1;
      } else if (lTokens.length == bestLen) {
        bestTies++;
      }
    }
  }
  return bestTies == 1 ? best : null;
}

/// Parses a leading `[muscle]` tag from [notes]. Returns the mapped rankable
/// [MuscleGroup] (null if absent/unknown/cardio) and the notes with the tag
/// stripped.
({MuscleGroup? muscle, String? stripped}) _parseMuscleTag(String? notes) {
  if (notes == null) return (muscle: null, stripped: null);
  final trimmed = notes.trim();
  final match = RegExp(r'^\[([^\]]+)\]\s*').firstMatch(trimmed);
  if (match == null) return (muscle: null, stripped: notes);
  final token = match.group(1)!.toLowerCase().trim();
  final stripped = trimmed.substring(match.end).trim();
  return (
    muscle: _muscleFromToken(token),
    stripped: stripped.isEmpty ? null : stripped,
  );
}

MuscleGroup? _muscleFromToken(String token) {
  switch (token) {
    case 'chest':
    case 'pecs':
      return MuscleGroup.chest;
    case 'shoulders':
    case 'shoulder':
    case 'delts':
    case 'delt':
    case 'front delt':
    case 'side delt':
    case 'rear delt':
      return MuscleGroup.shoulders;
    case 'triceps':
    case 'tricep':
    case 'tris':
      return MuscleGroup.triceps;
    case 'biceps':
    case 'bicep':
    case 'bis':
      return MuscleGroup.biceps;
    case 'forearms':
    case 'forearm':
      return MuscleGroup.forearms;
    case 'lats':
    case 'lat':
      return MuscleGroup.lats;
    case 'upper back':
    case 'upperback':
    case 'traps':
    case 'rhomboids':
      return MuscleGroup.upperBack;
    case 'lower back':
    case 'lowerback':
    case 'erectors':
      return MuscleGroup.lowerBack;
    case 'quads':
    case 'quad':
    case 'quadriceps':
      return MuscleGroup.quads;
    case 'hamstrings':
    case 'hamstring':
    case 'hams':
      return MuscleGroup.hamstrings;
    case 'glutes':
    case 'glute':
      return MuscleGroup.glutes;
    case 'calves':
    case 'calf':
      return MuscleGroup.calves;
    case 'abs':
    case 'ab':
    case 'core':
      return MuscleGroup.abs;
    case 'obliques':
    case 'oblique':
      return MuscleGroup.obliques;
    default:
      return null; // unknown or cardio → not rankable
  }
}

List<String> _tokens(String s) => s
    .toLowerCase()
    .split(RegExp(r'[^a-z0-9]+'))
    .where((t) => t.isNotEmpty)
    .toList();

String _slug(String s) {
  final buf = StringBuffer();
  for (final r in s.runes) {
    final ch = String.fromCharCode(r);
    if (RegExp(r'[a-z0-9]').hasMatch(ch)) buf.write(ch);
  }
  return buf.toString();
}
