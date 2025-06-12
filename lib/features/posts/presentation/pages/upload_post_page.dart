import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ig_mate/core/utils/text_bomb_detector.dart';
import 'package:ig_mate/layout/constrained_scaffold.dart';
import '../../../../core/utils/image_picker.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/cubit/cubit/auth_cubit.dart';
import '../../../auth/presentation/widgets/custom_text_field.dart';
import '../../domain/entities/post_entity.dart';
import '../cubit/post_cubit.dart';

class UploadPostPage extends StatefulWidget {
  const UploadPostPage({super.key});

  @override
  State<UploadPostPage> createState() => _UploadPostPageState();
}

class _UploadPostPageState extends State<UploadPostPage> {
  final TextEditingController postController = TextEditingController();
  AppUser? currentUser;
  File? selectedImage;
  bool isExpanded = false;

  @override
  void initState() {
    getCurrentUser();
    super.initState();
  }

  void getCurrentUser() async {
    final authCubit = context.read<AuthCubit>();
    currentUser = authCubit.currentUser;
  }

  // Text bomb detection helper function

  // Check if caption is too long for preview
  bool isLongCaption(String text) {
    return text.length > 150; // Adjust this threshold as needed
  }

  // Get preview text
  String getPreviewText(String text) {
    if (text.length <= 150) return text;
    return '${text.substring(0, 150)}...';
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
    final caption = postController.text.trim();

    // check if both image and caption are provided
    if (selectedImage == null || caption.isEmpty) {
      Fluttertoast.showToast(
        msg: "Please select image and write caption",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    // Check for text bomb
    if (isTextBomb(caption)) {
      Fluttertoast.showToast(
        msg: "Caption is too long or contains spam content",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    // create the post
    final newPost = Post(
      comments: [],
      likes: [],
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: currentUser!.uid,
      userName: currentUser!.name,
      text: caption,
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
          return const ConstrainedScaffold(
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

  Widget buildCaptionPreview() {
    final caption = postController.text;

    if (caption.isEmpty) {
      return const SizedBox.shrink();
    }

    // Check if it's a text bomb
    if (isTextBomb(caption)) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red, width: 1),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                "Caption contains spam content or is too long",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Show preview for long captions
    if (isLongCaption(caption)) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Caption Preview:",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isExpanded ? caption : getPreviewText(caption),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            if (isLongCaption(caption))
              GestureDetector(
                onTap: () {
                  setState(() {
                    isExpanded = !isExpanded;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    isExpanded ? "See less" : "See more",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget buildUploadingPage() {
    return ConstrainedScaffold(
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
              const SizedBox(height: 8),

              // Image preview
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

              // Text field for post caption/comment
              CustomTextField(
                controller: postController,
                hintText: "Write a caption...",
                isObscured: false,
                onChanged: (value) {
                  setState(() {}); // Trigger rebuild to update preview
                },
              ),
              const SizedBox(height: 8),

              // Caption preview with text bomb detection and see more functionality
              buildCaptionPreview(),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
