import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../admin/admin_dashboard_screen.dart';
import '../../patrol/patrol_request_screen.dart';
import '../../escort/escort_dashboard_screen.dart';
import '../../ui/main_dashboard.dart';

class _RoleBasedRouter extends StatelessWidget {
  const _RoleBasedRouter({super.key});

  Future<Widget> _determineDashboard() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
    }

    final uid = auth.currentUser!.uid;
    debugPrint('🔑 Current UID: $uid');

    String role = 'community';

    try {
      final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = snap.data();
      debugPrint('📄 User Firestore data: $data');

      if (data != null) {
        if (data['role'] is String) {
          role = (data['role'] as String).trim();
          debugPrint('✅ Role from string field: $role');
        } else if (data['roles'] is Map) {
          final roles = Map<String, dynamic>.from(data['roles']);
          if (roles['admin'] == true) role = 'admin';
          else if (roles['escort'] == true) role = 'escort';
          else if (roles['patrol'] == true) role = 'patrol';
          else role = 'community';
          debugPrint('✅ Role from roles map: $role');
        } else {
          debugPrint('⚠️ No valid role field found, using default "community"');
        }
      } else {
        debugPrint('❌ No user doc found in Firestore for UID $uid');
      }
    } catch (e) {
      debugPrint('❌ Error reading user role: $e');
    }

    switch (role) {
      case 'admin':
        return const AdminDashboardScreen();
      case 'escort':
        return const EscortDashboardScreen();
      case 'patrol':
        return const PatrolRequestScreen();
      default:
        return const MainDashboard(); // fallback to community
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _determineDashboard(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snap.hasError || snap.data == null) {
          return const Scaffold(body: Center(child: Text('Error loading role or no data.')));
        }
        return snap.data!;
      },
    );
  }
}
