
import 'package:flutter/material.dart';

enum PasswordStrength { weak, medium, strong, veryStrong }

PasswordStrength getPasswordStrength(String password) {
  int strength = 0;

  if (password.length >= 8) strength++;
  if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
  if (RegExp(r'[0-9]').hasMatch(password)) strength++;
  if (RegExp(r'[!@#\$&*~]').hasMatch(password)) strength++;

  if (strength <= 1) return PasswordStrength.weak;
  if (strength == 2) return PasswordStrength.medium;
  if (strength == 3) return PasswordStrength.strong;
  return PasswordStrength.veryStrong;
}

Color getStrengthColor(PasswordStrength strength) {
  switch (strength) {
    case PasswordStrength.weak:
      return Colors.red;
    case PasswordStrength.medium:
      return Colors.orange;
    case PasswordStrength.strong:
      return Colors.blue;
    case PasswordStrength.veryStrong:
      return Colors.green;
  }
}

String getStrengthLabel(PasswordStrength strength) {
  switch (strength) {
    case PasswordStrength.weak:
      return 'Weak';
    case PasswordStrength.medium:
      return 'Medium';
    case PasswordStrength.strong:
      return 'Strong';
    case PasswordStrength.veryStrong:
      return 'Very Strong';
  }
}
