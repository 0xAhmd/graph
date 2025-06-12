

String? validatePassword({required String password, required String email}) {
  if (password.isEmpty) return 'Password is required';
  if (password.length < 8) return 'Minimum 8 characters';
  if (!RegExp(r'[A-Z]').hasMatch(password)) return 'Needs 1 uppercase letter';
  if (!RegExp(r'[a-z]').hasMatch(password)) return 'Needs 1 lowercase letter';
  if (!RegExp(r'[0-9]').hasMatch(password)) return 'Needs 1 number';
  if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) {
    return 'Needs 1 special character';
  }

  final emailLocal = email.split('@').first;
  if (emailLocal.length > 2 && password.contains(emailLocal)) {
    return 'Cannot contain email parts';
  }

  return null;
}
