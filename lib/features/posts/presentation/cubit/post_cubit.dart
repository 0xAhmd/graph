import 'dart:io';
import 'package:bloc/bloc.dart';
import '../../domain/entities/post_entity.dart';
import '../../domain/repo/post_repo.dart';
import 'package:meta/meta.dart';

part 'post_state.dart';

class PostCubit extends Cubit<PostState> {
  final PostRepoContract postRepo;

  PostCubit({required this.postRepo}) : super(PostInitial());

  Future<void> fetchAllPosts() async {
    emit(PostLoading());
    try {
      final posts = await postRepo.fetchAllPosts();
      emit(PostLoaded(posts: posts));
    } catch (e) {
      emit(PostError(errMessage: "Failed to load posts: $e"));
    }
  }

  Future<void> createPost({required Post post, File? imageFile}) async {
    emit(PostUploading());

    try {
      String imageUrl = post.imageUrl;

      if (imageFile != null) {
        final uploadedUrl = await postRepo.uploadPostImage(imageFile, post.id);
        if (uploadedUrl == null) {
          emit(PostError(errMessage: 'Image upload failed'));
          return;
        }
        imageUrl = uploadedUrl;
      }

      final postToSave = post.copyWith(imageUrl: imageUrl);
      await postRepo.createPost(postToSave);
      emit(PostUploaded());
      await fetchAllPosts();
    } catch (e) {
      emit(PostError(errMessage: 'Error creating post: $e'));
    }
  }

  Future<void> deletePost(String postId) async {
    emit(PostLoading());
    try {
      await postRepo.deletePost(postId);
      await fetchAllPosts();
    } catch (e) {
      emit(PostError(errMessage: 'Error deleting post: $e'));
    }
  }

  Future<void> toggleLikes(String postId, String userId) async {
    try {
      await postRepo.toggleLikes(postId, userId);
      // Optionally refresh posts to get updated like count
      // await fetchAllPosts();
    } catch (e) {
      emit(PostError(errMessage: e.toString()));
    }
  }

  // Method to update comment count when comments are added/removed
  Future<void> updateCommentCount(String postId, int count) async {
    final currentState = state;
    if (currentState is PostLoaded) {
      // Optimistically update UI
      final updatedPosts = currentState.posts.map((post) {
        if (post.id == postId) {
          return post.copyWith(commentCount: count);
        }
        return post;
      }).toList();

      emit(PostLoaded(posts: updatedPosts));

      try {
        // Sync with backend
        await postRepo.updateCommentCount(postId, count);
      } catch (e) {
        // Revert on error
        emit(PostLoaded(posts: currentState.posts));
        emit(PostError(errMessage: e.toString()));
      }
    }
  }
}
