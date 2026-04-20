import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MakhiAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showLogout;
  final bool logoutOnLeft;

  const MakhiAppBar({
    super.key,
    required this.title,
    this.showLogout = true,
    this.logoutOnLeft = false,
  });

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return AppBar(
      title: Text(title),
      centerTitle: true,

      // LEFT SIDE
      leading: (logoutOnLeft && user != null && showLogout)
          ? IconButton(
              icon: const Icon(Icons.logout),
              tooltip: "Logout",
              onPressed: () => _logout(context),
            )
          : null,

      // RIGHT SIDE
      actions: [
        if (!logoutOnLeft && user != null && showLogout)
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: () => _logout(context),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}