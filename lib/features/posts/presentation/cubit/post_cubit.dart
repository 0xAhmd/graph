import 'dart:io';
import 'package:bloc/bloc.dart';
import '../../domain/entities/comment.dart';
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
    } catch (e) {
      emit(PostError(errMessage: e.toString()));
    }
  }

  // Optimistic update for adding comments
  Future<void> addComment(String postId, Comment comment) async {
    final currentState = state;
    if (currentState is PostLoaded) {
      // Optimistically update UI first
      final updatedPosts = currentState.posts.map((post) {
        if (post.id == postId) {
          return post.copyWith(comments: [...post.comments, comment]);
        }
        return post;
      }).toList();

      emit(PostLoaded(posts: updatedPosts));

      try {
        // Then sync with backend
        await postRepo.addComments(postId, comment);
      } catch (e) {
        // Revert optimistic update on error
        emit(PostLoaded(posts: currentState.posts));
        emit(PostError(errMessage: e.toString()));
      }
    }
  }

  Future<void> deleteComment(String postId, String commentId) async {
    final currentState = state;
    if (currentState is PostLoaded) {
      Comment? deletedComment;

      // Optimistically update UI
      final updatedPosts = currentState.posts.map((post) {
        if (post.id == postId) {
          // Try to find the comment manually
          for (final comment in post.comments) {
            if (comment.id.trim() == commentId.trim()) {
              deletedComment = comment;
              break;
            }
          }

          if (deletedComment == null) {
            emit(PostError(errMessage: 'Comment not found in local state'));
            return post;
          }

          final updatedComments = post.comments
              .where((comment) => comment.id.trim() != commentId.trim())
              .toList();

          return post.copyWith(comments: updatedComments);
        }
        return post;
      }).toList();

      emit(PostLoaded(posts: updatedPosts));

      try {
        // Sync with backend
        await postRepo.deleteComment(postId, commentId);
      } catch (e) {
        // Revert if deletion failed
        if (deletedComment != null) {
          final revertedPosts = updatedPosts.map((post) {
            if (post.id == postId) {
              return post.copyWith(
                comments: [...post.comments, deletedComment!],
              );
            }
            return post;
          }).toList();

          emit(PostLoaded(posts: revertedPosts));
        } else {
          emit(PostLoaded(posts: currentState.posts));
        }

        emit(PostError(errMessage: 'Error deleting comment: $e'));
      }
    }
  }

  Future<void> editComment(
    String postId,
    String commentId,
    String newText,
  ) async {
    final currentState = state;
    if (currentState is PostLoaded) {
      // Store the old comment for potential rollback
      Comment? oldComment;

      // Optimistically update UI first
      final updatedPosts = currentState.posts.map((post) {
        if (post.id == postId) {
          final commentIndex = post.comments.indexWhere(
            (c) => c.id == commentId,
          );
          if (commentIndex != -1) {
            oldComment = post.comments[commentIndex];
            final updatedComment = Comment(
              postId: postId,
              id: oldComment!.id,
              userId: oldComment!.userId,
              userName: oldComment!.userName,
              text: newText,
              timestamp: DateTime.now(),
            );
            final updatedComments = List<Comment>.from(post.comments);
            updatedComments[commentIndex] = updatedComment;
            return post.copyWith(comments: updatedComments);
          }
        }
        return post;
      }).toList();

      emit(PostLoaded(posts: updatedPosts));

      try {
        // Then sync with backend
        await postRepo.editComment(postId, commentId, newText);
      } catch (e) {
        // Revert optimistic update on error
        if (oldComment != null) {
          final revertedPosts = updatedPosts.map((post) {
            if (post.id == postId) {
              final commentIndex = post.comments.indexWhere(
                (c) => c.id == commentId,
              );
              if (commentIndex != -1) {
                final revertedComments = List<Comment>.from(post.comments);
                revertedComments[commentIndex] = oldComment!;
                return post.copyWith(comments: revertedComments);
              }
            }
            return post;
          }).toList();
          emit(PostLoaded(posts: revertedPosts));
        } else {
          emit(PostLoaded(posts: currentState.posts));
        }
        emit(PostError(errMessage: e.toString()));
      }
    }
  }
}
