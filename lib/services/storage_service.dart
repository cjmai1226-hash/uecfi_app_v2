import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as p;
import 'user_service.dart';

class StorageService {
  static final StorageService instance = StorageService._internal();
  StorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _getContentType(String ext) {
    switch (ext.toLowerCase()) {
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.jpg':
      case '.jpeg':
      default:
        return 'image/jpeg';
    }
  }

  /// Uploads user avatar to Firebase Storage, updates local profile and Firestore users collection
  Future<String?> uploadAvatar(File imageFile, String userEmail) async {
    try {
      if (userEmail.isEmpty) {
        userEmail = 'user_${DateTime.now().millisecondsSinceEpoch}';
      }

      final cleanEmail = userEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final ext = p.extension(imageFile.path).isNotEmpty
          ? p.extension(imageFile.path).toLowerCase()
          : '.jpg';
      final mimeType = _getContentType(ext);
      final ref = _storage.ref().child('avatars/$cleanEmail$ext');

      final uploadTask = await ref.putFile(
        imageFile,
        SettableMetadata(contentType: mimeType),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Sync with UserService
      await UserService.instance.updateProfileImages(avatarUrl: downloadUrl);

      // Sync with Firestore users collection
      if (userEmail.contains('@')) {
        await _firestore.collection('users').doc(userEmail.toLowerCase()).set({
          'avatarUrl': downloadUrl,
        }, SetOptions(merge: true));
      }

      debugPrint('✅ Avatar uploaded to Firebase Storage ($mimeType): $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Error uploading avatar to Firebase Storage: $e');
      return null;
    }
  }

  /// Uploads user cover photo to Firebase Storage
  Future<String?> uploadCover(File imageFile, String userEmail) async {
    try {
      if (userEmail.isEmpty) {
        userEmail = 'user_${DateTime.now().millisecondsSinceEpoch}';
      }

      final cleanEmail = userEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final ext = p.extension(imageFile.path).isNotEmpty
          ? p.extension(imageFile.path).toLowerCase()
          : '.jpg';
      final mimeType = _getContentType(ext);
      final ref = _storage.ref().child('covers/$cleanEmail$ext');

      final uploadTask = await ref.putFile(
        imageFile,
        SettableMetadata(contentType: mimeType),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Sync with UserService
      await UserService.instance.updateProfileImages(coverUrl: downloadUrl);

      // Sync with Firestore users collection
      if (userEmail.contains('@')) {
        await _firestore.collection('users').doc(userEmail.toLowerCase()).set({
          'coverUrl': downloadUrl,
        }, SetOptions(merge: true));
      }

      debugPrint('✅ Cover uploaded to Firebase Storage ($mimeType): $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Error uploading cover to Firebase Storage: $e');
      return null;
    }
  }
}
