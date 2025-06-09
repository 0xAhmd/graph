import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ig_mate/features/auth/domain/entities/app_user.dart';
import 'package:ig_mate/features/auth/presentation/cubit/cubit/auth_cubit.dart';
import 'package:ig_mate/features/profile/presentation/cubit/cubit/profile_cubit.dart';
import 'package:ig_mate/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:ig_mate/features/profile/presentation/widgets/bio_box.dart';

class ProfilePage extends StatefulWidget {
  final String uid;
  const ProfilePage({super.key, required this.uid});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final authCubit = context.read<AuthCubit>();
  late final profileCubit = context.read<ProfileCubit>();
  late AppUser? currentUser = authCubit.currentUser;
  @override
  void initState() {
    profileCubit.fetchUserProfile(widget.uid);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        if (state is ProfileLoaded) {
          final user = state.profileUserEntity;
          return Scaffold(
            appBar: AppBar(
              actions: [
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EditProfilePage(profileUserEntity: user),
                      ),
                    );
                  },
                  icon: const Icon(Icons.settings),
                ),
              ],
              centerTitle: true,
              title: Text(user.name),
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
            body: Center(
              child: Column(
                children: [
                  Text(
                    user.email,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 25),
                  Container(
                    padding: const EdgeInsets.all(25),
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    child: Icon(
                      Icons.person,
                      size: 70,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),

                  const SizedBox(height: 25),
                  // bio box
                  Padding(
                    padding: const EdgeInsets.only(left: 25.0),
                    child: Row(
                      children: [
                        Text(
                          "Bio",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  BioBox(text: user.bio),

                  Padding(
                    padding: const EdgeInsets.only(left: 25.0, top: 25),
                    child: Row(
                      children: [
                        Text(
                          "Posts",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        } else if (state is ProfileLoading) {
          return const Scaffold(
            body: Center(child: CupertinoActivityIndicator()),
          );
        } else {
          return const Center(child: Text("No Profile loaded"));
        }
      },
    );
  }
}
