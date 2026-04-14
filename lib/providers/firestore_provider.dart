import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  throw UnimplementedError('FirebaseFirestore must be overridden in ProviderScope');
});

final storageProvider = Provider<FirebaseStorage>((ref) {
  throw UnimplementedError('FirebaseStorage must be overridden in ProviderScope');
});

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService(ref.watch(firestoreProvider));
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(ref.watch(storageProvider));
});
