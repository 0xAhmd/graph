import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ig_mate/features/auth/presentation/widgets/custom_text_field.dart';
import 'package:ig_mate/features/profile/domain/entities/profile_user.dart';
import 'package:ig_mate/features/profile/presentation/cubit/cubit/profile_cubit.dart';

class EditProfilePage extends StatefulWidget {
  final ProfileUserEntity profileUserEntity;
  const EditProfilePage({super.key, required this.profileUserEntity});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  void updateProfile() async {
    final profileCubit = context.read<ProfileCubit>();
    if (bioTextController.text.isNotEmpty) {
      profileCubit.updatedProfile(
        uid: widget.profileUserEntity.uid,
        newBio: bioTextController.text, // ✅ pass the updated bio
      );
    }
  }

  final TextEditingController bioTextController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState>(
      listener: (context, state) {
        if (state is ProfileLoaded) {
          Navigator.pop(context);
        }
      },
      builder: (context, state) {
        if (state is ProfileLoading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CupertinoActivityIndicator(),
                  SizedBox(height: 15),
                  Text("Updating your profile info..."),
                ],
              ),
            ),
          );
        } else {
          return buildEditPage();
        }
      },
    );
  }

  Widget buildEditPage({double uploadProgress = 0.0}) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: updateProfile,
            icon: const Icon(Icons.upload_rounded),
          ),
        ],
        foregroundColor: Theme.of(context).colorScheme.primary,
        title: const Text("Let's Edit Your Profile"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const Text('bio', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: CustomTextField(
              controller: bioTextController,
              hintText: widget.profileUserEntity.bio,
              isObscured: false,
            ),
          ),
        ],
      ),
    );
  }
}
