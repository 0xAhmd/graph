import '../../../profile/domain/entities/profile_user.dart';

abstract class SearchRepoContract {
  Future<List<ProfileUserEntity>> filter(String query);
}
