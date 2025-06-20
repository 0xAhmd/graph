import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageHelper {
  static final ImagePicker _picker = ImagePicker();

  static Future<File?> pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  static Future<File?> pickAndResizeImage(BuildContext context) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (pickedFile != null) {
        final originalFile = File(pickedFile.path);

        // Show resize dialog
        final resizedFile = await showDialog<File?>(
          context: context,
          builder: (context) => ImageResizeDialog(originalFile: originalFile),
        );

        return resizedFile ?? originalFile;
      }
      return null;
    } catch (e) {
      debugPrint('Error picking and resizing image: $e');
      return null;
    }
  }

  static Future<File> resizeImage(
    File imageFile,
    int maxWidth,
    int maxHeight,
  ) async {
    try {
      // Read the image
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) throw Exception('Could not decode image');

      // Calculate new dimensions maintaining aspect ratio
      int newWidth = image.width;
      int newHeight = image.height;

      if (newWidth > maxWidth || newHeight > maxHeight) {
        final aspectRatio = newWidth / newHeight;

        if (aspectRatio > 1) {
          // Landscape
          newWidth = maxWidth;
          newHeight = (maxWidth / aspectRatio).round();
        } else {
          // Portrait or square
          newHeight = maxHeight;
          newWidth = (maxHeight * aspectRatio).round();
        }
      }

      // Resize the image
      final resizedImage = img.copyResize(
        image,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.linear,
      );

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final fileName = 'resized_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final tempFile = File(path.join(tempDir.path, fileName));

      await tempFile.writeAsBytes(img.encodeJpg(resizedImage, quality: 85));

      return tempFile;
    } catch (e) {
      debugPrint('Error resizing image: $e');
      return imageFile; // Return original if resize fails
    }
  }
}

class ImageResizeDialog extends StatefulWidget {
  final File originalFile;

  const ImageResizeDialog({super.key, required this.originalFile});

  @override
  State<ImageResizeDialog> createState() => _ImageResizeDialogState();
}

class _ImageResizeDialogState extends State<ImageResizeDialog> {
  double _scale = 1.0;
  bool _isProcessing = false;
  File? _previewFile;

  @override
  void initState() {
    super.initState();
    _previewFile = widget.originalFile;
  }

  Future<void> _updatePreview() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final maxSize = (800 * _scale).round();
      final resizedFile = await ImageHelper.resizeImage(
        widget.originalFile,
        maxSize,
        maxSize,
      );

      setState(() {
        _previewFile = resizedFile;
      });
    } catch (e) {
      debugPrint('Error updating preview: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Resize Image'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image preview
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _previewFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(_previewFile!, fit: BoxFit.cover),
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),
            const SizedBox(height: 16),

            // Scale slider
            Text(
              'Size: ${(_scale * 100).round()}%',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Slider(
              value: _scale,
              min: 0.3,
              max: 1.0,
              divisions: 7,
              label: '${(_scale * 100).round()}%',
              onChanged: (value) {
                setState(() {
                  _scale = value;
                });
              },
              onChangeEnd: (value) {
                _updatePreview();
              },
            ),

            const SizedBox(height: 8),

            if (_isProcessing)
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Processing...'),
                ],
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isProcessing
              ? null
              : () => Navigator.of(context).pop(_previewFile),
          child: const Text('Use This Size'),
        ),
      ],
    );
  }
}
