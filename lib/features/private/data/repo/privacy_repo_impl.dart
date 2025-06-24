// lib/features/private/data/repo/privacy_repo_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:ig_mate/features/profile/domain/repo/privacy_repo.dart';
import '../../domain/entities/privacy_settings.dart';

class PrivacyRepo implements PrivacyRepoContract {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> updatePrivacySettings({
    required String userId,
    required bool isPrivate,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isPrivate': isPrivate,
        'lastEmailUpdate': FieldValue.serverTimestamp(),
      });

      debugPrint(
        'Privacy settings updated for user: $userId, isPrivate: $isPrivate',
      );
    } catch (e) {
      debugPrint('Error updating privacy settings: $e');
      rethrow;
    }
  }

  @override
  Future<PrivacySettingsEntity?> getPrivacySettings(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        return PrivacySettingsEntity(
          userId: userId,
          isPrivate: data['isPrivate'] ?? false,
          updatedAt: data['lastEmailUpdate'] != null
              ? (data['lastEmailUpdate'] as Timestamp).toDate()
              : DateTime.now(),
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error getting privacy settings: $e');
      return null;
    }
  }

  @override
  Future<bool> isUserPrivate(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        return data['isPrivate'] ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('Error checking if user is private: $e');
      return false;
    }
  }

  @override
  Stream<PrivacySettingsEntity?> streamPrivacySettings(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists) {
            final data = snapshot.data()!;
            return PrivacySettingsEntity(
              userId: userId,
              isPrivate: data['isPrivate'] ?? false,
              updatedAt: data['lastEmailUpdate'] != null
                  ? (data['lastEmailUpdate'] as Timestamp).toDate()
                  : DateTime.now(),
            );
          }
          return null;
        })
        .handleError((error) {
          debugPrint('Error streaming privacy settings: $error');
          return null;
        });
  }
}
