// lib/features/advanced/profile/screens/edit_profile_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> currentData;
  const EditProfileScreen({super.key, required this.currentData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _firstController = TextEditingController();
  final _lastController = TextEditingController();
  final _mobileController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _firstController.text = widget.currentData['firstName'] ?? '';
    _lastController.text = widget.currentData['lastName'] ?? '';
    _mobileController.text = widget.currentData['mobileNumber'] ?? '';
  }

  @override
  void dispose() {
    _firstController.dispose();
    _lastController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  void _showToast(String msg) => Fluttertoast.showToast(msg: msg);

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showToast("User not logged in");
      return;
    }

    final first = _firstController.text.trim();
    final last = _lastController.text.trim();
    final mobile = _mobileController.text.trim();

    if (first.isEmpty) {
      _showToast("First name required");
      return;
    }

    try {
      setState(() => _saving = true);
      final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await ref.set({
        'firstName': first,
        'lastName': last,
        'mobileNumber': mobile,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      _showToast("Profile saved");
      Navigator.pop(context, true);
    } catch (e) {
      _showToast("Error: $e");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFF46D3A);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _firstController, decoration: const InputDecoration(labelText: 'First Name')),
            const SizedBox(height: 8),
            TextField(controller: _lastController, decoration: const InputDecoration(labelText: 'Last Name')),
            const SizedBox(height: 8),
            TextField(controller: _mobileController, decoration: const InputDecoration(labelText: 'Mobile Number'), keyboardType: TextInputType.phone),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor, minimumSize: const Size.fromHeight(50)),
              child: _saving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
