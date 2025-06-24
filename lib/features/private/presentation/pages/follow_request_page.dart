// lib/features/private/presentation/pages/follow_request_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ig_mate/features/private/presentation/cubit/follow_request_cubit.dart';
import 'package:ig_mate/features/private/domain/entities/follow_request.dart';
import 'package:ig_mate/features/profile/domain/entities/profile_user.dart';
import 'package:ig_mate/features/profile/presentation/cubit/cubit/profile_cubit.dart';
import 'package:ig_mate/features/profile/presentation/widgets/profile_image_viewer.dart';
import 'package:fluttertoast/fluttertoast.dart';

class FollowRequestsPage extends StatefulWidget {
  final String userId;

  const FollowRequestsPage({super.key, required this.userId});

  @override
  State<FollowRequestsPage> createState() => _FollowRequestsPageState();
}

class _FollowRequestsPageState extends State<FollowRequestsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  Map<String, ProfileUserEntity> _userProfiles = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<FollowRequestCubit>().loadFollowRequests(widget.userId);

    // Start streaming for real-time updates
    context.read<FollowRequestCubit>().streamIncomingRequests(widget.userId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile(String userId) async {
    if (_userProfiles.containsKey(userId)) return;

    try {
      await context.read<ProfileCubit>().fetchUserProfile(userId);
      final state = context.read<ProfileCubit>().state;
      if (state is ProfileLoaded) {
        setState(() {
          _userProfiles[userId] = state.profileUserEntity;
        });
      }
    } catch (e) {
      // Handle error silently for now
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Follow Requests'),
        centerTitle: true,
        foregroundColor: Theme.of(context).colorScheme.primary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Received'),
            Tab(text: 'Sent'),
          ],
        ),
      ),
      body: BlocConsumer<FollowRequestCubit, FollowRequestState>(
        listener: (context, state) {
          if (state is FollowRequestError) {
            Fluttertoast.showToast(
              msg: state.message,
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.red,
              textColor: Colors.white,
            );
          }
        },
        builder: (context, state) {
          if (state is FollowRequestLoading) {
            return const Center(child: CupertinoActivityIndicator());
          }

          if (state is FollowRequestError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Something went wrong',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      context.read<FollowRequestCubit>().loadFollowRequests(
                        widget.userId,
                      );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is FollowRequestLoaded) {
            return TabBarView(
              controller: _tabController,
              children: [
                // Received Requests Tab
                _buildReceivedRequestsList(state.incomingRequests),
                // Sent Requests Tab
                _buildSentRequestsList(state.outgoingRequests),
              ],
            );
          }

          return const Center(child: Text('No requests to show'));
        },
      ),
    );
  }

  Widget _buildReceivedRequestsList(List<FollowRequestEntity> requests) {
    if (requests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.person_add_disabled,
        title: 'No Follow Requests',
        subtitle:
            'When people request to follow you, their requests will appear here.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<FollowRequestCubit>().loadFollowRequests(widget.userId);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          return _buildFollowRequestCard(request: request, isIncoming: true);
        },
      ),
    );
  }

  Widget _buildSentRequestsList(List<FollowRequestEntity> requests) {
    if (requests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.send,
        title: 'No Sent Requests',
        subtitle:
            'Follow requests you send to private accounts will appear here.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<FollowRequestCubit>().loadFollowRequests(widget.userId);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          return _buildFollowRequestCard(request: request, isIncoming: false);
        },
      ),
    );
  }

  Widget _buildFollowRequestCard({
    required FollowRequestEntity request,
    required bool isIncoming,
  }) {
    final targetUserId = isIncoming ? request.fromUserId : request.toUserId;

    // Load user profile if not already loaded
    _loadUserProfile(targetUserId);

    final userProfile = _userProfiles[targetUserId];

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
              onTap: () {
                // Navigate to user profile
                Navigator.pushNamed(
                  context,
                  '/profile',
                  arguments: targetUserId,
                );
              },
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
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(request.createdAt),
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),

            // Action Buttons
            if (isIncoming) ...[
              _buildActionButtons(request),
            ] else ...[
              _buildSentRequestActions(request),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(FollowRequestEntity request) {
    return BlocBuilder<FollowRequestCubit, FollowRequestState>(
      builder: (context, state) {
        final isLoading =
            state is FollowRequestActionLoading &&
            state.requestId == request.id;

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
                onPressed: () => _declineRequest(request),
                icon: const Icon(Icons.close, color: Colors.red),
                iconSize: 20,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ),
            const SizedBox(width: 8),
            // Accept Button
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                onPressed: () => _acceptRequest(request),
                icon: const Icon(Icons.check, color: Colors.white),
                iconSize: 20,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSentRequestActions(FollowRequestEntity request) {
    return BlocBuilder<FollowRequestCubit, FollowRequestState>(
      builder: (context, state) {
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
                onPressed: () => _cancelRequest(request),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                ),
                child: const Text('Cancel', style: TextStyle(fontSize: 12)),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              subtitle,
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  void _acceptRequest(FollowRequestEntity request) {
    context.read<FollowRequestCubit>().acceptFollowRequest(
      requestId: request.id,
      fromUserId: request.fromUserId,
      toUserId: request.toUserId,
    );
  }

  void _declineRequest(FollowRequestEntity request) {
    context.read<FollowRequestCubit>().declineFollowRequest(
      requestId: request.id,
      userId: widget.userId,
    );
  }

  void _cancelRequest(FollowRequestEntity request) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Follow Request'),
          content: const Text(
            'Are you sure you want to cancel this follow request?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<FollowRequestCubit>().cancelFollowRequest(
                  fromUserId: request.fromUserId,
                  toUserId: request.toUserId,
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Yes, Cancel'),
            ),
          ],
        );
      },
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
