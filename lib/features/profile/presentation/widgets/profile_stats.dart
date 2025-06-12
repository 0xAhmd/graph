import 'package:flutter/material.dart';

class ProfileStats extends StatelessWidget {
  const ProfileStats({
    super.key,
    required this.postCount,
    required this.followersCount,
    required this.followingCount,
    required this.onTap,
  });
  final int postCount;
  final int followersCount;
  final int followingCount;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            child: Column(
              children: [
                Text(
                  postCount.toString(),
                  style: TextStyle(
                    fontSize: 22,

                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
                Text(
                  "Posts",
                  style: TextStyle(
                    fontSize: 16,

                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(
            width: 100,
            child: Column(
              children: [
                Text(
                  followersCount.toString(),
                  style: TextStyle(
                    fontSize: 22,

                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
                Text(
                  "Followers",
                  style: TextStyle(
                    fontSize: 16,

                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 100,
            child: Column(
              children: [
                Text(
                  followingCount.toString(),
                  style: TextStyle(
                    fontSize: 22,

                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
                Text(
                  "Following",
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
