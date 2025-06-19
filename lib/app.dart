import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:ig_mate/core/themes/dark_mode.dart';
import 'package:ig_mate/core/themes/light_mode.dart';
import 'package:ig_mate/core/themes/theme_cubit.dart';
import 'package:ig_mate/features/auth/presentation/pages/login_page.dart';
import 'package:ig_mate/features/chat/data/chat_repo.dart';
import 'package:ig_mate/features/chat/presentation/cubit/chat_cubit.dart';
import 'package:ig_mate/features/search/data/repo/search_repo.dart';
import 'package:ig_mate/features/search/presentation/cubit/search_cubit.dart';
import 'package:ig_mate/layout/constrained_scaffold.dart';
import 'features/auth/data/repo/firebase_auth_repo.dart';
import 'features/auth/presentation/cubit/cubit/auth_cubit.dart';

import 'features/auth/presentation/pages/auth_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/posts/data/repo/post_repo.dart';
import 'features/posts/presentation/cubit/post_cubit.dart';
import 'features/profile/data/repo/profile_user_repo.dart';
import 'features/profile/presentation/cubit/cubit/profile_cubit.dart';

class MyApp extends StatelessWidget {
  final authRepo = FirebaseAuthRepo();
  final profileRepo = ProfileUserRepo();
  final postRepo = PostRepo();
  final searchRepo = SearchRepo();
  final chatRepo = FirebaseChatRepo();

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ChatCubit>(create: (context) => ChatCubit(chatRepo)),
        BlocProvider<AuthCubit>(
          create: (context) => AuthCubit(authRepo)..checkAuth(),
        ),
        BlocProvider<SearchCubit>(create: (context) => SearchCubit(searchRepo)),
        BlocProvider<ProfileCubit>(
          create: (context) => ProfileCubit(profileRepo),
        ),
        BlocProvider<PostCubit>(
          create: (context) => PostCubit(postRepo: postRepo),
        ),
        BlocProvider<ThemeCubit>(create: (context) => ThemeCubit()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            routes: {
              '/login': (context) => const LoginPage(onTap: null),
              // ... other routes
            },
            debugShowCheckedModeBanner: false,
            themeMode: themeMode,
            theme: lightMode,
            darkTheme: darkMode,
            home: BlocConsumer<AuthCubit, AuthState>(
              builder: (context, state) {
                debugPrint(state.toString());
                if (state is UnAuthenticated) {
                  return const AuthPage();
                } else if (state is Authenticated) {
                  return const HomePage();
                } else if (state is AuthLoading) {
                  return const ConstrainedScaffold(
                    body: Center(child: CupertinoActivityIndicator()),
                  );
                } else {
                  return const ConstrainedScaffold(
                    body: Center(child: CupertinoActivityIndicator()),
                  );
                }
              },
              listener: (context, state) {
                if (state is AuthError) {
                  Fluttertoast.showToast(
                    msg: state.errMessage,
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}
