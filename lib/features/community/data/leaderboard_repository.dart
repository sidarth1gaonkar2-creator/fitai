import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/firestore_provider.dart';
import '../domain/leaderboard_entry.dart';

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  return LeaderboardRepository(ref.watch(firestoreProvider));
});

class LeaderboardRepository {
  LeaderboardRepository(this._firestore);
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _entries =>
      _firestore.collection('leaderboard_entries');

  Future<void> updateEntry(LeaderboardEntry entry) async {
    await _entries
        .doc(entry.userId)
        .set(entry.toMap(), SetOptions(merge: true));
  }

  /// Single leaderboard row for [userId], or null when the user has no entry
  /// yet. Powers the mini-profile sheet (rank scores + big-3 lifts).
  Future<LeaderboardEntry?> getEntry(String userId) async {
    final doc = await _entries.doc(userId).get();
    if (!doc.exists || doc.data() == null) return null;
    return LeaderboardEntry.fromMap(doc.data()!);
  }

  Future<List<LeaderboardEntry>> getTopBy(String field,
      {int limit = 50}) async {
    final snap = await _entries
        .orderBy(field, descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => LeaderboardEntry.fromMap(d.data()))
        .toList();
  }

  Future<List<LeaderboardEntry>> getFriendsLeaderboard(
      Set<String> friendIds, String field) async {
    if (friendIds.isEmpty) return const [];
    final ids = friendIds.toList();
    final results = <LeaderboardEntry>[];

    // Batch whereIn (max 30 in Firestore, Flutter SDK limit 30)
    for (var i = 0; i < ids.length; i += 30) {
      final batch = ids.sublist(i, (i + 30).clamp(0, ids.length));
      final snap = await _entries
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      results.addAll(
          snap.docs.map((d) => LeaderboardEntry.fromMap(d.data())));
    }

    // Sort by the requested field
    results.sort((a, b) {
      final aVal = _fieldValue(a, field);
      final bVal = _fieldValue(b, field);
      return bVal.compareTo(aVal);
    });
    return results;
  }

  double _fieldValue(LeaderboardEntry e, String field) {
    return switch (field) {
      'currentStreak' => e.currentStreak.toDouble(),
      'totalVolume' => e.totalVolume,
      'totalWorkouts' => e.totalWorkouts.toDouble(),
      // Rank-score segments (overall + per muscle group).
      _ => e.scoreForField(field),
    };
  }
}
