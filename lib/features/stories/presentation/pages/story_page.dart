// lib/features/stories/presentation/pages/create_story_page.dart

import 'package:flutter/cupertino.dart';
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
  final FocusNode _textFocusNode = FocusNode();

  File? _selectedImage;
  String _backgroundColor = '#000000';
  String _textColor = '#FFFFFF';
  double _fontSize = 24.0;
  String _fontWeight = 'normal';
  bool _showTextOptions = false;
  bool _isTextStory = true;

  Offset _textPosition = const Offset(100, 300); // initial position
  bool _isTextFocused = false;

  @override
  void initState() {
    super.initState();
    _textFocusNode.addListener(() {
      setState(() {
        _isTextFocused = _textFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _textFocusNode.dispose();
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
          _textPosition = const Offset(100, 300);
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
          _textPosition = const Offset(100, 300);
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
      context.read<StoriesCubit>().createTextStory(
        userId: currentUser.uid,
        username: currentUser.name,
        userProfileImageUrl: profileImageUrl,
        content: _textController.text.trim(),
        backgroundColor: _backgroundColor,
        textColor: _textColor,
        fontSize: _fontSize,
        fontWeight: _fontWeight,
      );
    } else if (!_isTextStory && _selectedImage != null) {
      context.read<StoriesCubit>().createImageStory(
        userId: currentUser.uid,
        username: currentUser.name,
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

  void _onTextTap() {
    if (!_isTextFocused) {
      _textFocusNode.requestFocus();
    }
  }

  void _onBackgroundTap() {
    if (_isTextFocused) {
      _textFocusNode.unfocus();
    }
    if (_showTextOptions) {
      setState(() {
        _showTextOptions = false;
      });
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
        body: GestureDetector(
          onTap: _onBackgroundTap,
          child: Stack(
            children: [
              if (_selectedImage != null)
                Positioned.fill(
                  child: Image.file(_selectedImage!, fit: BoxFit.cover),
                ),

              // For text stories: centered editable text
              if (_isTextStory)
                Positioned.fill(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: _onTextTap,
                          child: TextField(
                            controller: _textController,
                            focusNode: _textFocusNode,
                            style: TextStyle(
                              color: _getColorFromHex(_textColor),
                              fontSize: _fontSize,
                              fontWeight: _getFontWeight(_fontWeight),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: null,
                            decoration: InputDecoration(
                              hintText: 'Type your story...',
                              hintStyle: TextStyle(
                                color: _getColorFromHex(
                                  _textColor,
                                ).withOpacity(0.7),
                                fontSize: _fontSize,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // For image stories: draggable text field
              if (!_isTextStory)
                Positioned(
                  left: _textPosition.dx,
                  top: _textPosition.dy,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        final screenWidth = MediaQuery.of(context).size.width;
                        final screenHeight = MediaQuery.of(context).size.height;

                        _textPosition += details.delta;
                        _textPosition = Offset(
                          _textPosition.dx.clamp(0.0, screenWidth - 200),
                          _textPosition.dy.clamp(0.0, screenHeight - 200),
                        );
                      });
                    },
                    onTap: _onTextTap,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width - 40,
                        minWidth: 200,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: _textController.text.isNotEmpty
                          ? BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            )
                          : null,
                      child: TextField(
                        controller: _textController,
                        focusNode: _textFocusNode,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: _fontSize,
                          fontWeight: _getFontWeight(_fontWeight),
                          shadows: [
                            Shadow(
                              offset: const Offset(1, 1),
                              blurRadius: 3,
                              color: Colors.black.withOpacity(0.8),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: 'Add a caption...',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: _fontSize,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ),

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
                    child: Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Text Options',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _showTextOptions = false;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
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
                ),

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
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isCreating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CupertinoActivityIndicator(
                                radius: 10,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Share Story',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(
                                  context,
                                ).colorScheme.inversePrimary,
                              ),
                            ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
