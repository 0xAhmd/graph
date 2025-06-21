import 'package:flutter/material.dart';

class StoryProgressIndicator extends StatelessWidget {
  final int storyCount;
  final int currentIndex;
  final AnimationController animationController;

  const StoryProgressIndicator({
    super.key,
    required this.storyCount,
    required this.currentIndex,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(storyCount, (index) {
        return Expanded(
          child: Container(
            height: 3,
            margin: EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(1.5),
            ),
            child: AnimatedBuilder(
              animation: animationController,
              builder: (context, child) {
                double progress = 0.0;

                if (index < currentIndex) {
                  // Completed stories
                  progress = 1.0;
                } else if (index == currentIndex) {
                  // Current story
                  progress = animationController.value;
                } else {
                  // Upcoming stories
                  progress = 0.0;
                }

                return LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 3,
                );
              },
            ),
          ),
        );
      }),
    );
  }
}
