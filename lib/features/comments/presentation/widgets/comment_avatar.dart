import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CommentAvatar extends StatelessWidget {
  final String userName;
  final String userId;
  final String? profileImageUrl; // Add profile image URL
  final Color color;
  final VoidCallback? onTap;

  const CommentAvatar({
    super.key,
    required this.userName,
    required this.userId,
    this.profileImageUrl, // Add this parameter
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 18,
        backgroundColor: color.withOpacity(0.2),
        // Show profile image if available, otherwise show initial
        child: profileImageUrl != null && profileImageUrl!.isNotEmpty
            ? ClipOval(
                child: CachedNetworkImage(
                  imageUrl: profileImageUrl!,
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                  errorWidget: (context, url, error) => _buildFallbackAvatar(),
                ),
              )
            : _buildFallbackAvatar(),
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    return Text(
      userName.isNotEmpty ? userName[0].toUpperCase() : '?',
      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18),
    );
  }
}
