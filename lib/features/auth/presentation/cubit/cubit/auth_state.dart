part of 'auth_cubit.dart';

@immutable
sealed class AuthState {}

final class AuthInitial extends AuthState {}

final class AuthLoading extends AuthState {}

final class Authenticated extends AuthState {
  final AppUser user;

  Authenticated({required this.user});
}

final class AuthError extends AuthState {
  final String errMessage;

  AuthError({required this.errMessage});
}

final class UnAuthenticated extends AuthState {}
