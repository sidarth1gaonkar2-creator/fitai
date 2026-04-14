import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirestoreService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _firestore.collection(path);

  Future<DocumentSnapshot<Map<String, dynamic>>> getDoc(String path) =>
      _firestore.doc(path).get();

  Future<void> setDoc(String path, Map<String, dynamic> data,
      {bool merge = false}) =>
      _firestore.doc(path).set(data, SetOptions(merge: merge));

  Future<void> updateDoc(String path, Map<String, dynamic> data) =>
      _firestore.doc(path).update(data);

  Future<void> deleteDoc(String path) => _firestore.doc(path).delete();

  Future<QuerySnapshot<Map<String, dynamic>>> query(
    String collectionPath, {
    List<QueryFilter> filters = const [],
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query<Map<String, dynamic>> q = _firestore.collection(collectionPath);
    for (final f in filters) {
      q = q.where(f.field, isEqualTo: f.isEqualTo, isGreaterThanOrEqualTo: f.isGte, isLessThan: f.isLt, whereIn: f.whereIn);
    }
    if (orderBy != null) q = q.orderBy(orderBy, descending: descending);
    if (limit != null) q = q.limit(limit);
    return q.get();
  }

  Future<(List<QueryDocumentSnapshot<Map<String, dynamic>>>, DocumentSnapshot?)>
      paginatedQuery(
    String collectionPath, {
    required String orderBy,
    bool descending = true,
    int limit = 20,
    DocumentSnapshot? startAfter,
    List<QueryFilter> filters = const [],
  }) async {
    Query<Map<String, dynamic>> q = _firestore.collection(collectionPath);
    for (final f in filters) {
      if (f.isEqualTo != null) q = q.where(f.field, isEqualTo: f.isEqualTo);
      if (f.whereIn != null) q = q.where(f.field, whereIn: f.whereIn);
    }
    q = q.orderBy(orderBy, descending: descending);
    if (startAfter != null) q = q.startAfterDocument(startAfter);
    q = q.limit(limit);
    final snap = await q.get();
    final lastDoc = snap.docs.isNotEmpty ? snap.docs.last : null;
    return (snap.docs, lastDoc);
  }

  WriteBatch batch() => _firestore.batch();

  Future<T> runTransaction<T>(TransactionHandler<T> handler) =>
      _firestore.runTransaction(handler);
}

class QueryFilter {
  const QueryFilter({
    required this.field,
    this.isEqualTo,
    this.isGte,
    this.isLt,
    this.whereIn,
  });

  final String field;
  final Object? isEqualTo;
  final Object? isGte;
  final Object? isLt;
  final List<Object>? whereIn;
}
