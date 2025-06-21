import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../profile/domain/entities/profile_user.dart';
import '../../domain/repo/search_repo.dart';

class SearchRepo implements SearchRepoContract {
  @override
  Future<List<ProfileUserEntity>> filter(String query) async {
    try {
      final lowerQuery = query.toLowerCase();

      // Fetch a broader range (you can adjust limit as needed)
      final result = await FirebaseFirestore.instance.collection('users').get();

      return result.docs
          .map((doc) => ProfileUserEntity.fromJson(doc.data()))
          .where(
            (user) => user.name.toLowerCase().contains(lowerQuery),
          ) // client-side filtering
          .toList();
    } catch (e) {
      throw Exception("Error: $e");
    }
  }
}
