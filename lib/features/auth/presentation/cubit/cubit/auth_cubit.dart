import 'package:bloc/bloc.dart';
import '../../../domain/entities/app_user.dart';
import '../../../domain/repo/auth_repo.dart';
import 'package:meta/meta.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepo repo;
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



  Future<void> logout () async{
    repo.logout();
    emit(UnAuthenticated());
  }
}
