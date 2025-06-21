import '../entities/story.dart';

abstract class StoriesRepository {
  Future<List<StoryEntity>> getActiveStories();
  Future<List<StoryEntity>> getUserStories(String userId);
  Future<StoryEntity> createStory(StoryEntity story);
  Future<void> deleteStory(String storyId);
  Future<void> markStoryAsViewed(String storyId, String viewerId);
  Future<List<String>> getStoryViewers(String storyId);
  Future<String> uploadStoryImage(String imagePath);
  Stream<List<StoryEntity>> getStoriesStream();
}
