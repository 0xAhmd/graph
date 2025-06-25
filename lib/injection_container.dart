import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/auth/data/repo/firebase_auth_repo.dart';
import 'features/posts/data/repo/post_repo.dart';
import 'features/profile/data/repo/profile_user_repo.dart';
import 'features/search/data/repo/search_repo.dart';
import 'features/private/data/repo/privacy_repo_impl.dart';
import 'features/private/data/repo/follow_request_repo_impl.dart';
import 'features/chat/data/chat_repo.dart';
import 'features/comments/data/repo/comment_repo.dart';
import 'features/stories/data/repo/store_repo_impl.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // Repositories
  sl.registerLazySingleton(() => FirebaseAuthRepo());
  sl.registerLazySingleton(() => PostRepo());
  sl.registerLazySingleton(() => ProfileUserRepo());
  sl.registerLazySingleton(() => SearchRepo());
  sl.registerLazySingleton(() => PrivacyRepo());
  sl.registerLazySingleton(() => FollowRequestRepo());
  sl.registerLazySingleton(() => FirebaseChatRepo());
  sl.registerLazySingleton(() => CommentRepo());
  sl.registerLazySingleton(
    () => StoriesRepositoryImpl(
      firestore: FirebaseFirestore.instance,
      supabase: Supabase.instance.client,
    ),
  );
}
