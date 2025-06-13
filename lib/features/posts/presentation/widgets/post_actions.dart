import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/post_entity.dart';

class PostActions extends StatelessWidget {
  final Post post;
  final bool isLiked;
  final int likeCount;
  final int commentCount;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final DateTime timeStamp;

  const PostActions({
    super.key,
    required this.post,
    required this.isLiked,
    required this.likeCount,
    required this.commentCount,
    required this.onLike,
    required this.onComment,
    required this.timeStamp,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onLike,
                child: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked
                      ? Colors.red
                      : Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Text(
            likeCount.toString(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
          const SizedBox(width: 20),
          GestureDetector(onTap: onComment, child: const Icon(Icons.comment)),
          const SizedBox(width: 10),
          Text(
            commentCount.toString(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
          const Spacer(),
          Text(
            DateFormat('MMM d, yyyy • h:mm a').format(timeStamp),
            style: TextStyle(
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
        ],
      ),
    );
  }
}
