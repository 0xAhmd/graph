import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import '../../../domain/entities/app_user.dart';
import '../../../domain/repo/auth_repo.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepoContract repo;
  AppUser? _currentUser;
  AuthCubit(this.repo) : super(AuthInitial());

  void checkAuth() async {
    final AppUser? user = await repo.getCurrentUser();

    if (user != null) {
      _currentUser = user;
      emit(Authenticated(user: user));
    } else {
      emit(UnAuthenticated());
    }
  }

  AppUser? get currentUser => _currentUser;

  Future<void> login(String email, String password) async {
    try {
      final user = await repo.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (user != null) {
        _currentUser = user;
        emit(Authenticated(user: user));
      } else {
        emit(UnAuthenticated());
      }
    } catch (e) {
      emit(AuthError(errMessage: e.toString()));
      emit(UnAuthenticated());
    }
  }

  Future<void> register(String name, String email, String password) async {
    try {
      final user = await repo.registerWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
      );

      if (user != null) {
        _currentUser = user;
        emit(Authenticated(user: user));
      } else {
        emit(UnAuthenticated());
      }
    } catch (e) {
      emit(AuthError(errMessage: e.toString()));
      emit(UnAuthenticated());
    }
  }

  Future<void> logout() async {
    repo.logout();
    emit(UnAuthenticated());
  }

  Future<void> deleteAccount() async {
    try {
      emit(AuthLoading()); // Show loading state during deletion

      // Check if user is logged in
      if (_currentUser == null) {
        emit(AuthError(errMessage: 'No user logged in'));
        return;
      }

      // The repository handles everything:
      // 1. Deletes all user data from Firestore
      // 2. Deletes images from Supabase
      // 3. Deletes the Firebase Auth account
      await repo.deleteAccount();

      // Clear local state
      _currentUser = null;

      // Emit AccountDeleted instead of UnAuthenticated
      emit(AccountDeleted());
    } catch (e) {
      emit(AuthError(errMessage: e.toString()));
      // Don't emit UnAuthenticated here since deletion failed
      // Keep the current authenticated state so user can try again
      if (_currentUser != null) {
        emit(Authenticated(user: _currentUser!));
      }
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      emit(AuthLoading());
      final user = await repo.signInWithGoogle();
      if (user != null) {
        _currentUser = user;
        emit(Authenticated(user: user));
      } else {
        emit(UnAuthenticated());
      }
    } catch (e) {
      debugPrint(e.toString());
      emit(AuthError(errMessage: e.toString()));
      emit(UnAuthenticated());
    }
  }

  // Sign in with GitHub
  Future<void> signInWithGitHub() async {
    try {
      emit(AuthLoading());
      final user = await repo.signInWithGitHub();
      if (user != null) {
        _currentUser = user;
        emit(Authenticated(user: user));
      } else {
        emit(UnAuthenticated());
      }
    } catch (e) {
      debugPrint('GitHub sign-in error: $e');
      emit(AuthError(errMessage: e.toString()));
      emit(UnAuthenticated());
    }
  }
}
