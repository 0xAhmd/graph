import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repo/auth_repo.dart';

class FirebaseAuthRepo implements AuthRepo {
  // get instance from firebase auth

  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Future<AppUser?> getCurrentUser() async {
    final firebaseUser = firebaseAuth.currentUser;
    if (firebaseUser == null) {
      return null;
    }

    final doc = await firestore.collection('users').doc(firebaseUser.uid).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return AppUser.fromJson(doc.data()!);
  }

  @override
  Future<void> logout() async {
    await firebaseAuth.signOut();
  }

  @override
  Future<AppUser?> registerWithEmailAndPassword({
    String? email,
    String? password,
    String? name,
  }) async {
    try {
      UserCredential userCredential = await firebaseAuth
          .createUserWithEmailAndPassword(email: email!, password: password!);

      // create the user
      AppUser user = AppUser(
        uid: userCredential.user!.uid,
        name: name!,
        email: email,
      );
      await firestore.collection('users').doc(user.uid).set(user.toJson());
      return user;
    } on FirebaseAuthException catch (e) {
      // convert Firebase error code to user-friendly message and throw it
      throw _mapFirebaseAuthErrorToMessage(e);
    } catch (e) {
      throw "Something went wrong. Please try again.";
    }
  }

  @override
  Future<AppUser?> signInWithEmailAndPassword({
    String? email,
    String? password,
  }) async {
    try {
      debugPrint('Attempting FirebaseAuth login for $email');
      UserCredential userCredential = await firebaseAuth
          .signInWithEmailAndPassword(email: email!, password: password!);
      final uid = userCredential.user!.uid;
      debugPrint('FirebaseAuth login success, uid: $uid');

      final doc = await firestore.collection('users').doc(uid).get();
      if (!doc.exists || doc.data() == null) {
        debugPrint('User Firestore document not found for $uid');
        throw "User data not found.";
      }

      debugPrint('User Firestore document found for $uid');
      return AppUser.fromJson(doc.data()!);
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: ${e.code}');
      throw _mapFirebaseAuthErrorToMessage(e);
    } catch (e) {
      debugPrint('Unknown error: $e');
      throw "Something went wrong. Please try again.";
    }
  }

  String _mapFirebaseAuthErrorToMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return "No user found for that email.";
      case 'wrong-password':
        return "Incorrect password. Please try again.";
      case 'invalid-email':
        return "The email address is badly formatted.";
      case 'user-disabled':
        return "This user account has been disabled.";
      case 'too-many-requests':
        return "Too many login attempts. Try again later.";
      default:
        return "Login failed. Please try again.";
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) {
        throw "No user is currently signed in.";
      }

      final uid = user.uid;
      debugPrint('Attempting to delete account for uid: $uid');

      // Delete all user data from Firestore first
      await deleteUserInfoFromFirebase(uid);
      debugPrint('All user data deleted from Firestore');

      // Finally, delete the Firebase Auth user
      await user.delete();
      debugPrint('Firebase Auth user deleted successfully');
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during account deletion: ${e.code}');
      throw _mapFirebaseAuthErrorToMessage(e);
    } catch (e) {
      debugPrint('Unknown error during account deletion: $e');
      throw "Failed to delete account. Please try again.";
    }
  }

  @override
  Future<void> deleteUserInfoFromFirebase(String uid) async {
    debugPrint('Starting comprehensive data deletion for user: $uid');

    try {
      // Initialize Supabase storage bucket
      final bucket = Supabase.instance.client.storage.from('images');
      List<String> imagesToDelete = [];

      // Collect user's profile image URL for deletion
      DocumentSnapshot userDoc = await firestore
          .collection('users')
          .doc(uid)
          .get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        String? profileImgUrl = userData['profileImgUrl'];
        if (profileImgUrl != null && profileImgUrl.isNotEmpty) {
          String? fileName = _extractFileNameFromSupabaseUrl(profileImgUrl);
          if (fileName != null) {
            imagesToDelete.add(fileName);
          }
        }
      }

      // Collect user's post images for deletion
      QuerySnapshot userPosts = await firestore
          .collection('posts')
          .where('uid', isEqualTo: uid)
          .get();

      for (var post in userPosts.docs) {
        Map<String, dynamic> postData = post.data() as Map<String, dynamic>;
        String? postImgUrl = postData['postImgUrl'];
        if (postImgUrl != null && postImgUrl.isNotEmpty) {
          String? fileName = _extractFileNameFromSupabaseUrl(postImgUrl);
          if (fileName != null) {
            imagesToDelete.add(fileName);
          }
        }
      }

      debugPrint(
        'Found ${imagesToDelete.length} images to delete from Supabase storage',
      );

      // Delete images from Supabase storage
      if (imagesToDelete.isNotEmpty) {
        try {
          await bucket.remove(imagesToDelete);
          debugPrint(
            'Successfully deleted ${imagesToDelete.length} images from Supabase storage',
          );
        } catch (e) {
          debugPrint('Error deleting images from Supabase storage: $e');
          // Continue with Firestore deletion even if image deletion fails
        }
      }

      // Now proceed with existing Firestore cleanup...

      // First, handle all updates (removing likes from posts and follow relationships)
      QuerySnapshot allPosts = await firestore.collection('posts').get();
      WriteBatch updateBatch = firestore.batch();

      // Remove user's likes from all posts
      for (QueryDocumentSnapshot post in allPosts.docs) {
        Map<String, dynamic> postData = post.data() as Map<String, dynamic>;
        var likedBy = postData['likedBy'] as List<dynamic>? ?? [];
        if (likedBy.contains(uid)) {
          updateBatch.update(post.reference, {
            'likes': FieldValue.increment(-1),
            'likedBy': FieldValue.arrayRemove([uid]),
          });
        }
      }

      // Remove user from followers/following relationships
      QuerySnapshot allUsers = await firestore.collection('users').get();
      for (QueryDocumentSnapshot userDoc in allUsers.docs) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        // Remove from followers list
        var followers = userData['followers'] as List<dynamic>? ?? [];
        if (followers.contains(uid)) {
          updateBatch.update(userDoc.reference, {
            'followersCount': FieldValue.increment(-1),
            'followers': FieldValue.arrayRemove([uid]),
          });
        }

        // Remove from following list
        var following = userData['following'] as List<dynamic>? ?? [];
        if (following.contains(uid)) {
          updateBatch.update(userDoc.reference, {
            'followingCount': FieldValue.increment(-1),
            'following': FieldValue.arrayRemove([uid]),
          });
        }
      }

      // Commit the updates first
      await updateBatch.commit();
      debugPrint('User references removed from posts and user relationships');

      // Then handle all deletions in a separate batch
      WriteBatch deleteBatch = firestore.batch();

      // Delete user document
      DocumentReference userDocRef = firestore.collection('users').doc(uid);
      deleteBatch.delete(userDocRef);

      // Delete user's posts (already collected above)
      for (var post in userPosts.docs) {
        deleteBatch.delete(post.reference);
      }
      debugPrint('Queued deletion of ${userPosts.docs.length} user posts');

      // Delete user's comments
      QuerySnapshot userComments = await firestore
          .collection('comments')
          .where('uid', isEqualTo: uid)
          .get();
      for (var comment in userComments.docs) {
        deleteBatch.delete(comment.reference);
      }
      debugPrint(
        'Queued deletion of ${userComments.docs.length} user comments',
      );

      // Commit the deletion batch
      await deleteBatch.commit();
      debugPrint('All user data and documents deleted successfully');
    } catch (e) {
      debugPrint('Error during comprehensive user data deletion: $e');
      rethrow;
    }
  }

  // Helper method to extract filename from Supabase public URL
  String? _extractFileNameFromSupabaseUrl(String url) {
    try {
      // Supabase public URLs typically look like:
      // https://[project-id].supabase.co/storage/v1/object/public/images/[filename]

      Uri uri = Uri.parse(url);
      List<String> pathSegments = uri.pathSegments;

      // Find the index of 'public' and get the next segment after bucket name
      int publicIndex = pathSegments.indexOf('public');
      if (publicIndex != -1 && publicIndex + 2 < pathSegments.length) {
        // The filename should be after 'public/bucket-name/'
        return pathSegments[publicIndex + 2];
      }

      // Alternative: just get the last segment if the above doesn't work
      return pathSegments.last;
    } catch (e) {
      debugPrint('Error extracting filename from URL: $url, Error: $e');
      return null;
    }
  }
}
