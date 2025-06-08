import 'package:bloc/bloc.dart';
import 'package:ig_mate/features/auth/domain/entities/app_user.dart';
import 'package:ig_mate/features/auth/domain/repo/auth_repo.dart';
import 'package:meta/meta.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepo repo;
  AppUser? _currentUser;

  AuthCubit({required this.repo}) : super(AuthInitial());

  // 1. Gating
  void checkUserAuthenticated() async {
    final AppUser? user = await repo.getCurrentUser();
    if (user != null) {
      _currentUser = user;
      emit(Authenticated(user));
    } else {
      emit(UnAuthenticated());
    }
  }

  // 2. Get current user
  AppUser? get currentUser => _currentUser;

  // 3. Login
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      emit(AuthLoading());
      final user = await repo.signInWithEmailAndPassword(email, password);

      if (user != null) {
        _currentUser = user;
        emit(Authenticated(user));
      } else {
        emit(AuthError(errMessage: 'Login failed.'));
        emit(UnAuthenticated());
      }
    } catch (e) {
      emit(AuthError(errMessage: e.toString()));
      emit(UnAuthenticated());
    }
  }

  // 4. Register
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
        _currentUser = user;
        emit(Authenticated(user));
      } else {
        emit(AuthError(errMessage: 'Registration failed.'));
        emit(UnAuthenticated());
      }
    } catch (e) {
      final errorMessage = (e is String) ? e : 'An unknown error occurred.';
      emit(AuthError(errMessage: errorMessage));
      emit(UnAuthenticated());
    }
  }

  // 5. Logout
  Future<void> logout() async {
    await repo.logout();
    emit(UnAuthenticated());
  }

  void emitUnAuthenticated() => emit(UnAuthenticated());
}
