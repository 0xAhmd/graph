// lib/features/stories/presentation/cubit/stories_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ig_mate/features/stories/domain/entities/story.dart';
import 'dart:async';

import 'package:ig_mate/features/stories/presentation/cubit/story_state.dart';

import '../../domain/repo/story_repo_interface.dart';

class StoriesCubit extends Cubit<StoriesState> {
  final StoriesRepository _repository;
  StreamSubscription<List<StoryEntity>>? _storiesSubscription;

  StoriesCubit({required StoriesRepository repository})
    : _repository = repository,
      super(StoriesInitial());

  void fetchStories() {
    emit(StoriesLoading());

    _storiesSubscription?.cancel();
    _storiesSubscription = _repository.getStoriesStream().listen(
      (stories) {
        final groupedStories = _groupStoriesByUser(stories);
        emit(StoriesLoaded(stories: stories, groupedStories: groupedStories));
      },
      onError: (error) {
        emit(StoriesError(error.toString()));
      },
    );
  }

  Future<void> createTextStory({
    required String userId,
    required String username,
    String? userProfileImageUrl,
    required String content,
    String? backgroundColor,
    String? textColor,
    double? fontSize,
    String? fontWeight,
  }) async {
    try {
      emit(StoryCreating());

      final now = DateTime.now();
      final story = StoryEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        username: username,
        userProfileImageUrl: userProfileImageUrl,
        content: content,
        backgroundColor: backgroundColor ?? '#000000',
        textColor: textColor ?? '#FFFFFF',
        fontSize: fontSize ?? 16.0,
        fontWeight: fontWeight ?? 'normal',
        createdAt: now,
        expiresAt: now.add(const Duration(hours: 24)),
        isActive: true,
        viewers: [],
        viewCount: 0,
      );

      final createdStory = await _repository.createStory(story);
      emit(StoryCreated(createdStory));

      // Refresh stories
      fetchStories();
    } catch (e) {
      emit(StoriesError('Failed to create story: $e'));
    }
  }

  Future<void> createImageStory({
    required String userId,
    required String username,
    String? userProfileImageUrl,
    required String imagePath,
    String? content,
  }) async {
    try {
      emit(StoryCreating());

      // Upload image first
      final imageUrl = await _repository.uploadStoryImage(imagePath);

      final now = DateTime.now();
      final story = StoryEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        username: username,
        userProfileImageUrl: userProfileImageUrl,
        content: content,
        imageUrl: imageUrl,
        createdAt: now,
        expiresAt: now.add(const Duration(hours: 24)),
        isActive: true,
        viewers: [],
        viewCount: 0,
      );

      final createdStory = await _repository.createStory(story);
      emit(StoryCreated(createdStory));

      // Refresh stories
      fetchStories();
    } catch (e) {
      emit(StoriesError('Failed to create story: $e'));
    }
  }

  Future<void> deleteStory(String storyId) async {
    try {
      emit(StoryDeleting());
      await _repository.deleteStory(storyId);
      emit(StoryDeleted());

      // Refresh stories
      fetchStories();
    } catch (e) {
      emit(StoriesError('Failed to delete story: $e'));
    }
  }

  Future<void> markStoryAsViewed(String storyId, String viewerId) async {
    try {
      await _repository.markStoryAsViewed(storyId, viewerId);
    } catch (e) {
      // Silently handle view errors
    }
  }

  Map<String, List<StoryEntity>> _groupStoriesByUser(
    List<StoryEntity> stories,
  ) {
    final Map<String, List<StoryEntity>> grouped = {};

    for (final story in stories) {
      if (grouped.containsKey(story.userId)) {
        grouped[story.userId]!.add(story);
      } else {
        grouped[story.userId] = [story];
      }
    }

    return grouped;
  }

  @override
  Future<void> close() {
    _storiesSubscription?.cancel();
    return super.close();
  }
}
