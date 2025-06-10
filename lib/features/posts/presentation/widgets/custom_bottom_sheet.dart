import 'package:flutter/material.dart';

class CustomBottomSheet extends StatefulWidget {
  const CustomBottomSheet({
    super.key,
    required this.controller,
    required this.onPost,
    this.title = 'New Comment',
    this.hintText = 'Add a comment...',
    this.buttonLabel = 'POST',
  });

  final TextEditingController controller;
  final void Function(String) onPost;
  final String title;
  final String hintText;
  final String buttonLabel;

  @override
  State<CustomBottomSheet> createState() => _CustomBottomSheetState();
}

class _CustomBottomSheetState extends State<CustomBottomSheet> {
  static const int maxChars = 5000;
  static const int warningThreshold = 4500;

  String currentText = '';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {
      currentText = widget.controller.text;
    });
  }

  bool get isTooLong => currentText.length > maxChars;
  bool get isNearLimit => currentText.length > warningThreshold;

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.inversePrimary,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                style: TextStyle(color: theme.inversePrimary),
                maxLength: maxChars,
                controller: widget.controller,
                autofocus: true,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  filled: true,
                  fillColor: theme.secondary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  counterText: '', // hide default counter
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${currentText.length} / $maxChars',
                  style: TextStyle(
                    color: isTooLong
                        ? Colors.red
                        : isNearLimit
                        ? Colors.orange
                        : theme.primary,
                    fontWeight: isTooLong || isNearLimit
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
              if (isTooLong)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Your comment is too long! Please shorten it.',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: (currentText.trim().isNotEmpty && !isTooLong)
                    ? () {
                        widget.onPost(currentText.trim());
                        Navigator.pop(context);
                      }
                    : null,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: (currentText.trim().isNotEmpty && !isTooLong)
                        ? Colors.lightBlueAccent
                        : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.send,
                        color: (currentText.trim().isNotEmpty && !isTooLong)
                            ? Colors.white
                            : Colors.white54,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.buttonLabel,
                        style: TextStyle(
                          color: (currentText.trim().isNotEmpty && !isTooLong)
                              ? Colors.white
                              : Colors.white54,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
