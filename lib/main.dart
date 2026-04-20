import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MakhiApp());
}

class MakhiApp extends StatelessWidget {
  const MakhiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Makhi CCTV",
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      onGenerateRoute: appOnGenerateRoute,
    );
  }
}