import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ig_mate/features/auth/presentation/cubit/cubit/auth_cubit.dart';
import 'package:ig_mate/features/home/presentation/widgets/drawer_tile.dart';
import 'package:ig_mate/features/profile/presentation/pages/profile_page.dart';

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,

      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              // profile tile
              DrawerTile(
                icon: Icons.person,
                title: "P R O F I L E",
                onTap: () {
                  Navigator.pop(context);
                  final user = context.read<AuthCubit>().currentUser;
                  String? uid = user!.uid;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfilePage(uid: uid),
                    ),
                  );
                },
              ),
              // settings tile
              DrawerTile(
                icon: Icons.settings,
                title: "S E T T I N G S ",
                onTap: () {},
              ),
              // search tile
              DrawerTile(
                icon: Icons.search_rounded,
                title: "S E A R C H",
                onTap: () {},
              ),
              // chat tile
              DrawerTile(icon: Icons.chat_rounded, title: "D M ", onTap: () {}),
              // logout tile
              const Spacer(),
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
