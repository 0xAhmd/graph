// lib/features/follow_requests/domain/repo/follow_request_repo.dart

import 'package:ig_mate/features/private/domain/entities/follow_request.dart';


abstract class FollowRequestRepoContract {
  // Send a follow request
  Future<void> sendFollowRequest({
    required String fromUserId,
    required String toUserId,
  });

  // Accept a follow request
  Future<void> acceptFollowRequest({
    required String requestId,
    required String fromUserId,
    required String toUserId,
  });

  // Decline a follow request
  Future<void> declineFollowRequest(String requestId);

  // Cancel a sent follow request
  Future<void> cancelFollowRequest({
    required String fromUserId,
    required String toUserId,
  });

  // Get all follow requests for a user (incoming)
  Future<List<FollowRequestEntity>> getIncomingFollowRequests(String userId);

  // Get all sent follow requests by a user (outgoing)
  Future<List<FollowRequestEntity>> getOutgoingFollowRequests(String userId);

  // Check if a follow request exists between two users
  Future<FollowRequestEntity?> getFollowRequestBetweenUsers({
    required String fromUserId,
    required String toUserId,
  });

  // Get pending follow requests count for badge
  Future<int> getIncomingFollowRequestsCount(String userId);

  // Stream of incoming follow requests for real-time updates
  Stream<List<FollowRequestEntity>> streamIncomingFollowRequests(String userId);

  // Stream of follow request count for badge
  Stream<int> streamIncomingFollowRequestsCount(String userId);

  // Delete all follow requests related to a user (for cleanup)
  Future<void> deleteAllUserFollowRequests(String userId);
}
