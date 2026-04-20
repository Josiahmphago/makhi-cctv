import 'package:flutter/material.dart';

class ReporterDashboardScreen extends StatelessWidget {
  const ReporterDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reporter Dashboard')),
      body: const Center(child: Text('Welcome, Reporter! Features coming soon.')),
    );
  }
}
