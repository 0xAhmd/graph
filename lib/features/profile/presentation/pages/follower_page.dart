import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ig_mate/layout/consentrained_scaffold.dart';
import '../cubit/cubit/profile_cubit.dart';
import '../widgets/user_list_tile.dart';

class FollowerPage extends StatelessWidget {
  const FollowerPage({
    super.key,
    required this.followers,
    required this.followings,
  });
  final List<String> followers;
  final List<String> followings;
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
                    return UserListTile(profileUserEntity: user);
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
