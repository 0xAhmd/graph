import 'package:flutter/material.dart';

class PrivacyToggle extends StatelessWidget {
  final bool isPrivate;
  final ValueChanged<bool> onChanged;
  final bool isLoading;

  const PrivacyToggle({
    super.key,
    required this.isPrivate,
    required this.onChanged,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          isPrivate ? Icons.lock : Icons.lock_open,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Private Account',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isPrivate
                    ? 'Only approved followers can see your posts'
                    : 'Anyone can see your posts and follow you',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ),
        if (isLoading)
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          Switch.adaptive(value: isPrivate, onChanged: onChanged),
      ],
    );
  }
}
