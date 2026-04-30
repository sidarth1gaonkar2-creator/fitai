import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  StorageService(this._storage);

  final FirebaseStorage _storage;
  final _picker = ImagePicker();

  /// Pick an image from gallery or camera, compressed to 512x512 max.
  Future<File?> pickImage({ImageSource source = ImageSource.gallery}) async {
    final xFile = await _picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (xFile == null) return null;
    return File(xFile.path);
  }

  /// Upload profile picture and return download URL.
  Future<String> uploadProfilePicture(String userId, File file) async {
    final ref = _storage.ref('profiles/$userId.jpg');
    await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }

  /// Delete profile picture.
  Future<void> deleteProfilePicture(String userId) async {
    try {
      await _storage.ref('profiles/$userId.jpg').delete();
    } catch (e) {
      debugPrint('[StorageService] Delete failed: $e');
    }
  }

  /// Upload a challenge proof photo and return the download URL.
  ///
  /// Path: challenges/{challengeId}/proofs/{userId}/{yyyyMMdd}.jpg
  Future<String> uploadChallengeProof({
    required String challengeId,
    required String userId,
    required DateTime date,
    required File file,
  }) async {
    final key = _dayKey(date);
    final ref =
        _storage.ref('challenges/$challengeId/proofs/$userId/$key.jpg');
    await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }

  String _dayKey(DateTime d) {
    final utc = d.toUtc();
    final y = utc.year.toString().padLeft(4, '0');
    final m = utc.month.toString().padLeft(2, '0');
    final day = utc.day.toString().padLeft(2, '0');
    return '$y$m$day';
  }
}
