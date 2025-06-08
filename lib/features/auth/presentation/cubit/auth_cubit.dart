/*

the auth cubit will do this things

1. check if the user is authenticated
2. get current user
3. sign in with email and password
4. register with email and password
5. sign out 

 */

import 'package:bloc/bloc.dart';
import 'package:ig_mate/features/auth/domain/entities/app_user.dart';
import 'package:ig_mate/features/auth/domain/repo/auth_repo.dart';
import 'package:meta/meta.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepo repo;
  AppUser? _currentUser;
  AuthCubit({required this.repo}) : super(AuthInitial());

  // gating
  void checkUserAuthenticated() async {
    final AppUser? user = await repo.getCurrentUser();

    if (user != null) {
      _currentUser = user;
      emit(Authenticated(user));
    } else {
      emit(UnAuthenticated());
    }
  }

  // app user

  AppUser? get currentUser => _currentUser;

  // login with email and password

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      emit(AuthLoading());
      final user = await repo.signInWithEmailAndPassword(email, password);

      if (user != null) {
        _currentUser = user;
        emit(Authenticated(user));
      } else {
        emit(UnAuthenticated());
      }
    } catch (e) {
      emit(AuthError(errMessage: e.toString()));
      emit(UnAuthenticated());
    }
  }

  Future<void> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      emit(AuthLoading());
      final user = await repo.registerWithEmailAndPassword(
        email,
        password,
        name,
      );

      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(UnAuthenticated());
      }
    } catch (e) {
      // If the error is already a string message, emit it directly,
      // otherwise fallback to generic message.
      final errorMessage = (e is String) ? e : "An unknown error occurred.";
      emit(AuthError(errMessage: errorMessage));
      emit(UnAuthenticated());
    }
  }

  Future<void> logout() async {
    repo.logout();
    emit(UnAuthenticated());
  }

  void emitUnAuthenticated() => emit(UnAuthenticated());
}
