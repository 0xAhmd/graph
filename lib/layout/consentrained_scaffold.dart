import 'package:flutter/material.dart';

class ConstrainedScaffold extends StatelessWidget {
  const ConstrainedScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.drawer,
  });
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      drawer: drawer,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: body,
        ),
      ),
    );
  }
}
