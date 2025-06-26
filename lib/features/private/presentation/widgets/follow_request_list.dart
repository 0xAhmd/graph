// Extracted widget for the requests list
import 'package:ig_mate/features/private/domain/entities/follow_request.dart';
import 'package:ig_mate/features/private/presentation/widgets/empty.dart';
import 'package:ig_mate/features/private/presentation/widgets/follow_request_card.dart';
import 'package:ig_mate/features/profile/domain/entities/profile_user.dart';
import 'package:ig_mate/index.dart';

class FollowRequestsList extends StatelessWidget {
  final List<FollowRequestEntity> requests;
  final bool isIncoming;
  final Map<String, ProfileUserEntity> userProfiles;
  final Function(String) onLoadUserProfile;
  final VoidCallback onRefresh;
  final Function(FollowRequestEntity)? onAccept;
  final Function(FollowRequestEntity)? onDecline;
  final Function(FollowRequestEntity)? onCancel;
  final Function(String) onUserTap;
  final String currentUserId;

  const FollowRequestsList({
    super.key,
    required this.requests,
    required this.isIncoming,
    required this.userProfiles,
    required this.onLoadUserProfile,
    required this.onRefresh,
    this.onAccept,
    this.onDecline,
    this.onCancel,
    required this.onUserTap,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return EmptyStateWidget(
        icon: isIncoming ? Icons.person_add_disabled : Icons.send,
        title: isIncoming ? 'No Follow Requests' : 'No Sent Requests',
        subtitle: isIncoming
            ? 'When people request to follow you, their requests will appear here.'
            : 'Follow requests you send to private accounts will appear here.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          final targetUserId = isIncoming
              ? request.fromUserId
              : request.toUserId;

          // Load user profile if not already loaded
          onLoadUserProfile(targetUserId);

          final userProfile = userProfiles[targetUserId];

          return BlocBuilder<FollowRequestCubit, FollowRequestState>(
            builder: (context, state) {
              final isLoading =
                  state is FollowRequestActionLoading &&
                  state.requestId == request.id;

              return FollowRequestCard(
                request: request,
                userProfile: userProfile,
                isIncoming: isIncoming,
                isLoading: isLoading,
                onAccept: isIncoming ? () => onAccept?.call(request) : null,
                onDecline: isIncoming ? () => onDecline?.call(request) : null,
                onCancel:
                    !isIncoming && request.status == FollowRequestStatus.pending
                    ? () => onCancel?.call(request)
                    : null,
                onUserTap: () => onUserTap(targetUserId),
              );
            },
          );
        },
      ),
    );
  }
}
