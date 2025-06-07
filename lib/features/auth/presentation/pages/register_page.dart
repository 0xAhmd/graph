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

  // Password validation pattern
  final String _passwordPattern =
      r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$';

  void _submit() {
    final authCubit = context.read<AuthCubit>();

    if (_formKey.currentState!.validate()) {
      authCubit.registerWithEmailAndPassword(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: BlocListener<AuthCubit, AuthState>(
              listener: (context, state) {
                if (state is UnAuthenticated) {
                  // Registration successful → go to login
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Registration successful!')),
                  );
                  Navigator.pushReplacementNamed(context, LoginPage.routeName);
                }

                if (state is AuthError) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(state.errMessage)));
                }
              },
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.edit,
                      color: Theme.of(context).colorScheme.primary,
                      size: 90,
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
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 6),
                    CustomTextField(
                      controller: _emailController,
                      hintText: "Type your email",
                      isObscured: false,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email is required';
                        }
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
                      focusNode: _passwordFocusNode, // ✅ Now this works
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }
                        if (!RegExp(_passwordPattern).hasMatch(value)) {
                          return 'Use 8+ chars with upper and lowercase, number, special char';
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
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                right: 4,
                                left: 4,
                                top: 2,
                              ),
                              child: LinearProgressIndicator(
                                borderRadius: BorderRadius.circular(10),
                                value: (_passwordStrength.index + 1) / 4,
                                color: getStrengthColor(_passwordStrength),
                                backgroundColor: Colors.grey[300],
                                minHeight: 6,
                              ),
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
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    CustomButton(text: "Register", onTap: _submit),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Already a member ? ",
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 4),
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
