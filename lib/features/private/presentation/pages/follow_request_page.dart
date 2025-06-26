// lib/features/private/presentation/pages/follow_request_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ig_mate/features/private/presentation/cubit/follow_request_cubit.dart';
import 'package:ig_mate/features/private/domain/entities/follow_request.dart';

import 'package:ig_mate/features/private/presentation/widgets/error.dart';
import 'package:ig_mate/features/private/presentation/widgets/follow_request_list.dart';
import 'package:ig_mate/features/profile/domain/entities/profile_user.dart';
import 'package:ig_mate/features/profile/presentation/cubit/cubit/profile_cubit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ig_mate/features/profile/presentation/pages/profile_page.dart';

class FollowRequestsPage extends StatefulWidget {
  final String userId;

  const FollowRequestsPage({super.key, required this.userId});

  @override
  State<FollowRequestsPage> createState() => _FollowRequestsPageState();
}

class _FollowRequestsPageState extends State<FollowRequestsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, ProfileUserEntity> _userProfiles = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeFollowRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeFollowRequests() {
    final cubit = context.read<FollowRequestCubit>();
    cubit.loadFollowRequests(widget.userId);
    cubit.streamIncomingRequests(widget.userId);
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
      appBar: _buildAppBar(),
      body: BlocConsumer<FollowRequestCubit, FollowRequestState>(
        listener: _handleStateChanges,
        builder: _buildBody,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Follow Requests'),
      centerTitle: true,
      foregroundColor: Theme.of(context).colorScheme.primary,
      bottom: TabBar(
        dividerColor: Colors.transparent,
        controller: _tabController,
        indicatorColor: Theme.of(context).colorScheme.primary,
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: Colors.grey,
        tabs: const [
          Tab(text: 'Received'),
          Tab(text: 'Sent'),
        ],
      ),
    );
  }

  void _handleStateChanges(BuildContext context, FollowRequestState state) {
    if (state is FollowRequestError) {
      Fluttertoast.showToast(
        msg: state.message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Widget _buildBody(BuildContext context, FollowRequestState state) {
    if (state is FollowRequestLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (state is FollowRequestError) {
      return ErrorStateWidget(
        message: state.message,
        onRetry: () => context.read<FollowRequestCubit>().loadFollowRequests(
          widget.userId,
        ),
      );
    }

    if (state is FollowRequestLoaded) {
      return TabBarView(
        controller: _tabController,
        children: [
          FollowRequestsList(
            requests: state.incomingRequests,
            isIncoming: true,
            userProfiles: _userProfiles,
            onLoadUserProfile: _loadUserProfile,
            onRefresh: _refreshRequests,
            onAccept: _acceptRequest,
            onDecline: _declineRequest,
            onUserTap: _navigateToUserProfile,
            currentUserId: widget.userId,
          ),
          FollowRequestsList(
            requests: state.outgoingRequests,
            isIncoming: false,
            userProfiles: _userProfiles,
            onLoadUserProfile: _loadUserProfile,
            onRefresh: _refreshRequests,
            onCancel: _cancelRequest,
            onUserTap: _navigateToUserProfile,
            currentUserId: widget.userId,
          ),
        ],
      );
    }

    return const Center(child: Text('No requests to show'));
  }

  Future<void> _refreshRequests() async {
    context.read<FollowRequestCubit>().loadFollowRequests(widget.userId);
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

  void _navigateToUserProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfilePage(uid: userId)),
    );
  }
}
