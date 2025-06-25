import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'injection_container.dart';

import 'core/themes/theme_cubit.dart';
import 'core/themes/light_mode.dart';
import 'core/themes/dark_mode.dart';

import 'features/comments/presentation/cubit/comment_cubit.dart';
import 'features/private/presentation/cubit/follow_request_cubit.dart';
import 'features/private/presentation/cubit/privacy_cubit.dart';
import 'features/stories/presentation/cubit/story_cubit.dart';
import 'features/chat/presentation/cubit/chat_cubit.dart';
import 'features/search/presentation/cubit/search_cubit.dart';
import 'features/auth/presentation/cubit/cubit/auth_cubit.dart';
import 'features/posts/presentation/cubit/post_cubit.dart';
import 'features/profile/presentation/cubit/cubit/profile_cubit.dart';

import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/auth_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'layout/constrained_scaffold.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => StoriesCubit(repository: sl())),
        BlocProvider(create: (_) => FollowRequestCubit(sl())),
        BlocProvider(create: (_) => PrivacyCubit(sl())),
        BlocProvider(create: (_) => ChatCubit(sl())),
        BlocProvider(create: (_) => CommentCubit(commentRepo: sl())),
        BlocProvider(create: (_) => AuthCubit(sl())..checkAuth()),
        BlocProvider(create: (_) => SearchCubit(sl())),
        BlocProvider(create: (_) => ProfileCubit(sl())),
        BlocProvider(create: (_) => PostCubit(postRepo: sl())),
        BlocProvider(create: (_) => ThemeCubit()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            themeMode: themeMode,
            theme: lightMode,
            darkTheme: darkMode,
            routes: {'/login': (context) => const LoginPage(onTap: null)},
            home: BlocConsumer<AuthCubit, AuthState>(
              builder: (context, state) {
                if (state is UnAuthenticated) return const AuthPage();
                if (state is Authenticated) return const HomePage();
                return const ConstrainedScaffold(
                  body: Center(child: CupertinoActivityIndicator()),
                );
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
