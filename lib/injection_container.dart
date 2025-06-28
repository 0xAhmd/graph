import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'features/auth/domain/repo/auth_repo.dart';
import 'features/chat/domain/repo/chat_repo_contract.dart';
import 'features/comments/domain/repo/comment_repo_interface.dart';
import 'features/posts/domain/repo/post_repo.dart';
import 'features/profile/domain/repo/follow_request_repo.dart';
import 'features/stories/domain/repo/story_repo_interface.dart';
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

final locator = GetIt.instance;

Future<void> initDependencies() async {
  // Repos
  locator.registerLazySingleton<AuthRepoContract>(() => FirebaseAuthRepo());
  locator.registerLazySingleton<PostRepoContract>(() => PostRepo());
  locator.registerLazySingleton(() => ProfileUserRepo());
  locator.registerLazySingleton(() => SearchRepo());
  locator.registerLazySingleton(() => PrivacyRepo());
  locator.registerLazySingleton<FollowRequestRepoContract>(
    () => FollowRequestRepo(),
  );
  locator.registerLazySingleton<ChatRepoContract>(() => FirebaseChatRepo());
  locator.registerLazySingleton<CommentRepoContract>(() => CommentRepo());
  locator.registerLazySingleton(
    () => StoriesRepositoryImpl(
      firestore: FirebaseFirestore.instance,
      supabase: Supabase.instance.client,
    ),
  );
  locator.registerLazySingleton<StoriesRepository>(
    () => StoriesRepositoryImpl(
      firestore: FirebaseFirestore.instance,
      supabase: Supabase.instance.client,
    ),
  );
  // Cubits
  locator.registerFactory(() => AuthCubit(locator<AuthRepoContract>()));
  locator.registerFactory(() => PostCubit(postRepo: locator()));
  locator.registerFactory(() => ProfileCubit(locator()));
  locator.registerFactory(() => SearchCubit(locator()));
  locator.registerFactory(() => PrivacyCubit(locator()));
  locator.registerFactory(
    () => FollowRequestCubit(locator<FollowRequestRepoContract>()),
  );
  locator.registerFactory(() => ChatCubit(locator<ChatRepoContract>()));
  locator.registerFactory(
    () => CommentCubit(commentRepo: locator<CommentRepoContract>()),
  );
  locator.registerFactory(
    () => StoriesCubit(repository: locator<StoriesRepository>()),
  );
  locator.registerLazySingleton(() => ThemeCubit());
}
