import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../profile/domain/entities/profile_user.dart';
import '../../domain/repo/search_repo.dart';

class SearchRepo implements SearchRepoContract {
  @override
  Future<List<ProfileUserEntity>> filter(String query) async {
    try {
      final result = await FirebaseFirestore.instance
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      return result.docs
          .map((doc) => ProfileUserEntity.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception("Error: $e");
    }
  }
}
