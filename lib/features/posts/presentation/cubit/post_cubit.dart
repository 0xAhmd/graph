import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:ig_mate/features/posts/domain/entities/post_entity.dart';
import 'package:ig_mate/features/posts/domain/repo/post_repo.dart';
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

  Future<void> deletePost(Post post) async {
    emit(PostLoading());
    try {
      String? ext;
      if (post.imageUrl.isNotEmpty) {
        ext = '.' + Uri.parse(post.imageUrl).path.split('.').last;
      }

      await postRepo.deletePost(post.id, imageExt: ext);
      await fetchAllPosts();
    } catch (e) {
      emit(PostError(errMessage: 'Error deleting post: $e'));
    }
  }
}
