import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ig_mate/features/auth/domain/entities/app_user.dart';
import 'package:ig_mate/features/auth/domain/repo/auth_repo.dart';

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
  Future<AppUser?> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
  ) async {
    try {
      UserCredential userCredential = await firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      // create the user
      AppUser user = AppUser(
        uid: userCredential.user!.uid,
        name: name,
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

  Future<AppUser?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      print('Attempting FirebaseAuth login for $email');
      UserCredential userCredential = await firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);
      final uid = userCredential.user!.uid;
      print('FirebaseAuth login success, uid: $uid');

      final doc = await firestore.collection('users').doc(uid).get();
      if (!doc.exists || doc.data() == null) {
        print('User Firestore document not found for $uid');
        throw "User data not found.";
      }

      print('User Firestore document found for $uid');
      return AppUser.fromJson(doc.data()!);
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code}');
      throw _mapFirebaseAuthErrorToMessage(e);
    } catch (e) {
      print('Unknown error: $e');
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
}
