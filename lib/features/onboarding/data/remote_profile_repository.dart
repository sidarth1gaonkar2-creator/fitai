import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/enums.dart';
import '../../../models/user_profile.dart';
import '../../../providers/firestore_provider.dart';

/// The user's fitness onboarding profile, persisted to a PRIVATE, owner-only
/// Firestore doc: `users/{uid}/private/profile`.
///
/// This is the cross-device source of truth for "has this account completed
/// onboarding?". It is deliberately NOT on the public `users/{uid}` doc, which
/// is world-readable by any signed-in user — health data (age, weight, TDEE)
/// must never live there.
class RemoteProfile {
  const RemoteProfile({
    required this.name,
    required this.age,
    required this.sex,
    required this.weightKg,
    required this.heightCm,
    required this.goal,
    required this.activityLevel,
    required this.tdee,
  });

  final String name;
  final int age;
  final Sex sex;
  final double weightKg;
  final double heightCm;
  final Goal goal;
  final ActivityLevel activityLevel;
  final double tdee;

  /// A profile counts as "complete" only when onboarding produced the required
  /// fields — the routing gate keys off this, not merely the doc's existence.
  bool get isComplete =>
      tdee > 0 && age > 0 && weightKg > 0 && heightCm > 0;

  Map<String, dynamic> toMap() => {
        'name': name,
        'age': age,
        'sex': sex.name,
        'weightKg': weightKg,
        'heightCm': heightCm,
        'goal': goal.name,
        'activityLevel': activityLevel.name,
        'tdee': tdee,
        // Fast-path cache flag; the required fields above are the real check.
        'onboardingCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  /// Parses a Firestore map, returning null if the completion flag is unset or
  /// a required field is missing/malformed (treated as "no usable profile").
  static RemoteProfile? tryFromMap(Map<String, dynamic> m) {
    if (m['onboardingCompleted'] != true) return null;
    final sex = _enumByName(Sex.values, m['sex']);
    final goal = _enumByName(Goal.values, m['goal']);
    final activity = _enumByName(ActivityLevel.values, m['activityLevel']);
    final age = (m['age'] as num?)?.toInt();
    final weight = (m['weightKg'] as num?)?.toDouble();
    final height = (m['heightCm'] as num?)?.toDouble();
    final tdee = (m['tdee'] as num?)?.toDouble();
    if (sex == null ||
        goal == null ||
        activity == null ||
        age == null ||
        weight == null ||
        height == null ||
        tdee == null) {
      return null;
    }
    return RemoteProfile(
      name: m['name'] as String? ?? '',
      age: age,
      sex: sex,
      weightKg: weight,
      heightCm: height,
      goal: goal,
      activityLevel: activity,
      tdee: tdee,
    );
  }

  factory RemoteProfile.fromLocal(UserProfile p) => RemoteProfile(
        name: p.name,
        age: p.age,
        sex: p.sex,
        weightKg: p.weight,
        heightCm: p.height,
        goal: p.goal,
        activityLevel: p.activityLevel,
        tdee: p.tdee,
      );

  /// Builds a local Isar profile from this remote one (new-device hydration).
  UserProfile toUserProfile() => UserProfile()
    ..name = name
    ..age = age
    ..sex = sex
    ..weight = weightKg
    ..height = heightCm
    ..goal = goal
    ..activityLevel = activityLevel
    ..tdee = tdee;
}

T? _enumByName<T extends Enum>(List<T> values, Object? name) {
  if (name is! String) return null;
  for (final v in values) {
    if (v.name == name) return v;
  }
  return null;
}

class RemoteProfileRepository {
  RemoteProfileRepository(this._firestore);
  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String uid) => _firestore
      .collection('users')
      .doc(uid)
      .collection('private')
      .doc('profile');

  /// Returns the completed onboarding profile, or null when there is no
  /// complete profile doc.
  ///
  /// THROWS on network/permission errors so callers can distinguish "new user"
  /// (null) from "couldn't check" (throw) — the latter must never be treated as
  /// a new user.
  Future<RemoteProfile?> fetch(String uid) async {
    final snap = await _doc(uid).get();
    if (!snap.exists) return null;
    final data = snap.data();
    if (data == null) return null;
    final profile = RemoteProfile.tryFromMap(data);
    return (profile != null && profile.isComplete) ? profile : null;
  }

  /// Writes/merges the private profile doc. Merge so it never clobbers fields
  /// other flows may add later.
  Future<void> save(String uid, RemoteProfile profile) async {
    await _doc(uid).set(profile.toMap(), SetOptions(merge: true));
  }
}

final remoteProfileRepositoryProvider =
    Provider<RemoteProfileRepository>((ref) {
  return RemoteProfileRepository(ref.watch(firestoreProvider));
});
