import 'package:flutter/material.dart';

class BlockListPage extends StatelessWidget {
  const BlockListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        title: const Text("Blocked Users"),
      ),
    );
  }
}
