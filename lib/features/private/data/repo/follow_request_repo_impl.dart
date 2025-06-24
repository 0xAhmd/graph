// lib/features/follow_requests/data/repo/follow_request_repo.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:ig_mate/features/profile/domain/repo/follow_request_repo.dart';
import '../../domain/entities/follow_request.dart';

class FollowRequestRepo implements FollowRequestRepoContract {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> sendFollowRequest({
    required String fromUserId,
    required String toUserId,
  }) async {
    try {
      // Check if request already exists
      final existing = await getFollowRequestBetweenUsers(
        fromUserId: fromUserId,
        toUserId: toUserId,
      );

      if (existing != null) {
        throw Exception('Follow request already exists');
      }

      // Create new follow request
      final now = DateTime.now();
      final requestData = {
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'status': 'pending',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      await _firestore.collection('follow_requests').add(requestData);
      debugPrint('Follow request sent from $fromUserId to $toUserId');
    } catch (e) {
      debugPrint('Error sending follow request: $e');
      rethrow;
    }
  }

  @override
  Future<void> acceptFollowRequest({
    required String requestId,
    required String fromUserId,
    required String toUserId,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // Get user documents
        final fromUserRef = _firestore.collection('users').doc(fromUserId);
        final toUserRef = _firestore.collection('users').doc(toUserId);
        final requestRef = _firestore
            .collection('follow_requests')
            .doc(requestId);

        final fromUserDoc = await transaction.get(fromUserRef);
        final toUserDoc = await transaction.get(toUserRef);
        final requestDoc = await transaction.get(requestRef);

        if (!fromUserDoc.exists || !toUserDoc.exists || !requestDoc.exists) {
          throw Exception('User or request not found');
        }

        // Update followers and following
        final fromUserData = fromUserDoc.data()!;
        final toUserData = toUserDoc.data()!;

        final List<String> fromUserFollowing = List<String>.from(
          fromUserData['following'] ?? [],
        );
        final List<String> toUserFollowers = List<String>.from(
          toUserData['followers'] ?? [],
        );

        // Add to lists if not already present
        if (!fromUserFollowing.contains(toUserId)) {
          fromUserFollowing.add(toUserId);
        }
        if (!toUserFollowers.contains(fromUserId)) {
          toUserFollowers.add(fromUserId);
        }

        // Update users
        transaction.update(fromUserRef, {'following': fromUserFollowing});
        transaction.update(toUserRef, {'followers': toUserFollowers});

        // Update request status to accepted
        transaction.update(requestRef, {
          'status': 'accepted',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      debugPrint('Follow request accepted: $requestId');
    } catch (e) {
      debugPrint('Error accepting follow request: $e');
      rethrow;
    }
  }

  @override
  Future<void> declineFollowRequest(String requestId) async {
    try {
      await _firestore.collection('follow_requests').doc(requestId).update({
        'status': 'declined',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Follow request declined: $requestId');
    } catch (e) {
      debugPrint('Error declining follow request: $e');
      rethrow;
    }
  }

  @override
  Future<void> cancelFollowRequest({
    required String fromUserId,
    required String toUserId,
  }) async {
    try {
      final query = await _firestore
          .collection('follow_requests')
          .where('fromUserId', isEqualTo: fromUserId)
          .where('toUserId', isEqualTo: toUserId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.delete();
        debugPrint('Follow request cancelled from $fromUserId to $toUserId');
      }
    } catch (e) {
      debugPrint('Error cancelling follow request: $e');
      rethrow;
    }
  }

  @override
  Future<List<FollowRequestEntity>> getIncomingFollowRequests(
    String userId,
  ) async {
    try {
      final query = await _firestore
          .collection('follow_requests')
          .where('toUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        return FollowRequestEntity(
          id: doc.id,
          fromUserId: data['fromUserId'],
          toUserId: data['toUserId'],
          status: FollowRequestStatus.values.firstWhere(
            (status) => status.toString().split('.').last == data['status'],
          ),
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting incoming follow requests: $e');
      return [];
    }
  }

  @override
  Future<List<FollowRequestEntity>> getOutgoingFollowRequests(
    String userId,
  ) async {
    try {
      final query = await _firestore
          .collection('follow_requests')
          .where('fromUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        return FollowRequestEntity(
          id: doc.id,
          fromUserId: data['fromUserId'],
          toUserId: data['toUserId'],
          status: FollowRequestStatus.values.firstWhere(
            (status) => status.toString().split('.').last == data['status'],
          ),
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting outgoing follow requests: $e');
      return [];
    }
  }

  @override
  Future<FollowRequestEntity?> getFollowRequestBetweenUsers({
    required String fromUserId,
    required String toUserId,
  }) async {
    try {
      final query = await _firestore
          .collection('follow_requests')
          .where('fromUserId', isEqualTo: fromUserId)
          .where('toUserId', isEqualTo: toUserId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final data = doc.data();
        return FollowRequestEntity(
          id: doc.id,
          fromUserId: data['fromUserId'],
          toUserId: data['toUserId'],
          status: FollowRequestStatus.values.firstWhere(
            (status) => status.toString().split('.').last == data['status'],
          ),
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error getting follow request between users: $e');
      return null;
    }
  }

  @override
  Future<int> getIncomingFollowRequestsCount(String userId) async {
    try {
      final query = await _firestore
          .collection('follow_requests')
          .where('toUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      return query.docs.length;
    } catch (e) {
      debugPrint('Error getting follow requests count: $e');
      return 0;
    }
  }

  @override
  Stream<List<FollowRequestEntity>> streamIncomingFollowRequests(
    String userId,
  ) {
    return _firestore
        .collection('follow_requests')
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return FollowRequestEntity(
              id: doc.id,
              fromUserId: data['fromUserId'],
              toUserId: data['toUserId'],
              status: FollowRequestStatus.values.firstWhere(
                (status) => status.toString().split('.').last == data['status'],
              ),
              createdAt: (data['createdAt'] as Timestamp).toDate(),
              updatedAt: (data['updatedAt'] as Timestamp).toDate(),
            );
          }).toList();
        })
        .handleError((error) {
          debugPrint('Error streaming incoming follow requests: $error');
          return <FollowRequestEntity>[];
        });
  }

  @override
  Stream<int> streamIncomingFollowRequestsCount(String userId) {
    return _firestore
        .collection('follow_requests')
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length)
        .handleError((error) {
          debugPrint('Error streaming follow requests count: $error');
          return 0;
        });
  }

  @override
  Future<void> deleteAllUserFollowRequests(String userId) async {
    try {
      final batch = _firestore.batch();

      // Delete incoming requests
      final incomingQuery = await _firestore
          .collection('follow_requests')
          .where('toUserId', isEqualTo: userId)
          .get();

      // Delete outgoing requests
      final outgoingQuery = await _firestore
          .collection('follow_requests')
          .where('fromUserId', isEqualTo: userId)
          .get();

      for (final doc in [...incomingQuery.docs, ...outgoingQuery.docs]) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('All follow requests deleted for user: $userId');
    } catch (e) {
      debugPrint('Error deleting all user follow requests: $e');
      rethrow;
    }
  }
}
