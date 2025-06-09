import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ig_mate/features/auth/presentation/cubit/cubit/auth_cubit.dart';
import 'package:ig_mate/features/auth/presentation/widgets/custom_btn.dart';
import 'package:ig_mate/features/auth/presentation/widgets/custom_text_field.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, required this.onTap});
  final void Function()? onTap;
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  void register() {
    final String name = _nameController.text;
    final String email = _emailController.text;
    final String password = _passwordController.text;
    final String passwordConfirm = _passwordControllerConfirm.text;
    final authCubit = context.read<AuthCubit>();

    if (name.isNotEmpty &&
        email.isNotEmpty &&
        password.isNotEmpty &&
        passwordConfirm.isNotEmpty) {
      if (password == passwordConfirm) {
        authCubit.register(name, email, password);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please make sure the password matches")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill out all the fields")),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordControllerConfirm.dispose();
    super.dispose();
  }

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordControllerConfirm =
      TextEditingController();
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
              "Let's create an account for you..",
              style: TextStyle(
                fontSize: 17,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _nameController,
              hintText: "Type your name",
              isObscured: false,
            ),
            const SizedBox(height: 6),
            CustomTextField(
              controller: _emailController,
              hintText: "Type your Email",
              isObscured: false,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _passwordController,
              hintText: "Type your Password",
              isObscured: true,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _passwordControllerConfirm,
              hintText: "Confirm Your Password",
              isObscured: false,
            ),
            const SizedBox(height: 8),
            CustomButton(text: 'Register', onTap: register),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Not a member?", style: TextStyle(fontSize: 16)),
                GestureDetector(
                  onTap: widget.onTap,
                  child: Text(
                    " Login Now",
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
