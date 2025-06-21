import 'package:flutter/material.dart';
import 'package:ig_mate/features/stories/domain/entities/story.dart';
import 'package:cached_network_image/cached_network_image.dart';

class StoryContentWidget extends StatelessWidget {
  final StoryEntity story;

  const StoryContentWidget({
    super.key,
    required this.story,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: _buildStoryContent(),
    );
  }

  Widget _buildStoryContent() {
    if (story.isTextOnly) {
      return _buildTextOnlyStory();
    } else if (story.isImageOnly) {
      return _buildImageOnlyStory();
    } else if (story.isImageWithText) {
      return _buildImageWithTextStory();
    } else {
      // Fallback for empty stories
      return _buildEmptyStory();
    }
  }

  Widget _buildTextOnlyStory() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Text(
          story.content!,
          style: TextStyle(
            color: story.textColor != null
                ? _getColorFromHex(story.textColor!)
                : Colors.white,
            fontSize: story.fontSize ?? 28,
            fontWeight: _getFontWeight(story.fontWeight),
            height: 1.3,
            shadows: [
              Shadow(
                offset: const Offset(1, 1),
                blurRadius: 3,
                color: Colors.black.withOpacity(0.5),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildImageOnlyStory() {
    return CachedNetworkImage(
      imageUrl: story.imageUrl!,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      placeholder: (context, url) => Container(
        color: Colors.grey[900],
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[900],
        child: const Center(
          child: Icon(
            Icons.error_outline,
            color: Colors.white,
            size: 48,
          ),
        ),
      ),
    );
  }

  Widget _buildImageWithTextStory() {
    return Stack(
      children: [
        // Background image
        CachedNetworkImage(
          imageUrl: story.imageUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          placeholder: (context, url) => Container(
            color: Colors.grey[900],
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[900],
            child: const Center(
              child: Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
        ),
        
        // Overlay gradient for better text readability
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),
        
        // Text overlay
        Positioned.fill(
          child: Container(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  story.content!,
                  style: TextStyle(
                    color: story.textColor != null
                        ? _getColorFromHex(story.textColor!)
                        : Colors.white,
                    fontSize: story.fontSize ?? 20,
                    fontWeight: _getFontWeight(story.fontWeight),
                    height: 1.3,
                    shadows: [
                      Shadow(
                        offset: const Offset(1, 1),
                        blurRadius: 2,
                        color: Colors.black.withOpacity(0.8),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyStory() {
    return Container(
      color: Colors.grey[900],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              color: Colors.white54,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'No content available',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  FontWeight _getFontWeight(String? fontWeight) {
    switch (fontWeight?.toLowerCase()) {
      case 'thin':
        return FontWeight.w100;
      case 'extralight':
        return FontWeight.w200;
      case 'light':
        return FontWeight.w300;
      case 'normal':
      case 'regular':
        return FontWeight.w400;
      case 'medium':
        return FontWeight.w500;
      case 'semibold':
        return FontWeight.w600;
      case 'bold':
        return FontWeight.w700;
      case 'extrabold':
        return FontWeight.w800;
      case 'black':
        return FontWeight.w900;
      default:
        return FontWeight.w500;
    }
  }

  Color _getColorFromHex(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.white; // Default color if parsing fails
    }
  }
}