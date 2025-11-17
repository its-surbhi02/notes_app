// lib/features/advanced/profile/screens/change_password_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  void _show(String m) => Fluttertoast.showToast(msg: m);

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _show("Not logged in");
      return;
    }

    // check provider
    final providers = user.providerData.map((p) => p.providerId).toList();
    if (!providers.contains('password')) {
      _show("Password change not available for social logins. Use provider account settings.");
      return;
    }

    final current = _current.text.trim();
    final nwe = _new.text.trim();
    final confirm = _confirm.text.trim();

    if (current.isEmpty || nwe.isEmpty) {
      _show("Please fill all fields");
      return;
    }
    if (nwe.length < 6) {
      _show("New password must be at least 6 characters.");
      return;
    }
    if (nwe != confirm) {
      _show("Passwords do not match");
      return;
    }

    try {
      setState(() => _loading = true);
      final cred = EmailAuthProvider.credential(email: user.email!, password: current);
      await user.reauthenticateWithCredential(cred);

      await user.updatePassword(nwe);
      _show("Password updated");
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      _show(e.message ?? "Failed to update password");
    } catch (e) {
      _show("Error: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFFF46D3A);
    return Scaffold(
      appBar: AppBar(title: const Text("Change Password"), backgroundColor: primary),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("You will be required to enter your current password to change it.", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(controller: _current, obscureText: true, decoration: const InputDecoration(labelText: "Current Password")),
            const SizedBox(height: 8),
            TextField(controller: _new, obscureText: true, decoration: const InputDecoration(labelText: "New Password")),
            const SizedBox(height: 8),
            TextField(controller: _confirm, obscureText: true, decoration: const InputDecoration(labelText: "Confirm New Password")),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _changePassword,
              style: ElevatedButton.styleFrom(backgroundColor: primary, minimumSize: const Size.fromHeight(50)),
              child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text("Change Password"),
            ),
          ],
        ),
      ),
    );
  }
}
