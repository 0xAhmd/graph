import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool isObscured;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final FocusNode? focusNode; // ✅ Add this line

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.isObscured,
    this.validator,
    this.onChanged,
    this.focusNode, // ✅ Add this line
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 4),
      child: TextFormField(
        focusNode: focusNode, // ✅ Use it here
        controller: controller,
        obscureText: isObscured,
        validator: validator,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          fillColor: Theme.of(context).colorScheme.secondary,
          filled: true,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.tertiary,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
