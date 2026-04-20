
import 'package:flutter/material.dart';

class PatrolAssignmentsScreen extends StatelessWidget {
  const PatrolAssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Patrol Assignments')),
      body: Center(child: Text('List of patrol assignments')),
    );
  }
}
