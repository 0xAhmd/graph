// cspell:disable
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

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

  static Future<File?> pickAndCropImage(BuildContext context) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (pickedFile != null) {
        final originalFile = File(pickedFile.path);

        // Show crop dialog
        final croppedFile = await Navigator.push<File?>(
          context,
          MaterialPageRoute(
            builder: (context) => ImageCropScreen(originalFile: originalFile),
            fullscreenDialog: true,
          ),
        );

        return croppedFile;
      }
      return null;
    } catch (e) {
      debugPrint('Error picking and cropping image: $e');
      return null;
    }
  }

  static Future<File> cropImage(
    File imageFile,
    Rect cropRect,
    Size displaySize,
    Size actualImageSize,
    Offset imageOffset,
  ) async {
    try {
      // Read the image
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) throw Exception('Could not decode image');

      // Convert display coordinates to actual image coordinates
      final scaleX = image.width / displaySize.width;
      final scaleY = image.height / displaySize.height;

      // Adjust crop rect to account for image offset in display
      final adjustedCropRect = Rect.fromLTWH(
        cropRect.left - imageOffset.dx,
        cropRect.top - imageOffset.dy,
        cropRect.width,
        cropRect.height,
      );

      // Calculate actual crop coordinates
      final cropX = max(0, (adjustedCropRect.left * scaleX).round());
      final cropY = max(0, (adjustedCropRect.top * scaleY).round());
      final cropWidth = min(
        image.width - cropX,
        (adjustedCropRect.width * scaleX).round(),
      );
      final cropHeight = min(
        image.height - cropY,
        (adjustedCropRect.height * scaleY).round(),
      );

      // Ensure crop dimensions are valid
      if (cropWidth <= 0 || cropHeight <= 0) {
        throw Exception('Invalid crop dimensions');
      }

      // Crop the image
      final croppedImage = img.copyCrop(
        image,
        x: cropX,
        y: cropY,
        width: cropWidth,
        height: cropHeight,
      );

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final fileName = 'cropped_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final tempFile = File(path.join(tempDir.path, fileName));

      await tempFile.writeAsBytes(img.encodeJpg(croppedImage, quality: 90));

      return tempFile;
    } catch (e) {
      debugPrint('Error cropping image: $e');
      return imageFile; // Return original if crop fails
    }
  }
}

class ImageCropScreen extends StatefulWidget {
  final File originalFile;

  const ImageCropScreen({super.key, required this.originalFile});

  @override
  State<ImageCropScreen> createState() => _ImageCropScreenState();
}

