import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ig_mate/core/utils/err_mapper.dart';
import 'package:ig_mate/core/utils/file_name.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    hide User, OAuthProvider;
import '../../domain/entities/app_user.dart';
import '../../domain/repo/auth_repo.dart';

class FirebaseAuthRepo implements AuthRepoContract {
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
      throw mapFirebaseAuthErrorToMessage(e);
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
      UserCredential userCredential = await firebaseAuth
          .signInWithEmailAndPassword(email: email!, password: password!);
      final uid = userCredential.user!.uid;

      final doc = await firestore.collection('users').doc(uid).get();
      if (!doc.exists || doc.data() == null) {
        throw "User data not found.";
      }

      return AppUser.fromJson(doc.data()!);
    } on FirebaseAuthException catch (e) {
      throw mapFirebaseAuthErrorToMessage(e);
    } catch (e) {
      throw "Something went wrong. Please try again.";
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

      // Delete all user data from Firestore first
      await deleteUserInfoFromFirebase(uid);

      // Finally, delete the Firebase Auth user
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw mapFirebaseAuthErrorToMessage(e);
    } catch (e) {
      throw "Failed to delete account. Please try again.";
    }
  }

  @override
  Future<void> deleteUserInfoFromFirebase(String uid) async {
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
          String? fileName = extractFileNameFromSupabaseUrl(profileImgUrl);
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
          String? fileName = extractFileNameFromSupabaseUrl(postImgUrl);
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
          debugPrint('Failed to delete images from Supabase storage: $e');
          throw "Failed to delete images from storage. Please try again.";
        }
      }

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

      // Then handle all deletions in a separate batch
      WriteBatch deleteBatch = firestore.batch();

      // Delete user document
      DocumentReference userDocRef = firestore.collection('users').doc(uid);
      deleteBatch.delete(userDocRef);

      // Delete user's posts (already collected above)
      for (var post in userPosts.docs) {
        deleteBatch.delete(post.reference);
      }

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
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AppUser?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null; // User cancelled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await firebaseAuth
          .signInWithCredential(credential);

      final User? firebaseUser = userCredential.user;
      if (firebaseUser == null) return null;

      final docRef = firestore.collection('users').doc(firebaseUser.uid);
      final doc = await docRef.get();

      if (!doc.exists) {
        final newUser = AppUser(
          uid: firebaseUser.uid,
          name: firebaseUser.displayName ?? 'Unknown',
          email: firebaseUser.email ?? '',
        );
        await docRef.set(newUser.toJson());
        return newUser;
      }

      return AppUser.fromJson(doc.data()!);
    } on FirebaseAuthException catch (e) {
      throw mapFirebaseAuthErrorToMessage(e);
    } catch (e) {
      throw "Google sign-in failed. Please try again.";
    }
  }

  @override
  Future<AppUser?> signInWithGitHub() async {
    try {
      // Create a generic OAuth provider for GitHub
      final githubProvider = OAuthProvider('github.com');

      // Add the scopes you need
      githubProvider.addScope('user:email');
      githubProvider.addScope('read:user');

      // Set custom parameters if needed
      githubProvider.setCustomParameters({'allow_signup': 'true'});

      // Trigger the authentication flow
      final UserCredential userCredential = await firebaseAuth
          .signInWithProvider(githubProvider);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) return null;

      // Check if user exists in Firestore
      final docRef = firestore.collection('users').doc(firebaseUser.uid);
      final doc = await docRef.get();

      if (!doc.exists) {
        // New user - create their profile
        final newUser = AppUser(
          uid: firebaseUser.uid,
          name: firebaseUser.displayName ?? 'Unknown',
          email: firebaseUser.email ?? '',
        );
        await docRef.set(newUser.toJson());
        return newUser;
      }

      return AppUser.fromJson(doc.data()!);
    } on FirebaseAuthException catch (e) {
      throw mapFirebaseAuthErrorToMessage(e);
    } catch (e) {
      throw "GitHub sign-in failed. Please try again.";
    }
  }
}
