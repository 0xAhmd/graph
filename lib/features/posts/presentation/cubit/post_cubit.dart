import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:ig_mate/core/helpers/supabase/supabase_storage.dart';
import 'package:ig_mate/features/posts/domain/entities/post_entity.dart';
import 'package:ig_mate/features/posts/domain/repo/post_repo.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

part 'post_state.dart';

class PostCubit extends Cubit<PostState> {
  final PostRepoContract postRepo;
  PostCubit({required this.postRepo}) : super(PostInitial());

  /// Fetch all posts
  Future<void> fetchAllPosts() async {
    emit(PostLoading());
    try {
      final posts = await postRepo.fetchAllPosts();
      emit(PostLoaded(posts: posts));
    } catch (e) {
      emit(PostError(errMessage: "Failed to load posts: $e"));
    }
  }

  /// Create a new post with an optional image
  Future<void> createPost({
    required String userId,
    required String userName,
    required String text,
    File? imageFile,
  }) async {
    emit(PostUploading());

    final postId = const Uuid().v4();
    String imageUrl = '';

    try {
      if (imageFile != null) {
        final uploadedUrl = await SupabaseStorageService.uploadPostImage(
          imageFile,
          postId,
        );
        if (uploadedUrl == null) {
          emit(PostError(errMessage: 'Image upload failed'));
          return;
        }
        imageUrl = uploadedUrl;
      }

      final post = Post(
        id: postId,
        userId: userId,
        userName: userName,
        text: text,
        imageUrl: imageUrl,
        timeStamp: DateTime.now(),
      );

      await postRepo.createPost(post);
      await fetchAllPosts(); // Refresh post list
    } catch (e) {
      emit(PostError(errMessage: 'Error creating post: $e'));
    }
  }

  /// Delete a post and its image from Supabase
  Future<void> deletePost(Post post) async {
    emit(PostLoading());
    try {
      if (post.imageUrl.isNotEmpty) {
        final ext = Uri.parse(post.imageUrl).path.split('.').last;
        await SupabaseStorageService.deletePostImage(post.id, '.$ext');
      }

      await postRepo.deletePost(post.id);
      await fetchAllPosts(); // Refresh post list
    } catch (e) {
      emit(PostError(errMessage: 'Error deleting post: $e'));
    }
  }
}
