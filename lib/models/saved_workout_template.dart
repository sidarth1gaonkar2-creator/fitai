import 'package:isar/isar.dart';

part 'saved_workout_template.g.dart';

/// A reusable, ready-to-start workout template saved on-device (Build 75).
///
/// Created when the user taps Apply on an AI Coach `create_workout` proposal.
/// Shown in the Workouts → Templates tab alongside the built-in templates, but
/// distinguishable by [source] and deletable (built-ins are not). uid-scoped
/// from day one — every query filters by the current Firebase uid so templates
/// never leak across accounts on a shared device.
///
/// v1 is local-only (no Firestore sync); templates don't follow the user to a
/// new device yet. See the deferred list.
@collection
class SavedWorkoutTemplate {
  Id id = Isar.autoIncrement;

  @Index()
  late String uid;

  late String name;

  late String focus;

  /// JSON-encoded `List<Map>` of exercises, each:
  /// `{ exerciseName, sets, reps, suggestedWeightKg, restSeconds, notes }`.
  /// suggestedWeightKg is stored in kg (null when the AI had no history).
  late String exercisesJson;

  /// Origin marker, e.g. 'coach' for AI-generated templates — drives the badge.
  String source = 'coach';

  DateTime createdAt = DateTime.now();
}
