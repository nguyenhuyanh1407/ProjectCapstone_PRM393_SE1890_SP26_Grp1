import 'package:flutter/material.dart';

class GuideDashboardPage extends StatelessWidget {
  const GuideDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guide Dashboard')),
      body: const Center(child: Text('Guide Dashboard Page')),
    );
  }
}