class _ImageCropScreenState extends State<ImageCropScreen> {
  bool _isProcessing = false;
  Rect? _cropRect;
  Size? _displaySize;
  Size? _actualImageSize;
  Offset? _imageOffset;
  final GlobalKey _imageKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Crop Image', style: TextStyle(color: Colors.white)),
        actions: [
          if (_isProcessing)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _cropImage,
              child: const Text(
                'Done',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: ImageCropWidget(
                key: _imageKey,
                imageFile: widget.originalFile,
                onCropDataChanged: (cropRect, displaySize, actualSize, offset) {
                  _cropRect = cropRect;
                  _displaySize = displaySize;
                  _actualImageSize = actualSize;
                  _imageOffset = offset;
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildToolButton(
                  icon: Icons.crop_free,
                  label: 'Free',
                  onTap: () => _setCropRatio(null),
                ),
                _buildToolButton(
                  icon: Icons.crop_din,
                  label: '1:1',
                  onTap: () => _setCropRatio(1.0),
                ),
                _buildToolButton(
                  icon: Icons.crop_3_2,
                  label: '4:3',
                  onTap: () => _setCropRatio(4.0 / 3.0),
                ),
                _buildToolButton(
                  icon: Icons.crop_16_9,
                  label: '16:9',
                  onTap: () => _setCropRatio(16.0 / 9.0),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _setCropRatio(double? ratio) {
    final cropWidget = _imageKey.currentState as _ImageCropWidgetState?;
    cropWidget?.setAspectRatio(ratio);
  }

  Future<void> _cropImage() async {
    if (_cropRect == null ||
        _displaySize == null ||
        _actualImageSize == null ||
        _imageOffset == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a crop area')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final croppedFile = await ImageHelper.cropImage(
        widget.originalFile,
        _cropRect!,
        _displaySize!,
        _actualImageSize!,
        _imageOffset!,
      );

      if (mounted) {
        Navigator.of(context).pop(croppedFile);
      }
    } catch (e) {
      debugPrint('Error during crop: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error cropping image')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}

class ImageCropWidget extends StatefulWidget {
  final File imageFile;
  final Function(Rect, Size, Size, Offset) onCropDataChanged;

  const ImageCropWidget({
    super.key,
    required this.imageFile,
    required this.onCropDataChanged,
  });

  @override
  State<ImageCropWidget> createState() => _ImageCropWidgetState();
}

class _ImageCropWidgetState extends State<ImageCropWidget> {
  Rect _cropRect = const Rect.fromLTWH(50, 50, 200, 200);
  Size _displaySize = Size.zero;
  Size _actualImageSize = Size.zero;
  Offset _imageOffset = Offset.zero;
  double? _aspectRatio;
  bool _isImageLoaded = false;

  void setAspectRatio(double? ratio) {
    setState(() {
      _aspectRatio = ratio;
      if (_isImageLoaded) {
        _updateCropRect();
      }
    });
  }

  void _updateCropRect() {
    if (_displaySize == Size.zero) return;

    final center = Offset(
      _imageOffset.dx + _displaySize.width / 2,
      _imageOffset.dy + _displaySize.height / 2,
    );
    final maxSize = min(_displaySize.width, _displaySize.height) * 0.8;

    double width, height;

    if (_aspectRatio != null) {
      if (_aspectRatio! > 1) {
        width = maxSize;
        height = width / _aspectRatio!;
      } else {
        height = maxSize;
        width = height * _aspectRatio!;
      }
    } else {
      width = min(_cropRect.width, _displaySize.width * 0.8);
      height = min(_cropRect.height, _displaySize.height * 0.8);
    }

    _cropRect = Rect.fromCenter(center: center, width: width, height: height);
    _constrainCropRect();
    _notifyChanges();
  }

  void _constrainCropRect() {
    double left = _cropRect.left;
    double top = _cropRect.top;
    double width = _cropRect.width;
    double height = _cropRect.height;

    final rightLimit = _imageOffset.dx + _displaySize.width;
    final bottomLimit = _imageOffset.dy + _displaySize.height;

    // Constrain to image bounds
    if (left < _imageOffset.dx) left = _imageOffset.dx;
    if (top < _imageOffset.dy) top = _imageOffset.dy;

    if (left + width > rightLimit) {
      width = rightLimit - left;
      if (_aspectRatio != null) height = width / _aspectRatio!;
    }

    if (top + height > bottomLimit) {
      height = bottomLimit - top;
      if (_aspectRatio != null) width = height * _aspectRatio!;
    }

    // Ensure minimum size
    width = max(width, 50);
    height = max(height, 50);

    _cropRect = Rect.fromLTWH(left, top, width, height);
  }

  void _notifyChanges() {
    widget.onCropDataChanged(
      _cropRect,
      _displaySize,
      _actualImageSize,
      _imageOffset,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Image
            Positioned.fill(
              child: Image.file(
                widget.imageFile,
                fit: BoxFit.contain,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (frame != null && !_isImageLoaded) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _calculateImageSize(constraints);
                    });
                  }
                  return child;
                },
              ),
            ),
            // Crop overlay
            if (_isImageLoaded)
              Positioned.fill(
                child: CustomPaint(
                  painter: CropOverlayPainter(
                    cropRect: _cropRect,
                    imageSize: _displaySize,
                    containerSize: constraints.biggest,
                  ),
                ),
              ),
            // Crop handles
            if (_isImageLoaded) ..._buildCropHandles(),
          ],
        );
      },
    );
  }

  Future<void> _calculateImageSize(BoxConstraints constraints) async {
    try {
      final containerSize = constraints.biggest;
      final bytes = await widget.imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final imageAspectRatio = image.width / image.height;
      final containerAspectRatio = containerSize.width / containerSize.height;

      double displayWidth, displayHeight;

      if (imageAspectRatio > containerAspectRatio) {
        displayWidth = containerSize.width;
        displayHeight = displayWidth / imageAspectRatio;
      } else {
        displayHeight = containerSize.height;
        displayWidth = displayHeight * imageAspectRatio;
      }

      final offsetX = (containerSize.width - displayWidth) / 2;
      final offsetY = (containerSize.height - displayHeight) / 2;

      setState(() {
        _displaySize = Size(displayWidth, displayHeight);
        _actualImageSize = Size(
          image.width.toDouble(),
          image.height.toDouble(),
        );
        _imageOffset = Offset(offsetX, offsetY);
        _isImageLoaded = true;

        // Initialize crop rect to center of image
        final initialSize = min(displayWidth, displayHeight) * 0.6;
        _cropRect = Rect.fromCenter(
          center: Offset(
            offsetX + displayWidth / 2,
            offsetY + displayHeight / 2,
          ),
          width: initialSize,
          height: initialSize,
        );

        _notifyChanges();
      });

      image.dispose();
    } catch (e) {
      debugPrint('Error calculating image size: $e');
    }
  }

  List<Widget> _buildCropHandles() {
    const handleSize = 20.0;
    final handles = <Widget>[];

    // Corner handles
    final corners = [
      _cropRect.topLeft,
      _cropRect.topRight,
      _cropRect.bottomLeft,
      _cropRect.bottomRight,
    ];

    for (int i = 0; i < corners.length; i++) {
      handles.add(
        Positioned(
          left: corners[i].dx - handleSize / 2,
          top: corners[i].dy - handleSize / 2,
          child: GestureDetector(
            onPanUpdate: (details) => _handleCornerDrag(i, details.delta),
            child: Container(
              width: handleSize,
              height: handleSize,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.green, width: 2),
                borderRadius: BorderRadius.circular(handleSize / 2),
              ),
            ),
          ),
        ),
      );
    }

    // Center drag area
    handles.add(
      Positioned(
        left: _cropRect.left,
        top: _cropRect.top,
        width: _cropRect.width,
        height: _cropRect.height,
        child: GestureDetector(
          onPanUpdate: (details) => _handleCenterDrag(details.delta),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.transparent),
            ),
          ),
        ),
      ),
    );

    return handles;
  }

  void _handleCornerDrag(int cornerIndex, Offset delta) {
    setState(() {
      final minSize = 50.0;

      switch (cornerIndex) {
        case 0: // Top-left
          final newLeft = _cropRect.left + delta.dx;
          final newTop = _cropRect.top + delta.dy;
          final newWidth = _cropRect.right - newLeft;
          final newHeight = _cropRect.bottom - newTop;

          if (newWidth >= minSize && newHeight >= minSize) {
            _cropRect = Rect.fromLTRB(
              newLeft,
              newTop,
              _cropRect.right,
              _cropRect.bottom,
            );
          }
          break;
        case 1: // Top-right
          final newTop = _cropRect.top + delta.dy;
          final newRight = _cropRect.right + delta.dx;
          final newWidth = newRight - _cropRect.left;
          final newHeight = _cropRect.bottom - newTop;

          if (newWidth >= minSize && newHeight >= minSize) {
            _cropRect = Rect.fromLTRB(
              _cropRect.left,
              newTop,
              newRight,
              _cropRect.bottom,
            );
          }
          break;
        case 2: // Bottom-left
          final newLeft = _cropRect.left + delta.dx;
          final newBottom = _cropRect.bottom + delta.dy;
          final newWidth = _cropRect.right - newLeft;
          final newHeight = newBottom - _cropRect.top;

          if (newWidth >= minSize && newHeight >= minSize) {
            _cropRect = Rect.fromLTRB(
              newLeft,
              _cropRect.top,
              _cropRect.right,
              newBottom,
            );
          }
          break;
        case 3: // Bottom-right
          final newRight = _cropRect.right + delta.dx;
          final newBottom = _cropRect.bottom + delta.dy;
          final newWidth = newRight - _cropRect.left;
          final newHeight = newBottom - _cropRect.top;

          if (newWidth >= minSize && newHeight >= minSize) {
            _cropRect = Rect.fromLTRB(
              _cropRect.left,
              _cropRect.top,
              newRight,
              newBottom,
            );
          }
          break;
      }

      if (_aspectRatio != null) {
        _maintainAspectRatio(cornerIndex);
      }

      _constrainCropRect();
      _notifyChanges();
    });
  }

  void _maintainAspectRatio(int cornerIndex) {
    final center = _cropRect.center;
    double width = _cropRect.width;
    double height = width / _aspectRatio!;

    // Ensure the aspect ratio constrained size fits within bounds
    final maxWidth = _displaySize.width * 0.95;
    final maxHeight = _displaySize.height * 0.95;

    if (width > maxWidth) {
      width = maxWidth;
      height = width / _aspectRatio!;
    }

    if (height > maxHeight) {
      height = maxHeight;
      width = height * _aspectRatio!;
    }

    _cropRect = Rect.fromCenter(center: center, width: width, height: height);
  }

  void _handleCenterDrag(Offset delta) {
    setState(() {
      _cropRect = _cropRect.translate(delta.dx, delta.dy);
      _constrainCropRect();
      _notifyChanges();
    });
  }
}

