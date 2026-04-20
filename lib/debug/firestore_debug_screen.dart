import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FirestoreDebugScreen extends StatefulWidget {
  const FirestoreDebugScreen({super.key});

  @override
  State<FirestoreDebugScreen> createState() => _FirestoreDebugScreenState();
}

class _FirestoreDebugScreenState extends State<FirestoreDebugScreen> {
  String _log = 'Ready';

  void _set(String s) => setState(() => _log = s);

  Future<void> _checkAuth() async {
    final u = FirebaseAuth.instance.currentUser;
    _set('auth uid=${u?.uid} isAnon=${u?.isAnonymous} email=${u?.email}');
  }

  Future<void> _writeTest() async {
    try {
      final u = FirebaseAuth.instance.currentUser;
      if (u == null) throw Exception('Not logged in');

      final ref = await FirebaseFirestore.instance.collection('debug_writes').add({
        'uid': u.uid,
        'at': FieldValue.serverTimestamp(),
        'msg': 'hello from device',
      });

      _set('✅ WRITE OK: debug_writes/${ref.id}');
    } catch (e) {
      _set('❌ WRITE FAILED: $e');
    }
  }

  Future<void> _readTest() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('debug_writes').limit(1).get();
      _set('✅ READ OK: docs=${snap.docs.length}');
    } catch (e) {
      _set('❌ READ FAILED: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firestore Debug')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(onPressed: _checkAuth, child: const Text('Check Auth')),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _writeTest, child: const Text('Write Test')),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _readTest, child: const Text('Read Test')),
            const SizedBox(height: 16),
            Text(_log),
          ],
        ),
      ),
    );
  }
}
