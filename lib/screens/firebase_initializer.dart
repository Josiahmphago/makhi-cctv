// lib/screens/firebase_initializer.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../firebase_options.dart';

class FirebaseInitializer {
  static Future<String?> initAndGetDashboardRoute() async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }

    final user = FirebaseAuth.instance.currentUser!;
    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);

    await userDoc.set({
      'displayName': 'Anonymous',
      'createdAt': FieldValue.serverTimestamp(),
      'roles': {
        'admin': false,
        'patrol': false,
        'resident': true,
      }
    }, SetOptions(merge: true));

    final snapshot = await userDoc.get();
    final roles = snapshot.data()?['roles'] ?? {};

    if (roles['admin'] == true) return '/admin_dashboard';
    if (roles['patrol'] == true) return '/patrol/dashboard';
    return '/main_dashboard'; // fallback
  }
}
