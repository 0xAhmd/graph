// lib/features/private/presentation/widgets/follow_request_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:ig_mate/features/private/domain/entities/follow_request.dart';
import 'package:ig_mate/features/profile/domain/entities/profile_user.dart';
import 'package:ig_mate/features/profile/presentation/widgets/profile_image_viewer.dart';

class FollowRequestCard extends StatelessWidget {
  final FollowRequestEntity request;
  final ProfileUserEntity? userProfile;
  final bool isIncoming;
  final bool isLoading;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onCancel;
  final VoidCallback? onUserTap;

  const FollowRequestCard({
    super.key,
    required this.request,
    this.userProfile,
    required this.isIncoming,
    this.isLoading = false,
    this.onAccept,
    this.onDecline,
    this.onCancel,
    this.onUserTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Profile Image
            GestureDetector(
              onTap: onUserTap,
              child: ProfileImageViewer(
                imageUrl: userProfile?.profileImgUrl ?? '',
                size: 50,
                heroTag: 'request-${request.id}',
              ),
            ),
            const SizedBox(width: 12),
            
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userProfile?.name ?? 'Loading...',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userProfile?.email ?? '',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(request.createdAt),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            // Action Buttons
            if (isIncoming) ...[
              _buildIncomingActions(),
            ] else ...[
              _buildOutgoingActions(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIncomingActions() {
    if (isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CupertinoActivityIndicator(),
      );
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Decline Button
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            onPressed: onDecline,
            icon: const Icon(Icons.close, color: Colors.red),
            iconSize: 20,
            constraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Accept Button
        Container(
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            onPressed: onAccept,
            icon: const Icon(Icons.check, color: Colors.white),
            iconSize: 20,
            constraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOutgoingActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(request.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getStatusColor(request.status).withOpacity(0.3),
            ),
          ),
          child: Text(
            _getStatusText(request.status),
            style: TextStyle(
              color: _getStatusColor(request.status),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (request.status == FollowRequestStatus.pending) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Color _getStatusColor(FollowRequestStatus status) {
    switch (status) {
      case FollowRequestStatus.pending:
        return Colors.orange;
      case FollowRequestStatus.accepted:
        return Colors.green;
      case FollowRequestStatus.declined:
        return Colors.red;
    }
  }

  String _getStatusText(FollowRequestStatus status) {
    switch (status) {
      case FollowRequestStatus.pending:
        return 'Pending';
      case FollowRequestStatus.accepted:
        return 'Accepted';
      case FollowRequestStatus.declined:
        return 'Declined';
    }
  }
}
