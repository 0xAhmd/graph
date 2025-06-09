import 'package:flutter/material.dart';

import 'package:ig_mate/features/home/presentation/widgets/home_drawer.dart';

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
       
        centerTitle: true,
        title: const Text("Home Page"),
      ),
      drawer: const HomeDrawer(),
    );
  }
}
