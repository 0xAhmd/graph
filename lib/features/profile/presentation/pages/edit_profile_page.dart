import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../../core/utils/image_picker.dart';
import '../../../auth/presentation/widgets/custom_text_field.dart';
import '../../domain/entities/profile_user.dart';
import '../cubit/cubit/profile_cubit.dart';

class EditProfilePage extends StatefulWidget {
  final ProfileUserEntity profileUserEntity;
  const EditProfilePage({super.key, required this.profileUserEntity});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController bioTextController = TextEditingController();

  void updateProfile() async {
    final profileCubit = context.read<ProfileCubit>();
    if (bioTextController.text.isNotEmpty) {
      await profileCubit.updatedProfile(
        uid: widget.profileUserEntity.uid,
        newBio: bioTextController.text,
      );
    }
  }

  void updateImage() async {
    final profileCubit = context.read<ProfileCubit>();
    final imageFile = await ImageHelper.pickImage();
    if (imageFile != null) {
      await profileCubit.uploadProfileImage(
        image: imageFile,
        uid: widget.profileUserEntity.uid,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    bioTextController.text = widget.profileUserEntity.bio;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState>(
      listener: (context, state) {
        if (state is ProfileLoaded) {
          Navigator.pop(context);
        } else if (state is ProfileError) {
          Fluttertoast.showToast(
            msg: state.errMessage,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        }
      },
      builder: (context, state) {
        if (state is ProfileLoading || state is ProfileImageUploading) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CupertinoActivityIndicator(),
                  const SizedBox(height: 15),
                  Text(
                    "Updating your profile...",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return buildEditPage(state);
      },
    );
  }

  Widget buildEditPage(ProfileState state) {
    final profile = (state is ProfileLoaded)
        ? state.profileUserEntity
        : widget.profileUserEntity;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: updateProfile,
            icon: const Icon(Icons.upload_rounded),
          ),
        ],
        foregroundColor: Theme.of(context).colorScheme.primary,
        title: const Text("Edit Your Profile"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          GestureDetector(
            onTap: updateImage,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 90,
                    backgroundColor: Colors.grey.shade300,
                    child: CachedNetworkImage(
                      imageUrl: profile.profileImgUrl,
                      imageBuilder: (context, imageProvider) => CircleAvatar(
                        radius: 90,
                        backgroundImage: imageProvider,
                      ),
                      placeholder: (context, url) =>
                          const CupertinoActivityIndicator(),
                      errorWidget: (context, url, error) => CircleAvatar(
                        radius: 90,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Icon(
                          Icons.person,
                          size: 70,
                          color: Theme.of(context).colorScheme.inversePrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.only(left: 25),
            child: Text(
              'Bio',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          CustomTextField(
            controller: bioTextController,
            hintText: "Enter your bio",
            isObscured: false,
          ),
        ],
      ),
    );
  }
}
