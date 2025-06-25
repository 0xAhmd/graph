import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ig_mate/features/auth/domain/repo/auth_repo.dart';
import 'package:ig_mate/features/chat/domain/repo/chat_repo_contract.dart';
import 'package:ig_mate/features/comments/domain/repo/comment_repo_interface.dart';
import 'package:ig_mate/features/posts/domain/repo/post_repo.dart';
import 'package:ig_mate/features/profile/domain/repo/follow_request_repo.dart';
import 'package:ig_mate/features/stories/domain/repo/story_repo_interface.dart';
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

import 'features/auth/presentation/cubit/cubit/auth_cubit.dart';
import 'features/posts/presentation/cubit/post_cubit.dart';
import 'features/profile/presentation/cubit/cubit/profile_cubit.dart';
import 'features/search/presentation/cubit/search_cubit.dart';
import 'features/private/presentation/cubit/privacy_cubit.dart';
import 'features/private/presentation/cubit/follow_request_cubit.dart';
import 'features/chat/presentation/cubit/chat_cubit.dart';
import 'features/comments/presentation/cubit/comment_cubit.dart';
import 'features/stories/presentation/cubit/story_cubit.dart';
import 'core/themes/theme_cubit.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // Repos
  sl.registerLazySingleton<AuthRepoContract>(() => FirebaseAuthRepo());
  sl.registerLazySingleton<PostRepoContract>(() => PostRepo());
  sl.registerLazySingleton(() => ProfileUserRepo());
  sl.registerLazySingleton(() => SearchRepo());
  sl.registerLazySingleton(() => PrivacyRepo());
  sl.registerLazySingleton<FollowRequestRepoContract>(
    () => FollowRequestRepo(),
  );
  sl.registerLazySingleton<ChatRepoContract>(() => FirebaseChatRepo());
  sl.registerLazySingleton<CommentRepoContract>(() => CommentRepo());
  sl.registerLazySingleton(
    () => StoriesRepositoryImpl(
      firestore: FirebaseFirestore.instance,
      supabase: Supabase.instance.client,
    ),
  );
  sl.registerLazySingleton<StoriesRepository>(
    () => StoriesRepositoryImpl(
      firestore: FirebaseFirestore.instance,
      supabase: Supabase.instance.client,
    ),
  );
  // Cubits
  sl.registerFactory(() => AuthCubit(sl<AuthRepoContract>()));
  sl.registerFactory(() => PostCubit(postRepo: sl()));
  sl.registerFactory(() => ProfileCubit(sl()));
  sl.registerFactory(() => SearchCubit(sl()));
  sl.registerFactory(() => PrivacyCubit(sl()));
  sl.registerFactory(() => FollowRequestCubit(sl<FollowRequestRepoContract>()));
  sl.registerFactory(() => ChatCubit(sl<ChatRepoContract>()));
  sl.registerFactory(
    () => CommentCubit(commentRepo: sl<CommentRepoContract>()),
  );
  sl.registerFactory(() => StoriesCubit(repository: sl<StoriesRepository>()));
  sl.registerLazySingleton(() => ThemeCubit());
}
