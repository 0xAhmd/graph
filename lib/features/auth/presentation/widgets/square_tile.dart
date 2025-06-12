import 'package:flutter/material.dart';

class CustomSquareTile extends StatelessWidget {
  const CustomSquareTile({
    super.key,
    required this.onTap,
    required this.img,
    required this.title,
  });
  final String img;
  final void Function()? onTap;
  final String title;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),

        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.tertiary),
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(img, height: 45),
            const SizedBox(width: 20),
            Text(
              "Sign in with $title",
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
