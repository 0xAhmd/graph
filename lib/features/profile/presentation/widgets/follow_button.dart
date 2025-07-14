// lib/features/profile/presentation/widgets/follow_button.dart

import 'package:flutter/material.dart';

enum FollowButtonState {
  follow, // Can follow directly (public profile)
  following, // Already following
  requestSent, // Request pending
  sendRequest, // Send follow request (private profile)
}

class FollowButton extends StatelessWidget {
  const FollowButton({
    super.key,
    this.onTap,
    required this.followButtonState,
    this.isLoading = false,
  });

  final void Function()? onTap;
  final FollowButtonState followButtonState;
  final bool isLoading;

  String get _buttonText {
    switch (followButtonState) {
      case FollowButtonState.follow:
        return 'Follow';
      case FollowButtonState.following:
        return 'Following';
      case FollowButtonState.requestSent:
        return 'Requested';
      case FollowButtonState.sendRequest:
        return 'Follow';
    }
  }

  Color _getButtonColor(BuildContext context) {
    switch (followButtonState) {
      case FollowButtonState.follow:
      case FollowButtonState.sendRequest:
        return Colors.blue;
      case FollowButtonState.following:
        return Theme.of(context).colorScheme.primary;
      case FollowButtonState.requestSent:
        return Colors.grey;
    }
  }

  IconData? get _buttonIcon {
    switch (followButtonState) {
      case FollowButtonState.follow:
      case FollowButtonState.sendRequest:
        return Icons.person_add;
      case FollowButtonState.following:
        return Icons.check;
      case FollowButtonState.requestSent:
        return Icons.hourglass_empty;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(10),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: _getButtonColor(context),
        ),
        child: MaterialButton(
          onPressed: isLoading ? null : onTap,
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_buttonIcon != null) ...[
                      Icon(
                        _buttonIcon,
                        color: Theme.of(context).colorScheme.inversePrimary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      _buttonText,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// Helper extension to determine button state
extension FollowButtonStateHelper on FollowButtonState {
  static FollowButtonState determineState({
    required bool isFollowing,
    required bool isPrivate,
    required bool hasRequestSent,
  }) {
    if (isFollowing) {
      return FollowButtonState.following;
    } else if (hasRequestSent) {
      return FollowButtonState.requestSent;
    } else if (isPrivate) {
      return FollowButtonState.sendRequest;
    } else {
      return FollowButtonState.follow;
    }
  }
}
