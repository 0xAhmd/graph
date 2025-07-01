import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final bool isObscured;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final FocusNode? focusNode;
  final bool enabled;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.isObscured,
    this.validator,
    this.onChanged,
    this.focusNode,
    this.enabled = true,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isObscured;
  }

  void _toggleObscure() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 4),
      child: TextFormField(
        style: TextStyle(
          color: widget.enabled
              ? Theme.of(context).colorScheme.inversePrimary
              : Theme.of(context).colorScheme.inversePrimary.withOpacity(0.5),
        ),
        focusNode: widget.focusNode,
        controller: widget.controller,
        obscureText: _obscureText,
        validator: widget.validator,
        onChanged: widget.onChanged,
        enabled: widget.enabled,
        decoration: InputDecoration(
          hintText: widget.hintText,
          fillColor: widget.enabled
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
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.tertiary.withOpacity(0.5),
            ),
          ),
          suffixIcon: widget.isObscured
              ? IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility : Icons.visibility_off,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: _toggleObscure,
                )
              : null,
        ),
      ),
    );
  }
}
