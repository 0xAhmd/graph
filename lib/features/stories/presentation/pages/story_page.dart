// lib/features/stories/presentation/pages/create_story_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ig_mate/features/stories/presentation/cubit/story_cubit.dart';
import 'package:ig_mate/features/stories/presentation/cubit/story_state.dart';
import 'package:ig_mate/features/stories/presentation/widgets/color_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../auth/presentation/cubit/cubit/auth_cubit.dart';
import '../../../profile/presentation/cubit/cubit/profile_cubit.dart';
import '../widgets/text_style_options.dart';

class CreateStoryPage extends StatefulWidget {
  const CreateStoryPage({super.key});

  @override
  State<CreateStoryPage> createState() => _CreateStoryPageState();
}

class _CreateStoryPageState extends State<CreateStoryPage> {
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  String _backgroundColor = '#000000';
  String _textColor = '#FFFFFF';
  double _fontSize = 24.0;
  String _fontWeight = 'normal';
  bool _showTextOptions = false;
  bool _isTextStory = true;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _isTextStory = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _isTextStory = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to take photo: $e')));
    }
  }

  void _createStory() {
    final currentUser = context.read<AuthCubit>().currentUser;
    if (currentUser == null) return;

    final profileCubit = context.read<ProfileCubit>();
    final userProfile = profileCubit.state;

    String? profileImageUrl;
    if (userProfile is ProfileLoaded) {
      profileImageUrl = userProfile.profileUserEntity.profileImgUrl;
    }

    if (_isTextStory && _textController.text.trim().isNotEmpty) {
      // Create text story
      context.read<StoriesCubit>().createTextStory(
        userId: currentUser.uid,
        username: currentUser.email.split('@')[0],
        userProfileImageUrl: profileImageUrl,
        content: _textController.text.trim(),
        backgroundColor: _backgroundColor,
        textColor: _textColor,
        fontSize: _fontSize,
        fontWeight: _fontWeight,
      );
    } else if (!_isTextStory && _selectedImage != null) {
      // Create image story
      context.read<StoriesCubit>().createImageStory(
        userId: currentUser.uid,
        username: currentUser.email.split('@')[0],
        userProfileImageUrl: profileImageUrl,
        imagePath: _selectedImage!.path,
        content: _textController.text.trim().isEmpty
            ? null
            : _textController.text.trim(),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add content to your story')),
      );
      return;
    }
  }

  Color _getColorFromHex(String hexColor) {
    return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
  }

  FontWeight _getFontWeight(String fontWeight) {
    switch (fontWeight) {
      case 'bold':
        return FontWeight.bold;
      case 'light':
        return FontWeight.w300;
      default:
        return FontWeight.normal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<StoriesCubit, StoriesState>(
      listener: (context, state) {
        if (state is StoryCreated) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Story created successfully!')),
          );
        } else if (state is StoriesError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        backgroundColor: _isTextStory
            ? _getColorFromHex(_backgroundColor)
            : Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            if (_isTextStory)
              IconButton(
                icon: const Icon(Icons.palette, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _showTextOptions = !_showTextOptions;
                  });
                },
              ),
            IconButton(
              icon: const Icon(Icons.photo_library, color: Colors.white),
              onPressed: _pickImage,
            ),
            IconButton(
              icon: const Icon(Icons.camera_alt, color: Colors.white),
              onPressed: _takePhoto,
            ),
          ],
        ),
        body: Stack(
          children: [
            // Background/Image
            if (_selectedImage != null)
              Positioned.fill(
                child: Image.file(_selectedImage!, fit: BoxFit.cover),
              ),

            // Text input area
            Positioned.fill(
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextField(
                      controller: _textController,
                      style: TextStyle(
                        color: _isTextStory
                            ? _getColorFromHex(_textColor)
                            : Colors.white,
                        fontSize: _fontSize,
                        fontWeight: _getFontWeight(_fontWeight),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: _isTextStory
                            ? 'Type your story...'
                            : 'Add a caption...',
                        hintStyle: TextStyle(
                          color: _isTextStory
                              ? _getColorFromHex(_textColor).withOpacity(0.7)
                              : Colors.white.withOpacity(0.7),
                          fontSize: _fontSize,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Text styling options
            if (_showTextOptions && _isTextStory)
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Background color picker
                      const Text(
                        'Background Color',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ColorPickerWidget(
                        selectedColor: _backgroundColor,
                        onColorSelected: (color) {
                          setState(() {
                            _backgroundColor = color;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      // Text color picker
                      const Text(
                        'Text Color',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ColorPickerWidget(
                        selectedColor: _textColor,
                        onColorSelected: (color) {
                          setState(() {
                            _textColor = color;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      // Text style options
                      TextStyleOptions(
                        fontSize: _fontSize,
                        fontWeight: _fontWeight,
                        onFontSizeChanged: (size) {
                          setState(() {
                            _fontSize = size;
                          });
                        },
                        onFontWeightChanged: (weight) {
                          setState(() {
                            _fontWeight = weight;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

            // Create story button
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: BlocBuilder<StoriesCubit, StoriesState>(
                builder: (context, state) {
                  final isCreating = state is StoryCreating;

                  return ElevatedButton(
                    onPressed: isCreating ? null : _createStory,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isCreating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Share Story',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
