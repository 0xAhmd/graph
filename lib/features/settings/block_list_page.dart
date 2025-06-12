import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ig_mate/features/auth/presentation/cubit/cubit/auth_cubit.dart';
import 'package:ig_mate/features/profile/presentation/cubit/cubit/profile_cubit.dart';
import 'package:ig_mate/features/profile/domain/entities/profile_user.dart';
import 'package:ig_mate/layout/consentrained_scaffold.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';

class BlockListPage extends StatefulWidget {
  const BlockListPage({super.key});

  @override
  State<BlockListPage> createState() => _BlockListPageState();
}

class _BlockListPageState extends State<BlockListPage> {
  List<String> blockedUserIds = [];
  bool isLoading = true;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    setState(() => isLoading = true);

    try {
      final currentUser = context.read<AuthCubit>().currentUser;
      if (currentUser != null) {
        currentUserId = currentUser.uid;
        final profileCubit = context.read<ProfileCubit>();
        final blockedIds = await profileCubit.loadBlockedUsers(currentUserId!);
        setState(() {
          blockedUserIds = blockedIds;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading blocked users: $e');
      setState(() => isLoading = false);
    }
  }

  void _showUnBlockConfirmationBox(String userId) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.confirm,
      text: "Are you sure you want to unblock this user?",
      confirmBtnText: "Yes",
      showCancelBtn: true,
      confirmBtnColor: Theme.of(context).colorScheme.primary,
      onConfirmBtnTap: () async {
        Navigator.pop(context);
        await _unblockUser(userId);
      },
    );
  }

  Future<void> _unblockUser(String userId) async {
    if (currentUserId == null) return;

    try {
      final profileCubit = context.read<ProfileCubit>();
      await profileCubit.unBlockUser(currentUserId!, userId);

      setState(() {
        blockedUserIds.remove(userId);
      });

      if (mounted) {
        Fluttertoast.showToast(
          msg: "User unblocked Successfully",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green, // or Colors.green, etc.
          textColor: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('Error unblocking user: $e');
      if (mounted) {
        Fluttertoast.showToast(
          msg: "Failed unblock user $e",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red, // or Colors.green, etc.
          textColor: Colors.white,
        );
      }
    }
  }

  Future<ProfileUserEntity?> _getUserProfile(String uid) async {
    try {
      final profileCubit = context.read<ProfileCubit>();
      return await profileCubit.getUserProfile(uid);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedScaffold(
      appBar: AppBar(
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        title: const Text("Blocked Users"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : blockedUserIds.isEmpty
          ? Center(
              child: Text(
                "No blocked users.",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              itemCount: blockedUserIds.length,
              itemBuilder: (context, index) {
                final userId = blockedUserIds[index];
                return FutureBuilder<ProfileUserEntity?>(
                  future: _getUserProfile(userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        margin: const EdgeInsets.only(
                          left: 25,
                          right: 25,
                          top: 10,
                        ),
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const ListTile(title: Text('Loading...')),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data == null) {
                      return Container(
                        margin: const EdgeInsets.only(
                          left: 25,
                          right: 25,
                          top: 10,
                        ),
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const ListTile(title: Text('User not found')),
                      );
                    }
                    final user = snapshot.data!;
                    return Container(
                      margin: const EdgeInsets.only(
                        left: 25,
                        right: 25,
                        top: 10,
                      ),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.2),
                          child: Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        title: Text(
                          user.name,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.inversePrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          user.email,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.inversePrimary,
                          ),
                        ),
                        trailing: TextButton.icon(
                          onPressed: () =>
                              _showUnBlockConfirmationBox(user.uid),
                          icon: const Icon(Icons.lock_open, color: Colors.red),
                          label: const Text(
                            "Unblock",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
