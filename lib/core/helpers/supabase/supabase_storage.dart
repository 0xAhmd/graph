import 'dart:io';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart';

class SupabaseStorageService {
  static final _client = Supabase.instance.client;
  static const String bucketName = 'images'; // reuse the working bucket

  static Future<String?> uploadPostImage(File file, String postId) async {
    try {
      final fileExt = extension(file.path);
      final filePath = 'posts/$postId$fileExt';

      final fileBytes = await file.readAsBytes();
      final mimeType = lookupMimeType(file.path);

      await _client.storage
          .from(bucketName)
          .uploadBinary(
            filePath,
            fileBytes,
            fileOptions: FileOptions(contentType: mimeType, upsert: true),
          );

      final publicUrl = _client.storage.from(bucketName).getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  static Future<void> deletePostImage(String postId, String fileExt) async {
    try {
      final filePath =
          'posts/$postId$fileExt'; // match upload path here as well
      await _client.storage.from(bucketName).remove([filePath]);
    } catch (e) {
      print('Error deleting post image: $e');
    }
  }
}
