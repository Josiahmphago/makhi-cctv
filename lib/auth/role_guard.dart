import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoleGuard extends StatelessWidget {
  final Widget child;
  final String requiredRole;

  const RoleGuard({
    super.key,
    required this.child,
    required this.requiredRole,
  });

  Future<bool> _checkAccess() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      debugPrint("❌ No authenticated user");
      return false;
    }

    debugPrint("🔐 Logged in UID: ${user.uid}");

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    debugPrint("📄 User document exists: ${doc.exists}");

    if (!doc.exists) {
      debugPrint("❌ No Firestore user document found");
      return false;
    }

    final data = doc.data();
    debugPrint("📦 User data: $data");

    final roles = Map<String, dynamic>.from(data?['roles'] ?? {});
    final roleKey = requiredRole.toLowerCase();

    debugPrint("🎯 Required role: $roleKey");
    debugPrint("🧭 User roles map: $roles");

    /// ===============================
    /// 🔐 ROLE ACCESS RULES (MAKHI)
    /// ===============================

    /// ADMIN → access everything
    if (roles['admin'] == true) {
      debugPrint("👑 Admin override granted");
      return true;
    }

    /// DIRECT ROLE MATCH
    if (roles[roleKey] == true) {
      debugPrint("✅ Direct role match granted");
      return true;
    }

    /// COMMUNITY ACCESS
    if (roleKey == 'community' && roles['community'] == true) {
      debugPrint("👥 Community access granted");
      return true;
    }

    /// OPTIONAL HIERARCHY
    /// Police can access patrol tools
    if (roleKey == 'patrol' && roles['police'] == true) {
      debugPrint("🚓 Police override patrol access");
      return true;
    }

    /// Patrol can access escort
    if (roleKey == 'escort' && roles['patrol'] == true) {
      debugPrint("🛡 Patrol override escort access");
      return true;
    }

    debugPrint("❌ Access denied");

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkAccess(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text("Error: ${snapshot.error}"),
            ),
          );
        }

        if (snapshot.data == true) {
          return child;
        }

        return const Scaffold(
          body: Center(
            child: Text(
              "Access Denied",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }
}