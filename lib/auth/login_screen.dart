// lib/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'register_screen.dart'; // ✅ ADD THIS

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _loading = false;
  bool _obscure = true;

  /// =====================================================
  /// Ensure Firestore profile exists
  /// =====================================================
  Future<Map<String, dynamic>> _ensureUserProfile(User user) async {
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);

    final doc = await ref.get();

    if (!doc.exists) {
      await ref.set({
        'createdAt': FieldValue.serverTimestamp(),
        'areaId': 'Default',
        'email': user.email,
        'roles': {
  'community': true,
  'patrol': true,
  'escort': true,
  'towing': true,
}
      });
    }

    final updated = await ref.get();
    return updated.data() ?? {};
  }

  /// =====================================================
  /// Role redirect
  /// =====================================================
  void _redirect(Map<String, dynamic> roles) {
    if (!mounted) return;

    if (roles['admin'] == true) {
      Navigator.pushReplacementNamed(context, '/stats');
    } else if (roles['police'] == true) {
      Navigator.pushReplacementNamed(context, '/police');
    } else if (roles['patrol'] == true) {
      Navigator.pushReplacementNamed(context, '/patrol/dashboard');
    } else if (roles['escort'] == true) {
      Navigator.pushReplacementNamed(context, '/escort/dashboard');
    } else if (roles['towing'] == true) {
      Navigator.pushReplacementNamed(context, '/breakdown/inbox');
    } else {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  /// =====================================================
  /// Email login
  /// =====================================================
  Future<void> _loginEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final credential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final data = await _ensureUserProfile(credential.user!);
      final roles = Map<String, dynamic>.from(data['roles'] ?? {});

      _redirect(roles);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Login failed")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  /// =====================================================
  /// Guest login
  /// =====================================================
  Future<void> _guestLogin() async {
    setState(() => _loading = true);

    try {
      final credential = await FirebaseAuth.instance.signInAnonymously();

      final data = await _ensureUserProfile(credential.user!);
      final roles = Map<String, dynamic>.from(data['roles'] ?? {});

      _redirect(roles);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Guest login failed")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  /// =====================================================
  /// UI
  /// =====================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Makhi Login")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Text(
                  "Welcome to Makhi",
                  style: TextStyle(fontSize: 22),
                ),

                const SizedBox(height: 20),

                /// EMAIL
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: "Email"),
                  validator: (v) =>
                      v == null || v.isEmpty ? "Enter email" : null,
                ),

                const SizedBox(height: 12),

                /// PASSWORD
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: "Password",
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscure = !_obscure;
                        });
                      },
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? "Enter password" : null,
                ),

                const SizedBox(height: 20),

                /// LOGIN BUTTON
                if (_loading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton.icon(
                    icon: const Icon(Icons.login),
                    label: const Text("Login"),
                    onPressed: _loginEmail,
                  ),

                const SizedBox(height: 12),

                /// CREATE ACCOUNT BUTTON ✅
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RegisterScreen(),
                      ),
                    );
                  },
                  child: const Text("Create Account"),
                ),

                const SizedBox(height: 12),

                /// GUEST LOGIN
                OutlinedButton.icon(
                  icon: const Icon(Icons.person_outline),
                  label: const Text("Continue as Guest"),
                  onPressed: _guestLogin,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}