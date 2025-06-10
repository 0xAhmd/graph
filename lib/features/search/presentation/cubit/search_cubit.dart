import 'package:bloc/bloc.dart';
import '../../../profile/domain/entities/profile_user.dart';
import '../../data/repo/search_repo.dart';
import 'package:meta/meta.dart';

part 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  final SearchRepo searchRepo;
  SearchCubit(this.searchRepo) : super(SearchInitial());

  Future<void> filter(String query) async {
    if (query.isEmpty) {
      emit(SearchInitial());
      return;
    }

    try {
      emit(SearchLoading());
      final users = await searchRepo.filter(query);
      emit(SearchLoaded(profiles: users));
    } catch (e) {
      emit(SearchError(errMessage: "error: $e"));
    }
  }
}
