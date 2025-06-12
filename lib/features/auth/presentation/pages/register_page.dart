import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ig_mate/core/utils/password_strength.dart';
import 'package:ig_mate/core/utils/password_validator.dart';
import 'package:ig_mate/core/utils/validators.dart';
import '../cubit/cubit/auth_cubit.dart';
import '../widgets/custom_btn.dart';
import '../widgets/custom_text_field.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, required this.onTap});
  final void Function()? onTap;
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordControllerConfirm =
      TextEditingController();

  PasswordStrength _passwordStrength = PasswordStrength.weak;
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void initState() {
    super.initState();
    // Add listeners to validate fields in real-time
    _nameController.addListener(_validateName);
    _emailController.addListener(_validateEmail);
    _passwordController.addListener(_validatePassword);
    _passwordControllerConfirm.addListener(_validateConfirmPassword);
  }

  void _validateName() {
    setState(() {
      final name = _nameController.text;
      if (name.isEmpty) {
        _nameError = 'Name is required';
      } else if (name.length < 2) {
        _nameError = 'Name must be at least 2 characters';
      } else if (hasDoubleSpaces(name)) {
        _nameError = 'Remove extra spaces';
      } else if (containsEmoji(name)) {
        _nameError = 'Emojis are not allowed';
      } else if (startsOrEndsWithSpace(name)) {
        _nameError = 'Remove leading/trailing spaces';
      } else {
        _nameError = null;
      }
    });
  }

  void _validateEmail() {
    setState(() {
      final email = _emailController.text;
      if (email.isEmpty) {
        _emailError = 'Email is required';
      } else if (!isValidEmail(email)) {
        _emailError = 'Enter a valid email';
      } else {
        _emailError = null;
      }
    });
  }

  void _validatePassword() {
    setState(() {
      final password = _passwordController.text;
      final email = _emailController.text;

      _passwordError = validatePassword(password: password, email: email);
      _passwordStrength = getPasswordStrength(password);

      // Re-validate confirm password when password changes
      if (_passwordControllerConfirm.text.isNotEmpty) {
        _validateConfirmPassword();
      }
    });
  }

  void _validateConfirmPassword() {
    setState(() {
      final password = _passwordController.text;
      final confirmPassword = _passwordControllerConfirm.text;

      if (confirmPassword.isEmpty) {
        _confirmPasswordError = 'Please confirm your password';
      } else if (password != confirmPassword) {
        _confirmPasswordError = 'Passwords do not match';
      } else {
        _confirmPasswordError = null;
      }
    });
  }

  bool get _isFormValid {
    return _nameError == null &&
        _emailError == null &&
        _passwordError == null &&
        _confirmPasswordError == null &&
        _nameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _passwordControllerConfirm.text.isNotEmpty;
  }

  void register() {
    // Validate all fields first
    _validateName();
    _validateEmail();
    _validatePassword();
    _validateConfirmPassword();

    if (_isFormValid) {
      final String name = _nameController.text.trim();
      final String email = _emailController.text.trim();
      final String password = _passwordController.text;
      final authCubit = context.read<AuthCubit>();

      authCubit.register(name, email, password);
    } else {
      Fluttertoast.showToast(
        msg: "please end all fields before proceeding",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red, // or Colors.green, etc.
        textColor: Colors.white,
      );
    }
  }

  Widget _buildPasswordStrengthIndicator() {
    if (_passwordController.text.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Password strength: ',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              Text(
                getStrengthLabel(_passwordStrength),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: getStrengthColor(_passwordStrength),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(right: 25.0),
            child: LinearProgressIndicator(
              value: (_passwordStrength.index + 1) / 4,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                getStrengthColor(_passwordStrength),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorText(String? error) {
    if (error == null) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 4),
        child: Text(
          error,
          textAlign: TextAlign.left,
          style: TextStyle(
            color: Theme.of(context).colorScheme.error,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordControllerConfirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
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

              // Name Field
              CustomTextField(
                controller: _nameController,
                hintText: "Type your name",
                isObscured: false,
              ),
              _buildErrorText(_nameError),
              const SizedBox(height: 6),

              // Email Field
              CustomTextField(
                controller: _emailController,
                hintText: "Type your Email",
                isObscured: false,
              ),
              _buildErrorText(_emailError),
              const SizedBox(height: 8),

              // Password Field
              CustomTextField(
                controller: _passwordController,
                hintText: "Type your Password",
                isObscured: true,
              ),
              _buildErrorText(_passwordError),
              _buildPasswordStrengthIndicator(),
              const SizedBox(height: 8),

              // Confirm Password Field
              CustomTextField(
                controller: _passwordControllerConfirm,
                hintText: "Confirm Your Password",
                isObscured: true,
              ),
              _buildErrorText(_confirmPasswordError),
              const SizedBox(height: 20),

              // Register Button
              CustomButton(text: 'Register', onTap: register),
              const SizedBox(height: 18),

              // Login Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already a member?",
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: widget.onTap,
                    child: Text(
                      " Login Now",
                      style: TextStyle(
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
