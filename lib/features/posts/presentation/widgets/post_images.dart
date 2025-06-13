import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PostImage extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onDoubleTap;
  final bool showHeart;
  final bool isLiked;

  const PostImage({
    super.key,
    required this.imageUrl,
    required this.onDoubleTap,
    required this.showHeart,
    required this.isLiked,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (kIsWeb)
          GestureDetector(
            onDoubleTap: onDoubleTap,
            child: Image.network(
              imageUrl,
              height: 450,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const SizedBox(
                height: 450,
                child: Center(child: Icon(Icons.error_outline, size: 50)),
              ),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return SizedBox(
                  height: 450,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
            ),
          )
        else
          GestureDetector(
            onDoubleTap: onDoubleTap,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              height: 450,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => const SizedBox(height: 450),
              errorWidget: (context, url, error) =>
                  const Icon(Icons.error_outline),
            ),
          ),
        AnimatedOpacity(
          opacity: showHeart ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: AnimatedScale(
            scale: showHeart ? 1.6 : 0.5,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.favorite,
              color: isLiked ? Colors.redAccent : Colors.white,
              size: 120,
              shadows: const [
                Shadow(
                  blurRadius: 20,
                  color: Colors.black54,
                  offset: Offset(0, 4),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
