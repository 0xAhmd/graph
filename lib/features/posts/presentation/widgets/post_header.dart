import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ig_mate/features/profile/presentation/pages/profile_page.dart';
import '../../domain/entities/post_entity.dart';
import '../../../profile/domain/entities/profile_user.dart';

class PostHeader extends StatelessWidget {
  final Post post;
  final ProfileUserEntity? postUser;
  final bool isOwnPost;
  final bool isUserBlocked;
  final VoidCallback? onDeletePressed;
  final VoidCallback? onBlockPressed;
  final VoidCallback? onUnblockPressed;

  const PostHeader({
    super.key,
    required this.post,
    required this.postUser,
    required this.isOwnPost,
    required this.isUserBlocked,
    this.onDeletePressed,
    this.onBlockPressed,
    this.onUnblockPressed,
  });

  @override
  Widget build(BuildContext context) {
    // ...your header UI code here...
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        postUser?.profileImgUrl != null
            ? _buildProfileImage(context)
            : const Icon(Icons.person),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfilePage(uid: post.userId),
              ),
            );
          },
          child: Text(
            post.userName,
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
        ),
        // Show blocked indicator
        if (isUserBlocked)
          Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: const Text(
              'Blocked',
              style: TextStyle(
                color: Colors.red,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        const Spacer(),
        GestureDetector(
          onTap: () => showOptions(context),
          child: Icon(
            isOwnPost ? Icons.delete : Icons.more_vert,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    ); // Replace with actual header code
  }

  Widget _buildProfileImage(BuildContext context) {
    if (kIsWeb) {
      // Use Image.network for web
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfilePage(uid: post.userId),
            ),
          );
        },
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: postUser?.profileImgUrl != null
                ? DecorationImage(
                    image: NetworkImage(postUser!.profileImgUrl),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {
                      debugPrint('Image load error: $exception');
                    },
                  )
                : null,
          ),
          child: postUser?.profileImgUrl == null
              ? const Icon(Icons.person)
              : null,
        ),
      );
    } else {
      // Use CachedNetworkImage for mobile
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfilePage(uid: post.userId),
            ),
          );
        },
        child: CachedNetworkImage(
          imageBuilder: (context, imageProvider) => Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
            ),
          ),
          imageUrl: postUser!.profileImgUrl,
          errorWidget: (context, url, error) => const Icon(Icons.person),
        ),
      );
    }
  }

  void showOptions(BuildContext context) {
    if (isOwnPost) {
      // Show delete dialog for own posts
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            "Delete Post ?",
            style: TextStyle(
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                if (onDeletePressed != null) {
                  onDeletePressed!();
                }
                Navigator.of(context).pop();
              },
              child: Text(
                "Delete",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Show block/unblock options for other users
      showModalBottomSheet(
        context: context,
        builder: (context) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              if (isUserBlocked)
                ListTile(
                  leading: const Icon(Icons.block, color: Colors.red),
                  title: Text(
                    'Block ${post.userName}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    if (onBlockPressed != null) {
                      onBlockPressed!();
                    }
                  },
                )
              else
                ListTile(
                  leading: const Icon(Icons.block, color: Colors.green),
                  title: Text(
                    'Unblock ${post.userName}',
                    style: const TextStyle(color: Colors.green),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    if (onUnblockPressed != null) {
                      onUnblockPressed!();
                    }
                  },
                ),
              ListTile(
                leading: Icon(
                  Icons.cancel,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
                title: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );
    }
  }
}
