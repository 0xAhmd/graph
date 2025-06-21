// lib/features/stories/presentation/cubit/stories_state.dart
import 'package:equatable/equatable.dart';
import 'package:ig_mate/features/stories/domain/entities/story.dart';


abstract class StoriesState extends Equatable {
  const StoriesState();

  @override
  List<Object?> get props => [];
}

class StoriesInitial extends StoriesState {}

class StoriesLoading extends StoriesState {}

class StoriesLoaded extends StoriesState {
  final List<StoryEntity> stories;
  final Map<String, List<StoryEntity>> groupedStories;

  const StoriesLoaded({required this.stories, required this.groupedStories});

  @override
  List<Object?> get props => [stories, groupedStories];
}

class StoriesError extends StoriesState {
  final String message;

  const StoriesError(this.message);

  @override
  List<Object?> get props => [message];
}

class StoryCreating extends StoriesState {}

class StoryCreated extends StoriesState {
  final StoryEntity story;

  const StoryCreated(this.story);

  @override
  List<Object?> get props => [story];
}

class StoryDeleting extends StoriesState {}

class StoryDeleted extends StoriesState {}
