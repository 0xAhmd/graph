part of 'search_cubit.dart';

@immutable
sealed class SearchState {}

final class SearchInitial extends SearchState {}

final class SearchLoading extends SearchState {}

final class SearchLoaded extends SearchState {
  final List<ProfileUserEntity> profiles;

  SearchLoaded({required this.profiles});
}

final class SearchError extends SearchState {
  final String errMessage;

  SearchError({required this.errMessage});
}
