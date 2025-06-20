import 'dart:io';
import 'dart:math';
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
    Size imageSize,
  ) async {
    try {
      // Read the image
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) throw Exception('Could not decode image');

      // Calculate actual crop coordinates
      final scaleX = image.width / imageSize.width;
      final scaleY = image.height / imageSize.height;

      final cropX = (cropRect.left * scaleX).round();
      final cropY = (cropRect.top * scaleY).round();
      final cropWidth = (cropRect.width * scaleX).round();
      final cropHeight = (cropRect.height * scaleY).round();

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
  Size? _imageSize;
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
                onCropRectChanged: (rect, imageSize) {
                  _cropRect = rect;
                  _imageSize = imageSize;
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
    if (_cropRect == null || _imageSize == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final croppedFile = await ImageHelper.cropImage(
        widget.originalFile,
        _cropRect!,
        _imageSize!,
      );

      if (mounted) {
        Navigator.of(context).pop(croppedFile);
      }
    } catch (e) {
      debugPrint('Error cropping image: $e');
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
  final Function(Rect, Size) onCropRectChanged;

  const ImageCropWidget({
    super.key,
    required this.imageFile,
    required this.onCropRectChanged,
  });

  @override
  State<ImageCropWidget> createState() => _ImageCropWidgetState();
}

class _ImageCropWidgetState extends State<ImageCropWidget> {
  Rect _cropRect = const Rect.fromLTWH(50, 50, 200, 200);
  Size _imageSize = Size.zero;
  double? _aspectRatio;

  void setAspectRatio(double? ratio) {
    setState(() {
      _aspectRatio = ratio;
      _updateCropRect();
    });
  }

  void _updateCropRect() {
    if (_imageSize == Size.zero) return;

    final center = Offset(_imageSize.width / 2, _imageSize.height / 2);
    final maxSize = min(_imageSize.width, _imageSize.height) * 0.8;

    double width, height;

    if (_aspectRatio != null) {
      if (_aspectRatio! > 1) {
        width = maxSize;
        height = maxSize / _aspectRatio!;
      } else {
        height = maxSize;
        width = maxSize * _aspectRatio!;
      }
    } else {
      width = _cropRect.width;
      height = _cropRect.height;
    }

    _cropRect = Rect.fromCenter(center: center, width: width, height: height);

    _constrainCropRect();
    widget.onCropRectChanged(_cropRect, _imageSize);
  }

  void _constrainCropRect() {
    double left = _cropRect.left;
    double top = _cropRect.top;
    double width = _cropRect.width;
    double height = _cropRect.height;

    // Ensure crop rect stays within image bounds
    if (left < 0) left = 0;
    if (top < 0) top = 0;
    if (left + width > _imageSize.width) {
      if (_aspectRatio != null) {
        width = _imageSize.width - left;
        height = width / _aspectRatio!;
      } else {
        width = _imageSize.width - left;
      }
    }
    if (top + height > _imageSize.height) {
      if (_aspectRatio != null) {
        height = _imageSize.height - top;
        width = height * _aspectRatio!;
      } else {
        height = _imageSize.height - top;
      }
    }

    _cropRect = Rect.fromLTWH(left, top, width, height);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Image
            Positioned.fill(
              child: Image.file(widget.imageFile, fit: BoxFit.contain),
            ),
            // Crop overlay
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate actual image size within the container
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _calculateImageSize(constraints);
                  });

                  return CustomPaint(
                    painter: CropOverlayPainter(
                      cropRect: _cropRect,
                      imageSize: _imageSize,
                      containerSize: constraints.biggest,
                    ),
                  );
                },
              ),
            ),
            // Crop handles
            if (_imageSize != Size.zero) ..._buildCropHandles(),
          ],
        );
      },
    );
  }

  void _calculateImageSize(BoxConstraints constraints) {
    // This is a simplified calculation - you might need to adjust based on your image's aspect ratio
    final containerSize = constraints.biggest;

    // For now, assume the image fills the container proportionally
    if (_imageSize == Size.zero) {
      setState(() {
        _imageSize = containerSize;
        _updateCropRect();
      });
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
      switch (cornerIndex) {
        case 0: // Top-left
          _cropRect = Rect.fromLTRB(
            _cropRect.left + delta.dx,
            _cropRect.top + delta.dy,
            _cropRect.right,
            _cropRect.bottom,
          );
          break;
        case 1: // Top-right
          _cropRect = Rect.fromLTRB(
            _cropRect.left,
            _cropRect.top + delta.dy,
            _cropRect.right + delta.dx,
            _cropRect.bottom,
          );
          break;
        case 2: // Bottom-left
          _cropRect = Rect.fromLTRB(
            _cropRect.left + delta.dx,
            _cropRect.top,
            _cropRect.right,
            _cropRect.bottom + delta.dy,
          );
          break;
        case 3: // Bottom-right
          _cropRect = Rect.fromLTRB(
            _cropRect.left,
            _cropRect.top,
            _cropRect.right + delta.dx,
            _cropRect.bottom + delta.dy,
          );
          break;
      }

      if (_aspectRatio != null) {
        _maintainAspectRatio(cornerIndex);
      }

      _constrainCropRect();
      widget.onCropRectChanged(_cropRect, _imageSize);
    });
  }

  void _maintainAspectRatio(int cornerIndex) {
    final center = _cropRect.center;
    final width = _cropRect.width;
    final height = width / _aspectRatio!;

    _cropRect = Rect.fromCenter(center: center, width: width, height: height);
  }

  void _handleCenterDrag(Offset delta) {
    setState(() {
      _cropRect = _cropRect.translate(delta.dx, delta.dy);
      _constrainCropRect();
      widget.onCropRectChanged(_cropRect, _imageSize);
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
