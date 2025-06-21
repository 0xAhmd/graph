// lib/features/stories/presentation/pages/story_viewer_page.dart
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
  Timer? _storyTimer;
  int _currentStoryIndex = 0;
  bool _isPaused = false;
  bool _showPauseIcon = false;

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
    _storyTimer?.cancel();
    _progressController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _startStoryTimer() {
    if (!mounted) return;

    _progressController.reset();
    _progressController.forward();

    _storyTimer?.cancel();
    _storyTimer = Timer(_storyDuration, () {
      if (!mounted) return;

      if (!_isPaused) {
        _nextStory();
      }
    });
  }

  void _pauseStory() {
    if (!mounted || _isPaused) return;

    setState(() {
      _isPaused = true;
      _showPauseIcon = true;
    });
    _storyTimer?.cancel();
    _progressController.stop();

    // Hide pause icon after 1 second
    Timer(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _showPauseIcon = false;
        });
      }
    });
  }

  void _resumeStory() {
    if (!mounted || !_isPaused) return;

    setState(() {
      _isPaused = false;
      _showPauseIcon = true;
    });
    _startStoryTimer();

    // Hide play icon after 1 second
    Timer(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _showPauseIcon = false;
        });
      }
    });
  }

  void _togglePlayPause() {
    if (_isPaused) {
      _resumeStory();
    } else {
      _pauseStory();
    }
  }

  void _nextStory() {
    if (!mounted) return;

    if (_currentStoryIndex < widget.stories.length - 1) {
      setState(() {
        _currentStoryIndex++;
        _isPaused = false;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startStoryTimer();
      _markCurrentStoryAsViewed();
    } else {
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _previousStory() {
    if (!mounted) return;

    if (_currentStoryIndex > 0) {
      setState(() {
        _currentStoryIndex--;
        _isPaused = false;
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
    if (!mounted) return;

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
    if (!mounted) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final tapPosition = details.globalPosition.dx;

    if (tapPosition < screenWidth * 0.2) {
      // Tap on left side - previous story
      _storyTimer?.cancel();
      _previousStory();
    } else if (tapPosition > screenWidth * 0.8) {
      // Tap on right side - next story
      _storyTimer?.cancel();
      _nextStory();
    } else {
      // Middle tap - toggle play/pause
      _togglePlayPause();
    }
  }

  void _showStoryOptions() {
    if (!mounted) return;

    // Pause the story when showing options
    final wasPaused = _isPaused;
    if (!_isPaused) {
      _storyTimer?.cancel();
      _progressController.stop();
      setState(() {
        _isPaused = true;
      });
    }

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

            // Show view count only for current user's own stories
            if (_canDeleteCurrentStory())
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
    ).then((_) {
      // Resume story if it wasn't paused before
      if (mounted && !wasPaused) {
        setState(() {
          _isPaused = false;
        });
        _startStoryTimer();
      }
    });
  }

  bool _canDeleteCurrentStory() {
    if (!mounted) return false;

    final currentUser = context.read<AuthCubit>().currentUser;
    return currentUser != null &&
        widget.stories[_currentStoryIndex].userId == currentUser.uid;
  }

  void _deleteStory() {
    if (!mounted) return;

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
    if (!mounted) return;

    // Pause the story when showing viewers list
    final wasPaused = _isPaused;
    if (!_isPaused) {
      _storyTimer?.cancel();
      _progressController.stop();
      setState(() {
        _isPaused = true;
      });
    }

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
    ).then((_) {
      // Resume story if it wasn't paused before
      if (mounted && !wasPaused) {
        setState(() {
          _isPaused = false;
        });
        _startStoryTimer();
      }
    });
  }

  Color _getColorFromHex(String hexColor) {
    return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthCubit>().currentUser;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: _onStoryTap,
        child: Stack(
          children: [
            // Story content
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                if (!mounted) return;
                setState(() {
                  _currentStoryIndex = index;
                  _isPaused = false;
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
                currentUserId: currentUser?.uid, // Safe null check
                onMorePressed: _showStoryOptions,
                onClosePressed: () {
                  if (mounted) {
                    Navigator.pop(context);
                  }
                },
              ),
            ),

            // Play/Pause indicator
            if (_showPauseIcon)
              Positioned.fill(
                child: Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isPaused ? Icons.play_arrow : Icons.pause,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),

            // Invisible tap areas for navigation hints
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: MediaQuery.of(context).size.width * 0.2,
              child: Container(color: Colors.transparent),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: MediaQuery.of(context).size.width * 0.2,
              child: Container(color: Colors.transparent),
            ),
          ],
        ),
      ),
    );
  }
}
