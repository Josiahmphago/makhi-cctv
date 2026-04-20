import 'package:flutter/material.dart';

class AssignGroupContactsScreen extends StatelessWidget {
  const AssignGroupContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assign Group Contacts')),
      body: const Center(child: Text('Assign groups to contacts here.')),
    );
  }
}
