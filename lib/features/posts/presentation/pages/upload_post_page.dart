import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ig_mate/core/helpers/image_picker.dart';
import 'package:ig_mate/features/auth/domain/entities/app_user.dart';
import 'package:ig_mate/features/auth/presentation/cubit/cubit/auth_cubit.dart';
import 'package:ig_mate/features/auth/presentation/widgets/custom_text_field.dart';
import 'package:ig_mate/features/posts/domain/entities/post_entity.dart';
import 'package:ig_mate/features/posts/presentation/cubit/post_cubit.dart';

class UploadPostPage extends StatefulWidget {
  const UploadPostPage({super.key});

  @override
  State<UploadPostPage> createState() => _UploadPostPageState();
}

class _UploadPostPageState extends State<UploadPostPage> {
  final TextEditingController postController = TextEditingController();
  AppUser? currentUser;
  File? selectedImage;

  @override
  void initState() {
    getCurrentUser();
    super.initState();
  }

  void getCurrentUser() async {
    final authCubit = context.read<AuthCubit>();
    currentUser = authCubit.currentUser;
  }

  // select image
  Future<void> selectImage() async {
    final imageFile = await ImageHelper.pickImage();
    if (imageFile != null) {
      setState(() {
        selectedImage = imageFile;
      });
    }
  }

  // create and upload post
  void uploadPost() {
    // check if both image and caption are provided
    if (selectedImage == null || postController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image and write a caption.'),
        ),
      );
      return;
    }
    // create the post
    final newPost = Post(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: currentUser!.uid,
      userName: currentUser!.name,
      text: postController.text,
      imageUrl: '',
      timeStamp: DateTime.now(),
    );
    final postCubit = context.read<PostCubit>();

    // mobile upload
    postCubit.createPost(post: newPost, imageFile: selectedImage);
    // web upload will implement it later
    Navigator.pop(context);
  }

  @override
  void dispose() {
    postController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PostCubit, PostState>(
      builder: (context, state) {
        if (state is PostLoading || state is PostUploading) {
          return const Scaffold(
            body: Center(child: CupertinoActivityIndicator()),
          );
        }
        return buildUploadingPage();
      },
      listener: (context, state) {
        if (state is PostLoaded) {
          Navigator.pop(context);
        }
      },
    );
  }

  Widget buildUploadingPage() {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(onPressed: uploadPost, icon: const Icon(Icons.add)),
        ],
        title: const Text("Share your thoughts!"),
        centerTitle: true,
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Tap here to Add Image!",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 8), // Image preview
              if (selectedImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 4,
                    ),
                    child: Image.file(
                      selectedImage!,
                      width: double.infinity,
                      height: 500,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                GestureDetector(
                  onTap: selectImage,

                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 4,
                    ),
                    width: double.infinity,
                    height: 500,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.upload,
                      size: 80,
                      color: Colors.grey,
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Decorated pick image button

              // Text field for post caption/comment
              CustomTextField(
                controller: postController,
                hintText: "Write a caption...",
                isObscured: false,
              ),
              const SizedBox(height: 16),

            ],
          ),
        ),
      ),
    );
  }
}
