import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../profile/domain/repo/follow_request_repo.dart';
import '../../domain/entities/follow_request.dart';

part 'follow_request_state.dart';

class FollowRequestCubit extends Cubit<FollowRequestState> {
  final FollowRequestRepoContract _followRequestRepo;

  FollowRequestCubit(this._followRequestRepo) : super(FollowRequestInitial());

  Future<void> loadFollowRequests(String userId) async {
    emit(FollowRequestLoading());
    try {
      final incomingRequests = await _followRequestRepo
          .getIncomingFollowRequests(userId);
      final outgoingRequests = await _followRequestRepo
          .getOutgoingFollowRequests(userId);
      final count = await _followRequestRepo.getIncomingFollowRequestsCount(
        userId,
      );

      emit(
        FollowRequestLoaded(
          incomingRequests: incomingRequests,
          outgoingRequests: outgoingRequests,
          incomingCount: count,
        ),
      );
    } catch (e) {

      emit(const FollowRequestError(message: 'Failed to load follow requests'));
    }
  }

  Future<void> sendFollowRequest({
    required String fromUserId,
    required String toUserId,
  }) async {
    try {
      await _followRequestRepo.sendFollowRequest(
        fromUserId: fromUserId,
        toUserId: toUserId,
      );

      // Reload data to reflect changes
      loadFollowRequests(fromUserId);
    } catch (e) {

      emit(const FollowRequestError(message: 'Failed to send follow request'));
    }
  }

  Future<void> acceptFollowRequest({
    required String requestId,
    required String fromUserId,
    required String toUserId,
  }) async {
    emit(FollowRequestActionLoading(requestId: requestId));
    try {
      await _followRequestRepo.acceptFollowRequest(
        requestId: requestId,
        fromUserId: fromUserId,
        toUserId: toUserId,
      );

      // Reload data to reflect changes
      loadFollowRequests(toUserId);
    } catch (e) {

      emit(const FollowRequestError(message: 'Failed to accept follow request'));
    }
  }

  Future<void> declineFollowRequest({
    required String requestId,
    required String userId,
  }) async {
    emit(FollowRequestActionLoading(requestId: requestId));
    try {
      await _followRequestRepo.declineFollowRequest(requestId);

      // Reload data to reflect changes
      loadFollowRequests(userId);
    } catch (e) {

      emit(const FollowRequestError(message: 'Failed to decline follow request'));
    }
  }

  Future<void> cancelFollowRequest({
    required String fromUserId,
    required String toUserId,
  }) async {
    try {
      await _followRequestRepo.cancelFollowRequest(
        fromUserId: fromUserId,
        toUserId: toUserId,
      );

      // Reload data to reflect changes
      loadFollowRequests(fromUserId);
    } catch (e) {

      emit(const FollowRequestError(message: 'Failed to cancel follow request'));
    }
  }

  Future<FollowRequestEntity?> getFollowRequestBetweenUsers({
    required String fromUserId,
    required String toUserId,
  }) async {
    try {
      return await _followRequestRepo.getFollowRequestBetweenUsers(
        fromUserId: fromUserId,
        toUserId: toUserId,
      );
    } catch (e) {

      return null;
    }
  }

  void streamIncomingRequests(String userId) {
    _followRequestRepo
        .streamIncomingFollowRequests(userId)
        .listen(
          (requests) {
            final currentState = state;
            if (currentState is FollowRequestLoaded) {
              emit(
                FollowRequestLoaded(
                  incomingRequests: requests,
                  outgoingRequests: currentState.outgoingRequests,
                  incomingCount: requests.length,
                ),
              );
            } else {
              emit(
                FollowRequestLoaded(
                  incomingRequests: requests,
                  outgoingRequests: [],
                  incomingCount: requests.length,
                ),
              );
            }
          },
          onError: (error) {

            emit(
              const FollowRequestError(message: 'Failed to stream follow requests'),
            );
          },
        );
  }

  Stream<int> streamIncomingRequestsCount(String userId) {
    return _followRequestRepo.streamIncomingFollowRequestsCount(userId);
  }
}
