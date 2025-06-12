import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ImageHelper {
  static Future<File?> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      return File(picked.path);
    }
    return null;
  }
}
