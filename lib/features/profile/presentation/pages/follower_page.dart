import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ig_mate/features/auth/presentation/cubit/cubit/auth_cubit.dart';
import 'package:ig_mate/features/profile/presentation/pages/profile_page.dart';
import '../../../../layout/constrained_scaffold.dart';
import '../cubit/cubit/profile_cubit.dart';

class FollowerPage extends StatelessWidget {
  const FollowerPage({
    super.key,
    required this.followers,
    required this.followings,
    this.originalProfileUid, // Add this parameter
  });

  final List<String> followers;
  final List<String> followings;
  final String? originalProfileUid; // Track the original profile we came from

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: ConstrainedScaffold(
        appBar: AppBar(
          bottom: TabBar(
            dividerColor: Colors.transparent,
            labelColor: Theme.of(context).colorScheme.inversePrimary,
            unselectedLabelColor: Theme.of(context).colorScheme.primary,
            tabs: [
              const Tab(text: "Followers"),
              const Tab(text: "Following"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFollowerList(followers, "No Followers", context),
            _buildFollowerList(followings, "Not Following anyone", context),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowerList(
    List<String> uids,
    String emptyMessage,
    BuildContext context,
  ) {
    return uids.isEmpty
        ? Center(
            child: Text(
              emptyMessage,
              style: TextStyle(
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
          )
        : ListView.builder(
            itemBuilder: (context, index) {
              final uid = uids[index];

              return FutureBuilder(
                future: context.read<ProfileCubit>().getUserProfile(uid),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final user = snapshot.data!;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user.profileImgUrl.isNotEmpty
                            ? NetworkImage(user.profileImgUrl)
                            : null,
                        child: (user.profileImgUrl.isEmpty)
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(user.name),
                      subtitle: Text(user.email),

                      // In FollowerPage, replace the onTap with this:
                      onTap: () async {
                        // Get current user to check if it's own profile
                        final currentUserUid = context
                            .read<AuthCubit>()
                            .currentUser
                            ?.uid;

                        if (user.uid == currentUserUid) {
                          // If navigating to own profile, pop all the way back to main profile
                          Navigator.popUntil(context, (route) {
                            return route.settings.arguments is String &&
                                    (route.settings.arguments as String) ==
                                        currentUserUid ||
                                route.isFirst;
                          });
                          Fluttertoast.showToast(
                            msg: "Go to your profile From Drawer",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                            backgroundColor: Colors.red,
                            textColor: Colors.white,
                          );
                        } else {
                          // For other profiles, use pushReplacement to avoid stack issues
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfilePage(
                                uid: user.uid,
                                key:
                                    UniqueKey(), // Force new instance every time
                              ),
                              settings: RouteSettings(
                                arguments: user.uid,
                              ), // For popUntil reference
                            ),
                          );
                        }
                      },
                    );
                  } else if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const ListTile(title: Text("Loading.."));
                  } else {
                    return const ListTile(title: Text("User not found..."));
                  }
                },
              );
            },
            itemCount: uids.length,
          );
  }
}
