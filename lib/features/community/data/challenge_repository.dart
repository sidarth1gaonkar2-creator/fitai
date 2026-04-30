import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/logger.dart';
import '../../../providers/firestore_provider.dart';
import '../../../services/storage_service.dart';
import '../domain/challenge.dart';
import 'notification_repository.dart';

final challengeRepositoryProvider = Provider<ChallengeRepository>((ref) {
  return ChallengeRepository(
    firestore: ref.watch(firestoreProvider),
    storage: ref.watch(storageServiceProvider),
    notifications: ref.watch(notificationRepositoryProvider),
  );
});

class ChallengeRepository {
  ChallengeRepository({
    required FirebaseFirestore firestore,
    required StorageService storage,
    required NotificationRepository notifications,
  })  : _firestore = firestore,
        _storage = storage,
        _notifications = notifications;

  final FirebaseFirestore _firestore;
  final StorageService _storage;
  final NotificationRepository _notifications;

  CollectionReference<Map<String, dynamic>> get _challenges =>
      _firestore.collection('challenges');
  CollectionReference<Map<String, dynamic>> get _participants =>
      _firestore.collection('challenge_participants');

  String _participantId(String challengeId, String userId) =>
      '${challengeId}_$userId';

  Future<void> createChallenge(Challenge challenge) async {
    await _challenges.doc(challenge.challengeId).set(challenge.toMap());
  }

