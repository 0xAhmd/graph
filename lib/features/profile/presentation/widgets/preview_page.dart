import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ig_mate/features/posts/domain/entities/post_entity.dart';
import 'package:ig_mate/features/posts/presentation/cubit/post_cubit.dart';
import 'package:ig_mate/features/posts/presentation/widgets/post_tile.dart';
import 'package:ig_mate/layout/constrained_scaffold.dart';

class PostPreviewPage extends StatefulWidget {
  final List<Post> userPosts;
  final int initialIndex;
  final String userId;

  const PostPreviewPage({
    super.key,
    required this.userPosts,
    required this.initialIndex,
    required this.userId,
  });

  @override
  State<PostPreviewPage> createState() => _PostPreviewPageState();
}

class _PostPreviewPageState extends State<PostPreviewPage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedScaffold(
      appBar: AppBar(
        title: const Text('Posts'),
        centerTitle: true,
        foregroundColor: Theme.of(context).colorScheme.primary,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          // Show post counter
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                '${_currentIndex + 1}/${widget.userPosts.length}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<PostCubit, PostState>(
        builder: (context, state) {
          if (state is PostLoaded) {
            // Get updated user posts
            final updatedUserPosts = state.posts
                .where((post) => post.userId == widget.userId)
                .toList();

            if (updatedUserPosts.isEmpty) {
              return const Center(
                child: Text('No posts available'),
              );
            }

            return PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: updatedUserPosts.length,
              itemBuilder: (context, index) {
                final post = updatedUserPosts[index];
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: PostTile(
                      post: post,
                      onDeletePressed: () {
                        context.read<PostCubit>().deletePost(post.id);
                        // If this was the last post, go back
                        if (updatedUserPosts.length == 1) {
                          Navigator.of(context).pop();
                        } else {
                          // Adjust current index if needed
                          if (_currentIndex >= updatedUserPosts.length - 1) {
                            setState(() {
                              _currentIndex = updatedUserPosts.length - 2;
                            });
                            _pageController.animateToPage(
                              _currentIndex,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        }
                      },
                    ),
                  ),
                );
              },
            );
          } else if (state is PostLoading) {
            return const Center(
              child: CupertinoActivityIndicator(),
            );
          } else if (state is PostError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error loading posts',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<PostCubit>().fetchAllPosts();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return const Center(
            child: Text('No posts available'),
          );
        },
      ),
    );
  }
}