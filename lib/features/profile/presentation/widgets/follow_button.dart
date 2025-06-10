import 'package:flutter/material.dart';

class FollowButton extends StatelessWidget {
  const FollowButton({super.key, this.onTap, required this.isFollowing});
  final void Function()? onTap;
  final bool isFollowing;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 25, left: 25, bottom: 25, top: 4),
        padding: const EdgeInsets.all(10),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isFollowing
              ? Theme.of(context).colorScheme.primary
              : Colors.blue,
        ),
        child: MaterialButton(
          onPressed: onTap,
          child: Text(
            isFollowing ? 'Unfollow' : 'Follow',
            style: TextStyle(
              fontSize: 17,
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
        ),
      ),
    );
  }
}
