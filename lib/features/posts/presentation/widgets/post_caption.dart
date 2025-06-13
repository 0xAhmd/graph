import 'package:flutter/material.dart';

class PostCaption extends StatelessWidget {
  final String userName;
  final String text;
  final bool isExpanded;
  final VoidCallback onToggleExpand;

  const PostCaption({
    super.key,
    required this.userName,
    required this.text,
    required this.isExpanded,
    required this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context) {
    final showSeeMore = text.length > 40 || text.split('\n').length > 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: onToggleExpand,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              textAlign: TextAlign.left,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: userName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                  ),
                  const TextSpan(text: '  '),
                  TextSpan(
                    text: text,
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                  ),
                ],
              ),
              maxLines: isExpanded ? null : 1,
              overflow: isExpanded
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
            ),/*  */
            if (showSeeMore)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onToggleExpand,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    isExpanded ? "See less" : "See more",
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
