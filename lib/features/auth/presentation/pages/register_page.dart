import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ig_mate/core/helpers/password_strength.dart';
import 'package:ig_mate/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:ig_mate/features/auth/presentation/pages/login_page.dart';
import 'package:ig_mate/features/auth/presentation/widget/custom_btn.dart';
import 'package:ig_mate/features/auth/presentation/widget/custom_text_field.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  static const String routeName = '/register_page';

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordCnfrmController =
      TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  PasswordStrength _passwordStrength = PasswordStrength.weak;
  final FocusNode _passwordFocusNode = FocusNode();
  bool _isPasswordFocused = false;

  final String _passwordPattern =
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$&*~_])[A-Za-z\d!@#\$&*~_]{8,}$';

  void register() {
    final authCubit = context.read<AuthCubit>();

    final String email = _emailController.text;
    final String name = _nameController.text;
    final String pw = _passwordController.text;
    final String pwCnftm = _passwordCnfrmController.text;
    if (_formKey.currentState!.validate()) {
      if (pw == pwCnftm) {
        authCubit.registerWithEmailAndPassword(
          name: name,
          email: email,
          password: pw,
        );
      }

      debugPrint('All fields are valid, registration submitted.');
    }
  }

  @override
  void initState() {
    super.initState();
    _passwordFocusNode.addListener(() {
      setState(() {
        _isPasswordFocused = _passwordFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordCnfrmController.dispose();
    _nameController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Registration successful!')),
            );
            context.read<AuthCubit>().emitUnAuthenticated();
            Navigator.pushReplacementNamed(context, LoginPage.routeName);
          } else if (state is AuthError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errMessage)));
          }
        },
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.edit,
                      size: 90,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Welcome to your new favorite place",
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
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Name is required'
                          : null,
                    ),
                    const SizedBox(height: 6),
                    CustomTextField(
                      controller: _emailController,
                      hintText: "Type your email",
                      isObscured: false,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty)
                          return 'Email is required';
                        if (!RegExp(
                          r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 6),
                    CustomTextField(
                      controller: _passwordController,
                      hintText: "Type your Password",
                      isObscured: true,
                      focusNode: _passwordFocusNode,
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Password is required';
                        if (!RegExp(_passwordPattern).hasMatch(value)) {
                          return 'Use 8+ chars with upper/lowercase, number, symbol';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {
                          _passwordStrength = getPasswordStrength(value);
                        });
                      },
                    ),
                    if (_isPasswordFocused)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LinearProgressIndicator(
                              borderRadius: BorderRadius.circular(10),
                              value: (_passwordStrength.index + 1) / 4,
                              color: getStrengthColor(_passwordStrength),
                              backgroundColor: Colors.grey[300],
                              minHeight: 6,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Strength: ${getStrengthLabel(_passwordStrength)}',
                              style: TextStyle(
                                color: getStrengthColor(_passwordStrength),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 6),
                    CustomTextField(
                      controller: _passwordCnfrmController,
                      hintText: "Confirm your Password",
                      isObscured: true,
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Please confirm your password';
                        if (value != _passwordController.text)
                          return 'Passwords do not match';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    CustomButton(text: "Register", onTap: register),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Already a member? ",
                          style: TextStyle(fontSize: 16),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, LoginPage.routeName);
                          },
                          child: Text(
                            "Login",
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
            ),
          ),
        ),
      ),
    );
  }
}
