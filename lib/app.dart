import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ig_mate/core/themes/light_mode.dart';
import 'package:ig_mate/features/auth/data/repo/firebase_auth_repo.dart';
import 'package:ig_mate/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:ig_mate/features/auth/presentation/pages/login_page.dart';
import 'package:ig_mate/features/auth/presentation/pages/register_page.dart';
import 'package:ig_mate/features/posts/presentation/pages/home_page.dart';

class MyApp extends StatelessWidget {
  final authRepo = FirebaseAuthRepo();
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthCubit>(
      create: (context) => AuthCubit(repo: authRepo)..checkUserAuthenticated(),
      child: Builder(
        builder: (context) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: lightMode.copyWith(
              textTheme: GoogleFonts.poppinsTextTheme(),
            ),
            routes: {
              LoginPage.routeName: (context) => const LoginPage(),
              RegisterPage.routeName: (context) => const RegisterPage(),
              HomePage.routeName: (context) => const HomePage(),
            },
            home: BlocConsumer<AuthCubit, AuthState>(
              builder: (context, state) {
                if (state is UnAuthenticated) {
                  return const LoginPage();
                }

                if (state is Authenticated) {
                  return const HomePage();
                }

                if (state is AuthLoading) {
                  return const Scaffold(
                    body: Center(child: CupertinoActivityIndicator()),
                  );
                }

                return const Scaffold(
                  body: Center(child: Text('Unknown state')),
                );
              },
              listener: (context, state) {
                if (state is AuthError) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(state.errMessage)));
                }
              },
            ),
          );
        },
      ),
    );
  }
}
