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
}
