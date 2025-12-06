// // lib/features/advanced/profile/screens/edit_profile_screen.dart
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';

// class EditProfileScreen extends StatefulWidget {
//   final Map<String, dynamic> currentData;
//   const EditProfileScreen({super.key, required this.currentData});

//   @override
//   State<EditProfileScreen> createState() => _EditProfileScreenState();
// }

// class _EditProfileScreenState extends State<EditProfileScreen> {
//   final _firstController = TextEditingController();
//   final _lastController = TextEditingController();
//   final _mobileController = TextEditingController();
//   bool _saving = false;

//   @override
//   void initState() {
//     super.initState();
//     _firstController.text = widget.currentData['firstName'] ?? '';
//     _lastController.text = widget.currentData['lastName'] ?? '';
//     _mobileController.text = widget.currentData['mobileNumber'] ?? '';
//   }

//   @override
//   void dispose() {
//     _firstController.dispose();
//     _lastController.dispose();
//     _mobileController.dispose();
//     super.dispose();
//   }

//   void _showToast(String msg) => Fluttertoast.showToast(msg: msg);

//   Future<void> _save() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) {
//       _showToast("User not logged in");
//       return;
//     }

//     final first = _firstController.text.trim();
//     final last = _lastController.text.trim();
//     final mobile = _mobileController.text.trim();

//     if (first.isEmpty) {
//       _showToast("First name required");
//       return;
//     }

//     try {
//       setState(() => _saving = true);
//       final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
//       await ref.set({
//         'firstName': first,
//         'lastName': last,
//         'mobileNumber': mobile,
//         'lastUpdated': FieldValue.serverTimestamp(),
//       }, SetOptions(merge: true));

//       if (!mounted) return;
//       _showToast("Profile saved");
//       Navigator.pop(context, true);
//     } catch (e) {
//       _showToast("Error: $e");
//     } finally {
//       if (mounted) setState(() => _saving = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     const Color primaryColor = Color(0xFFF46D3A);
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Edit Profile'),
//         backgroundColor: primaryColor,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             TextField(controller: _firstController, decoration: const InputDecoration(labelText: 'First Name')),
//             const SizedBox(height: 8),
//             TextField(controller: _lastController, decoration: const InputDecoration(labelText: 'Last Name')),
//             const SizedBox(height: 8),
//             TextField(controller: _mobileController, decoration: const InputDecoration(labelText: 'Mobile Number'), keyboardType: TextInputType.phone),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _saving ? null : _save,
//               style: ElevatedButton.styleFrom(backgroundColor: primaryColor, minimumSize: const Size.fromHeight(50)),
//               child: _saving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save', style: TextStyle(fontSize: 16)),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
// lib/features/advanced/profile/screens/edit_profile_screen.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notes/core/services/supabase_storage_service.dart';

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
  File? _localImage;
  final ImagePicker _picker = ImagePicker();
  final SupabaseStorageService _storageService = SupabaseStorageService();

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

  // Now accept a source (camera/gallery)
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1000,
      );
      if (picked != null) {
        setState(() => _localImage = File(picked.path));
      }
    } catch (e) {
      _showToast("Error picking image: $e");
    }
  }

  // Show action sheet to choose source
  void _showSourceChooser() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Wrap(children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(ctx),
            ),
          ]),
        );
      },
    );
  }

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

    setState(() => _saving = true);

    try {
      String? publicUrl;

      if (_localImage != null) {
        final storagePath = 'profiles/${user.uid}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
        publicUrl = await _storageService.uploadImage(_localImage!, storagePath);
        if (publicUrl == null) {
          throw Exception("Image upload failed");
        }
      }

      final Map<String, dynamic> updateData = {
        'firstName': first,
        'lastName': last,
        'mobileNumber': mobile,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      if (publicUrl != null) {
        updateData['profilePhotoUrl'] = publicUrl;
      }

      final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await ref.set(updateData, SetOptions(merge: true));

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
    final currentPhotoUrl = widget.currentData['profilePhotoUrl'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Image Picker UI now opens source chooser
              GestureDetector(
                onTap: _saving ? null : _showSourceChooser,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _localImage != null
                          ? FileImage(_localImage!) as ImageProvider
                          : (currentPhotoUrl != null && currentPhotoUrl.isNotEmpty ? NetworkImage(currentPhotoUrl) : null),
                      child: (_localImage == null && (currentPhotoUrl == null || currentPhotoUrl.isEmpty))
                          ? const Icon(Icons.person, size: 50, color: Colors.grey)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              TextField(controller: _firstController, decoration: const InputDecoration(labelText: 'First Name')),
              const SizedBox(height: 8),
              TextField(controller: _lastController, decoration: const InputDecoration(labelText: 'Last Name')),
              const SizedBox(height: 8),
              TextField(controller: _mobileController, decoration: const InputDecoration(labelText: 'Mobile Number'), keyboardType: TextInputType.phone),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor, minimumSize: const Size.fromHeight(50)),
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
