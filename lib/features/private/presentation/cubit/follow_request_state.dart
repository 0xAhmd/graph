part of 'follow_request_cubit.dart';

abstract class FollowRequestState extends Equatable {
  const FollowRequestState();

  @override
  List<Object> get props => [];
}

class FollowRequestInitial extends FollowRequestState {}

class FollowRequestLoading extends FollowRequestState {}

class FollowRequestLoaded extends FollowRequestState {
  final List<FollowRequestEntity> incomingRequests;
  final List<FollowRequestEntity> outgoingRequests;
  final int incomingCount;

  const FollowRequestLoaded({
    required this.incomingRequests,
    required this.outgoingRequests,
    required this.incomingCount,
  });

  @override
  List<Object> get props => [incomingRequests, outgoingRequests, incomingCount];
}

class FollowRequestError extends FollowRequestState {
  final String message;

  const FollowRequestError({required this.message});

  @override
  List<Object> get props => [message];
}

class FollowRequestActionLoading extends FollowRequestState {
  final String requestId;

  const FollowRequestActionLoading({required this.requestId});

  @override
  List<Object> get props => [requestId];
}
