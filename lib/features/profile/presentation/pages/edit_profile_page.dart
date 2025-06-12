import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ig_mate/layout/constrained_scaffold.dart';
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
  final TextEditingController emailTextController = TextEditingController();
  bool _canUpdateEmail = true;
  DateTime? _lastEmailUpdate;

  void updateProfile() async {
    final profileCubit = context.read<ProfileCubit>();

    // Check if email can be updated
    if (emailTextController.text.isNotEmpty &&
        emailTextController.text != widget.profileUserEntity.email) {
      if (!_canUpdateEmail) {
        Fluttertoast.showToast(
          msg: "Email can only be updated once per 40 days",
          backgroundColor: Colors.orange,
          textColor: Colors.white,
        );
        return;
      }

      // Validate email format
      if (!_isValidEmail(emailTextController.text)) {
        Fluttertoast.showToast(
          msg: "Please enter a valid email address",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return;
      }
    }

    // Always call update, even if only bio changed
    await profileCubit.updatedProfile(
      uid: widget.profileUserEntity.uid,
      newBio: bioTextController.text.isNotEmpty ? bioTextController.text : null,
      newEmail:
          (emailTextController.text.isNotEmpty &&
              emailTextController.text != widget.profileUserEntity.email)
          ? emailTextController.text
          : null,
    );
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

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _checkEmailUpdateAvailability() {
    // Check if user has lastEmailUpdate timestamp
    if (widget.profileUserEntity.lastEmailUpdate != null) {
      _lastEmailUpdate = DateTime.fromMillisecondsSinceEpoch(
        widget.profileUserEntity.lastEmailUpdate!,
      );

      final daysSinceLastUpdate = DateTime.now()
          .difference(_lastEmailUpdate!)
          .inDays;
      _canUpdateEmail = daysSinceLastUpdate >= 40;
    } else {
      _canUpdateEmail = true; // First time updating email
    }
  }

  @override
  void initState() {
    super.initState();
    bioTextController.text = widget.profileUserEntity.bio;
    emailTextController.text = widget.profileUserEntity.email;
    _checkEmailUpdateAvailability();
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
          return ConstrainedScaffold(
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

    return ConstrainedScaffold(
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

          // Email Section
          Padding(
            padding: const EdgeInsets.only(left: 25),
            child: Row(
              children: [
                Text(
                  'Email',
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                if (!_canUpdateEmail) ...[
                  const Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(${40 - DateTime.now().difference(_lastEmailUpdate!).inDays} days left)',
                    style: const TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          CustomTextField(
            controller: emailTextController,
            hintText: "Enter your email address",
            isObscured: false,
            enabled: _canUpdateEmail,
          ),
          if (!_canUpdateEmail)
            const Padding(
              padding: EdgeInsets.only(left: 25, top: 5),
              child: Text(
                'Email can only be updated once every 40 days',
                style: TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ),

          const SizedBox(height: 20),

          // Bio Section
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
