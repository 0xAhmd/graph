import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../private/presentation/pages/follow_request_page.dart';
import '../../../chat/presentation/pages/chat_list_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../auth/presentation/cubit/cubit/auth_cubit.dart';
import 'drawer_tile.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../search/presentation/pages/search_page.dart';

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthCubit>().currentUser;

    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 50),
                child: Image.asset(
                  color: Theme.of(context).colorScheme.primary,
                  'assets/images/graph.png',
                  width: 124,
                ),
              ),
              Divider(color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 10),

              // home tile
              DrawerTile(
                icon: Icons.home_filled,
                title: "H O M E ",
                onTap: () => Navigator.pop(context),
              ),

              // profile tile
              DrawerTile(
                icon: Icons.person,
                title: "P R O F I L E",
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfilePage(uid: user!.uid),
                    ),
                  );
                },
              ),

              // settings tile
              DrawerTile(
                icon: Icons.settings,
                title: "S E T T I N G S ",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsPage(),
                    ),
                  );
                },
              ),

              // search tile
              DrawerTile(
                icon: Icons.search_rounded,
                title: "S E A R C H",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SearchPage()),
                  );
                },
              ),

              // chat tile
              DrawerTile(
                icon: Icons.chat_rounded,
                title: "D M ",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChatListPage(),
                    ),
                  );
                },
              ),

              // ✅ follow requests tile (fixed)
              DrawerTile(
                icon: Icons.group_add_sharp,
                title: "N E W N O D E S",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          FollowRequestsPage(userId: user!.uid),
                    ),
                  );
                },
              ),

              const Spacer(),

              // logout
              DrawerTile(
                icon: Icons.logout,
                title: "L O G O U T ",
                onTap: () {
                  context.read<AuthCubit>().logout();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
