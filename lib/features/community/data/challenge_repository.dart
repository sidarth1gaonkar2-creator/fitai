import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/firestore_provider.dart';
import '../domain/challenge.dart';

final challengeRepositoryProvider = Provider<ChallengeRepository>((ref) {
  return ChallengeRepository(ref.watch(firestoreProvider));
});

class ChallengeRepository {
  ChallengeRepository(this._firestore);
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _challenges =>
      _firestore.collection('challenges');
  CollectionReference<Map<String, dynamic>> get _participants =>
      _firestore.collection('challenge_participants');

  Future<void> createChallenge(Challenge challenge) async {
    await _challenges.doc(challenge.challengeId).set(challenge.toMap());
  }

  Future<Challenge?> getChallenge(String challengeId) async {
    final doc = await _challenges.doc(challengeId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Challenge.fromMap(doc.data()!);
  }

  Future<List<Challenge>> getPublicChallenges() async {
    final now = DateTime.now();
    final snap = await _challenges
        .where('isPublic', isEqualTo: true)
        .where('endDate', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('endDate')
        .limit(30)
        .get();
    return snap.docs.map((d) => Challenge.fromMap(d.data())).toList();
  }

  Future<List<Challenge>> getMyChallenges(String userId) async {
    final partSnap = await _participants
        .where('userId', isEqualTo: userId)
        .get();
    if (partSnap.docs.isEmpty) return const [];

    final challengeIds = partSnap.docs
        .map((d) => d.data()['challengeId'] as String)
        .toSet()
        .toList();

    final results = <Challenge>[];
    for (var i = 0; i < challengeIds.length; i += 10) {
      final batch =
          challengeIds.sublist(i, (i + 10).clamp(0, challengeIds.length));
      final snap = await _challenges
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      results.addAll(snap.docs.map((d) => Challenge.fromMap(d.data())));
    }
    return results;
  }

  Future<void> joinChallenge(ChallengeParticipant participant) async {
    final docId = '${participant.challengeId}_${participant.userId}';
    final batch = _firestore.batch();
    batch.set(_participants.doc(docId), participant.toMap());
    batch.update(_challenges.doc(participant.challengeId), {
      'participantCount': FieldValue.increment(1),
    });
    await batch.commit();
  }

  Future<void> leaveChallenge(String challengeId, String userId) async {
    final docId = '${challengeId}_$userId';
    final batch = _firestore.batch();
    batch.delete(_participants.doc(docId));
    batch.update(_challenges.doc(challengeId), {
      'participantCount': FieldValue.increment(-1),
    });
    await batch.commit();
  }

  Future<void> updateProgress(
      String challengeId, String userId, double progress) async {
    final docId = '${challengeId}_$userId';
    await _participants.doc(docId).update({
      'progress': progress,
    });
  }

  Future<List<ChallengeParticipant>> getParticipants(
      String challengeId) async {
    final snap = await _participants
        .where('challengeId', isEqualTo: challengeId)
        .orderBy('progress', descending: true)
        .get();
    return snap.docs
        .map((d) => ChallengeParticipant.fromMap(d.data()))
        .toList();
  }

  Future<bool> isParticipant(String challengeId, String userId) async {
    final docId = '${challengeId}_$userId';
    final doc = await _participants.doc(docId).get();
    return doc.exists;
  }

  Future<List<ChallengeParticipant>> getUserParticipations(
      String userId) async {
    final snap = await _participants
        .where('userId', isEqualTo: userId)
        .get();
    return snap.docs
        .map((d) => ChallengeParticipant.fromMap(d.data()))
        .toList();
  }
}
