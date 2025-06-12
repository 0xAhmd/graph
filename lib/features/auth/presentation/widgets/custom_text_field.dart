import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool isObscured;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final FocusNode? focusNode;
  final bool enabled; // ✅ Add enabled property

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.isObscured,
    this.validator,
    this.onChanged,
    this.focusNode,
    this.enabled = true, // ✅ Default to true
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 4),
      child: TextFormField(
        style: TextStyle(
          color: enabled
              ? Theme.of(context).colorScheme.inversePrimary
              : Theme.of(context).colorScheme.inversePrimary.withOpacity(0.5),
        ),
        focusNode: focusNode,
        controller: controller,
        obscureText: isObscured,
        validator: validator,
        onChanged: onChanged,
        enabled: enabled, // ✅ Use enabled property
        decoration: InputDecoration(
          hintText: hintText,
          fillColor: enabled
              ? Theme.of(context).colorScheme.secondary
              : Theme.of(context).colorScheme.secondary.withOpacity(0.5),
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
          disabledBorder: OutlineInputBorder(
            // ✅ Add disabled border
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.tertiary.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }
}