class CropOverlayPainter extends CustomPainter {
  final Rect cropRect;
  final Size imageSize;
  final Size containerSize;

  CropOverlayPainter({
    required this.cropRect,
    required this.imageSize,
    required this.containerSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    // Draw dark overlay outside crop area
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(cropRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Draw crop rectangle border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRect(cropRect, borderPaint);

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.white38
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Vertical lines
    final thirdWidth = cropRect.width / 3;
    canvas.drawLine(
      Offset(cropRect.left + thirdWidth, cropRect.top),
      Offset(cropRect.left + thirdWidth, cropRect.bottom),
      gridPaint,
    );
    canvas.drawLine(
      Offset(cropRect.left + thirdWidth * 2, cropRect.top),
      Offset(cropRect.left + thirdWidth * 2, cropRect.bottom),
      gridPaint,
    );

    // Horizontal lines
    final thirdHeight = cropRect.height / 3;
    canvas.drawLine(
      Offset(cropRect.left, cropRect.top + thirdHeight),
      Offset(cropRect.right, cropRect.top + thirdHeight),
      gridPaint,
    );
    canvas.drawLine(
      Offset(cropRect.left, cropRect.top + thirdHeight * 2),
      Offset(cropRect.right, cropRect.top + thirdHeight * 2),
      gridPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
