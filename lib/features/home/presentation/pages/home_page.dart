import 'package:flutter/material.dart';

import 'package:ig_mate/features/home/presentation/widgets/home_drawer.dart';
import 'package:ig_mate/features/posts/presentation/pages/upload_post_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const UploadPostPage()),
            ),
            icon: const Icon(Icons.add),
          ),
        ],
        centerTitle: true,
        title: const Text("Home"),
      ),
      drawer: const HomeDrawer(),
    );
  }
}
