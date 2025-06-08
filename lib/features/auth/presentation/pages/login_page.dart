import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ig_mate/features/auth/presentation/cubit/cubit/auth_cubit.dart';
import 'package:ig_mate/features/auth/presentation/widgets/custom_btn.dart';
import 'package:ig_mate/features/auth/presentation/widgets/custom_text_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onTap});
  final void Function()? onTap;
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void login() {
    final String email = _emailController.text;
    final String password = _passwordController.text;
    final authCubit = context.read<AuthCubit>();

    if (email.isNotEmpty && password.isNotEmpty) {
      authCubit.login(email, password);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please Write both email and password correctly "),
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_open_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              "Welcome back, You have been missed",
              style: TextStyle(
                fontSize: 17,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _emailController,
              hintText: "Type your email",
              isObscured: false,
            ),
            const SizedBox(height: 6),
            CustomTextField(
              controller: _passwordController,
              hintText: "Type your password",
              isObscured: true,
            ),
            const SizedBox(height: 8),
            CustomButton(text: 'Login', onTap: login),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Not a member?", style: TextStyle(fontSize: 16)),
                GestureDetector(
                  onTap: widget.onTap,
                  child: Text(
                    " Register Now",
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