  Future<Challenge?> getChallenge(String challengeId) async {
    final doc = await _challenges.doc(challengeId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Challenge.fromMap(doc.data()!);
  }

  Future<List<Challenge>> getPublicChallenges() async {
    try {
      final now = DateTime.now();
      final snap = await _challenges
          .where('isPublic', isEqualTo: true)
          .where('endDate', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('endDate')
          .limit(30)
          .get();
      return snap.docs.map((d) => Challenge.fromMap(d.data())).toList();
    } catch (e, stack) {
      _logQueryError('getPublicChallenges', e, stack);
      rethrow;
    }
  }

  Future<List<Challenge>> getMyChallenges(String userId) async {
    try {
      final partSnap =
          await _participants.where('userId', isEqualTo: userId).get();
      if (partSnap.docs.isEmpty) return const [];

      final challengeIds = partSnap.docs
          .map((d) => d.data()['challengeId'] as String)
          .toSet()
          .toList();

      final results = <Challenge>[];
      for (var i = 0; i < challengeIds.length; i += 10) {
        final batch = challengeIds.sublist(
            i, (i + 10).clamp(0, challengeIds.length));
        final snap = await _challenges
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        results.addAll(
            snap.docs.map((d) => Challenge.fromMap(d.data())));
      }
      return results;
    } catch (e, stack) {
      _logQueryError('getMyChallenges', e, stack);
      rethrow;
    }
  }

  void _logQueryError(String op, Object e, StackTrace stack) {
    AppLogger.error(
      'ChallengeRepository.$op failed',
      error: e,
      stack: stack,
    );
    if (e is FirebaseException) {
      debugPrint('[Challenges] Firebase code: ${e.code}');
      final msg = e.message ?? '';
      final urlStart = msg.indexOf('https://');
      if (urlStart != -1) {
        debugPrint('[Challenges] INDEX URL: ${msg.substring(urlStart)}');
      }
    }
  }

  Future<void> joinChallenge(ChallengeParticipant participant) async {
    final docId =
        _participantId(participant.challengeId, participant.userId);
    final batch = _firestore.batch();
    batch.set(_participants.doc(docId), participant.toMap());
    batch.update(_challenges.doc(participant.challengeId), {
      'participantCount': FieldValue.increment(1),
    });
    await batch.commit();

    // Notify the challenge creator.
    final challenge = await getChallenge(participant.challengeId);
    if (challenge != null) {
      AppLogger.log('Challenge joined: "${challenge.title}"');
      if (challenge.creatorId.isNotEmpty &&
          challenge.creatorId != 'system' &&
          challenge.creatorId != participant.userId) {
        await _notifications.send(
          toUserId: challenge.creatorId,
          type: 'challenge_join',
          fromUserId: participant.userId,
          fromUsername: participant.username,
          fromUserAvatar: participant.profilePictureUrl,
          message:
              '${participant.username} joined your challenge "${challenge.title}"',
          challengeId: challenge.challengeId,
        );
      }
    }
  }

  Future<void> leaveChallenge(String challengeId, String userId) async {
    final docId = _participantId(challengeId, userId);
    final batch = _firestore.batch();
    batch.delete(_participants.doc(docId));
    batch.update(_challenges.doc(challengeId), {
      'participantCount': FieldValue.increment(-1),
    });
    await batch.commit();
  }

  /// Current participant state for a user in a challenge.
  Future<ChallengeParticipant?> getParticipant(
      String challengeId, String userId) async {
    final doc =
        await _participants.doc(_participantId(challengeId, userId)).get();
    if (!doc.exists || doc.data() == null) return null;
    return ChallengeParticipant.fromMap(doc.data()!);
  }

  /// Returns all participants for a challenge ordered by completedDays desc.
  Future<List<ChallengeParticipant>> getParticipants(
      String challengeId) async {
    final snap = await _participants
        .where('challengeId', isEqualTo: challengeId)
        .orderBy('joinedAt', descending: true)
        .get();
    final list = snap.docs
        .map((d) => ChallengeParticipant.fromMap(d.data()))
        .toList();
    list.sort((a, b) => b.completedDays.compareTo(a.completedDays));
    return list;
  }

  Future<bool> isParticipant(String challengeId, String userId) async {
    final doc =
        await _participants.doc(_participantId(challengeId, userId)).get();
    return doc.exists;
  }

  /// Logs today's check-in for a challenge participant. If the challenge
  /// requires photo proof, caller must supply [proofFile]. Returns the
  /// updated participant state.
  ///
  /// Idempotent on the same UTC day — does nothing if already checked in.
  Future<ChallengeParticipant> checkIn({
    required Challenge challenge,
    required String userId,
    File? proofFile,
  }) async {
    final participant =
        await getParticipant(challenge.challengeId, userId);
    if (participant == null) {
      throw StateError('Not a participant of this challenge');
    }

    if (challenge.requiresPhotoProof && proofFile == null) {
      throw ArgumentError('This challenge requires a photo proof.');
    }

    final today = _utcDay(DateTime.now());
    final last =
        participant.lastCheckInDate == null ? null : _utcDay(participant.lastCheckInDate!);

    if (last != null && !today.isAfter(last)) {
      // Already checked in today (or earlier-dated record shouldn't advance).
      return participant;
    }

    String? proofUrl;
    if (proofFile != null) {
      proofUrl = await _storage.uploadChallengeProof(
        challengeId: challenge.challengeId,
        userId: userId,
        date: today,
        file: proofFile,
      );
    }

    final newStreak = last != null && today.difference(last).inDays == 1
        ? participant.currentStreak + 1
        : 1;
    final newCompletedDays = participant.completedDays + 1;
    final isCompleted = newCompletedDays >= challenge.durationDays;

    final updates = <String, dynamic>{
      'completedDays': newCompletedDays,
      'currentStreak': newStreak,
      'lastCheckInDate': Timestamp.fromDate(today),
      'isCompleted': isCompleted,
      if (proofUrl != null)
        'proofPhotos': FieldValue.arrayUnion([proofUrl]),
    };

    await _participants
        .doc(_participantId(challenge.challengeId, userId))
        .update(updates);

    return ChallengeParticipant(
      challengeId: participant.challengeId,
      userId: participant.userId,
      username: participant.username,
      profilePictureUrl: participant.profilePictureUrl,
      joinedAt: participant.joinedAt,
      completedDays: newCompletedDays,
      currentStreak: newStreak,
      proofPhotos: [
        ...participant.proofPhotos,
        ?proofUrl,
      ],
      isCompleted: isCompleted,
      lastCheckInDate: today,
    );
  }

  /// Returns whether this user already checked in today.
  bool didCheckInToday(ChallengeParticipant? p) {
    if (p?.lastCheckInDate == null) return false;
    final last = _utcDay(p!.lastCheckInDate!);
    final today = _utcDay(DateTime.now());
    return !today.isAfter(last);
  }

  DateTime _utcDay(DateTime d) {
    final utc = d.toUtc();
    return DateTime.utc(utc.year, utc.month, utc.day);
  }
}
