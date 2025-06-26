// lib/features/chat/presentation/widgets/chat_user_tile.dart
import 'package:flutter/material.dart';

import '../../domain/entities/chat_user.dart';

class ChatUserTile extends StatelessWidget {
  final ChatUser user;
  final VoidCallback onTap;

  const ChatUserTile({super.key, required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.secondary,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundImage: user.profileImgUrl != null
                  ? NetworkImage(user.profileImgUrl!)
                  : null,
              child: user.profileImgUrl == null
                  ? Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ],
        ),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.email,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
        onTap: onTap,
        trailing: IconButton(
          onPressed: onTap,
          icon: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
