import 'package:firebase_auth/firebase_auth.dart';

String mapFirebaseAuthErrorToMessage(FirebaseAuthException e) {
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