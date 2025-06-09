import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart';

class SupabaseStorageService {
  static final _client = Supabase.instance.client;
  static const String bucketName = 'post-images';

  static Future<String?> uploadPostImage(File file, String postId) async {
    try {
      final fileExt = extension(file.path);
      final filePath = 'posts/$postId$fileExt';

      await _client.storage
          .from(bucketName)
          .upload(filePath, file, fileOptions: const FileOptions(upsert: true));

      final publicUrl = _client.storage.from(bucketName).getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  static Future<void> deletePostImage(String postId, String fileExt) async {
    try {
      final filePath = 'posts/$postId$fileExt';
      await _client.storage.from(bucketName).remove([filePath]);
    } catch (e) {
      print('Error deleting post image: $e');
    }
  }
}
