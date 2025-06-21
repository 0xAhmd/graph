// lib/features/stories/presentation/pages/story_viewer_page.dart
// cspell:disable
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ig_mate/features/stories/domain/entities/story.dart';
import 'package:ig_mate/features/stories/presentation/cubit/story_cubit.dart';
import 'package:ig_mate/features/stories/presentation/widgets/story_content.dart';
import 'package:ig_mate/features/stories/presentation/widgets/story_header.dart';
import 'package:ig_mate/features/stories/presentation/widgets/story_progress_inidcator.dart';
import 'dart:async';

import '../../../auth/presentation/cubit/cubit/auth_cubit.dart';


class StoryViewerPage extends StatefulWidget {
  final List<StoryEntity> stories;
  final int initialIndex;

  const StoryViewerPage({
    super.key,
    required this.stories,
    this.initialIndex = 0,
  });

  @override
  State<StoryViewerPage> createState() => _StoryViewerPageState();
}

class _StoryViewerPageState extends State<StoryViewerPage>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  late Timer _storyTimer;

  int _currentStoryIndex = 0;
  bool _isPaused = false;
  bool _isLongPressing = false;

  static const Duration _storyDuration = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _currentStoryIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentStoryIndex);
    _progressController = AnimationController(
      duration: _storyDuration,
      vsync: this,
    );

    _startStoryTimer();
    _markCurrentStoryAsViewed();
  }

  @override
  void dispose() {
    _storyTimer.cancel();
    _progressController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _startStoryTimer() {
    _progressController.reset();
    _progressController.forward();

    _storyTimer = Timer(_storyDuration, () {
      if (!_isPaused && !_isLongPressing) {
        _nextStory();
      }
    });
  }

  void _pauseStory() {
    if (!_isPaused) {
      setState(() {
        _isPaused = true;
      });
      _storyTimer.cancel();
      _progressController.stop();
    }
  }

  void _resumeStory() {
    if (_isPaused) {
      setState(() {
        _isPaused = false;
      });
      _startStoryTimer();
    }
  }

  void _nextStory() {
    if (_currentStoryIndex < widget.stories.length - 1) {
      setState(() {
        _currentStoryIndex++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startStoryTimer();
      _markCurrentStoryAsViewed();
    } else {
      Navigator.pop(context);
    }
  }

  void _previousStory() {
    if (_currentStoryIndex > 0) {
      setState(() {
        _currentStoryIndex--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startStoryTimer();
      _markCurrentStoryAsViewed();
    }
  }

  void _markCurrentStoryAsViewed() {
    final currentUser = context.read<AuthCubit>().currentUser;
    if (currentUser != null) {
      final currentStory = widget.stories[_currentStoryIndex];
      if (!currentStory.viewers.contains(currentUser.uid)) {
        context.read<StoriesCubit>().markStoryAsViewed(
          currentStory.id,
          currentUser.uid,
        );
      }
    }
  }

  void _onStoryTap(TapDownDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tapPosition = details.globalPosition.dx;

    if (tapPosition < screenWidth * 0.3) {
      // Tap on left side - previous story
      _storyTimer.cancel();
      _previousStory();
    } else if (tapPosition > screenWidth * 0.7) {
      // Tap on right side - next story
      _storyTimer.cancel();
      _nextStory();
    }
    // Middle tap is handled by long press for pause/resume
  }

  void _showStoryOptions() {
    _pauseStory();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Story options
            ListTile(
              leading: const Icon(Icons.visibility),
              title: Text(
                'View Count: ${widget.stories[_currentStoryIndex].viewCount}',
              ),
              onTap: () {
                Navigator.pop(context);
                _showViewersList();
              },
            ),

            // Delete option (only for own stories)
            if (_canDeleteCurrentStory())
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Delete Story',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteStory();
                },
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    ).then((_) => _resumeStory());
  }

  bool _canDeleteCurrentStory() {
    final currentUser = context.read<AuthCubit>().currentUser;
    return currentUser != null &&
        widget.stories[_currentStoryIndex].userId == currentUser.uid;
  }

  void _deleteStory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Story'),
        content: const Text('Are you sure you want to delete this story?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<StoriesCubit>().deleteStory(
                widget.stories[_currentStoryIndex].id,
              );
              Navigator.pop(context); // Close story viewer
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showViewersList() {
    _pauseStory();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.8,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${widget.stories[_currentStoryIndex].viewCount} views',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: widget.stories[_currentStoryIndex].viewers.length,
                  itemBuilder: (context, index) {
                    final viewerId =
                        widget.stories[_currentStoryIndex].viewers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          viewerId.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                      title: Text(viewerId), // You might want to fetch username
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) => _resumeStory());
  }

  Color _getColorFromHex(String hexColor) {
    return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: _onStoryTap,
        onLongPressStart: (_) {
          setState(() {
            _isLongPressing = true;
          });
          _pauseStory();
        },
        onLongPressEnd: (_) {
          setState(() {
            _isLongPressing = false;
          });
          _resumeStory();
        },
        child: Stack(
          children: [
            // Story content
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentStoryIndex = index;
                });
                _startStoryTimer();
                _markCurrentStoryAsViewed();
              },
              itemCount: widget.stories.length,
              itemBuilder: (context, index) {
                final story = widget.stories[index];

                return Container(
                  color: story.backgroundColor != null
                      ? _getColorFromHex(story.backgroundColor!)
                      : Colors.black,
                  child: StoryContentWidget(story: story),
                );
              },
            ),

            // Progress indicators
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              child: StoryProgressIndicator(
                storyCount: widget.stories.length,
                currentIndex: _currentStoryIndex,
                animationController: _progressController,
              ),
            ),

            // Story header
            Positioned(
              top: MediaQuery.of(context).padding.top + 50,
              left: 16,
              right: 16,
              child: StoryHeader(
                story: widget.stories[_currentStoryIndex],
                onMorePressed: _showStoryOptions,
                onClosePressed: () => Navigator.pop(context),
              ),
            ),

            // Pause indicator
            if (_isPaused || _isLongPressing)
              const Positioned.fill(
                child: Center(
                  child: Icon(
                    Icons.pause_circle_filled,
                    color: Colors.white,
                    size: 80,
                  ),
                ),
              ),

            // Navigation areas (invisible)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: MediaQuery.of(context).size.width * 0.3,
              child: Container(color: Colors.transparent),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: MediaQuery.of(context).size.width * 0.3,
              child: Container(color: Colors.transparent),
            ),
          ],
        ),
      ),
    );
  }
}
