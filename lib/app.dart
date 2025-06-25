import 'package:ig_mate/features/profile/presentation/pages/index.dart';
import 'index.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<StoriesCubit>()),
        BlocProvider(create: (_) => sl<FollowRequestCubit>()),
        BlocProvider(create: (_) => sl<PrivacyCubit>()),
        BlocProvider(create: (_) => sl<ChatCubit>()),
        BlocProvider(create: (_) => sl<CommentCubit>()),
        BlocProvider(create: (_) => sl<AuthCubit>()..checkAuth()),
        BlocProvider(create: (_) => sl<SearchCubit>()),
        BlocProvider(create: (_) => sl<ProfileCubit>()),
        BlocProvider(create: (_) => sl<PostCubit>()),
        BlocProvider(create: (_) => sl<ThemeCubit>()),
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
