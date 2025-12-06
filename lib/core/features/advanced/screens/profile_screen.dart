// lib/features/advanced/profile/screens/profile_screen.dart
import 'dart:io'; // Added for File
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart'; // Added for ImagePicker
// Replace with your actual path
import 'package:notes/core/services/supabase_storage_service.dart'; 
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final User? _user = FirebaseAuth.instance.currentUser;
  late Future<DocumentSnapshot<Map<String, dynamic>>> _userDocFuture;
  
  // Existing loading state for delete/logout
  bool _loading = false; 

  // --- NEW: Image Upload Variables ---
  final ImagePicker _picker = ImagePicker();
  final SupabaseStorageService _storageService = SupabaseStorageService();
  File? _localImage;
  bool _isImageUploading = false;
  // -----------------------------------

  // Animation for header
  late final AnimationController _animController;
  late final Animation<double> _avatarScale;

  @override
  void initState() {
    super.initState();
    _userDocFuture = _fetchUserDoc();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _avatarScale = Tween<double>(begin: 0.9, end: 1.0).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _fetchUserDoc() {
    return FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _showToast(String msg, {Color? bg}) {
    Fluttertoast.showToast(msg: msg, backgroundColor: bg ?? null);
  }

  // --- NEW: Image Pick and Auto-Upload Logic ---
  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, 
        maxWidth: 1000,
      );

      if (picked == null) return;

      setState(() {
        _localImage = File(picked.path);
        _isImageUploading = true;
      });

      // Start Upload
      await _uploadToSupabase(File(picked.path));

    } catch (e) {
      _showToast('Failed to pick image: $e');
      setState(() => _isImageUploading = false);
    }
  }

  Future<void> _uploadToSupabase(File imageFile) async {
    final user = _user;
    if (user == null) return;

    final storagePath = 'profiles/${user.uid}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';

    try {
      final publicUrl = await _storageService.uploadImage(imageFile, storagePath);

      if (publicUrl != null) {
        // Save public URL to Firestore user doc
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'profilePhotoUrl': publicUrl,
          'lastUpdated': FieldValue.serverTimestamp(), // Update timestamp too
        }, SetOptions(merge: true));

        _showToast('Profile photo updated!');
        
        // Refresh the Future to show the new network image
        setState(() {
          _userDocFuture = _fetchUserDoc();
          _localImage = null; // Clear local file so we use the network URL now
        });
      } else {
        _showToast('Upload failed.');
      }
    } catch (e) {
      _showToast('Upload error: $e');
    } finally {
      if (mounted) {
        setState(() => _isImageUploading = false);
      }
    }
  }
  // ---------------------------------------------

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    _showToast("Logged out");
    Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
  }

  Future<void> _deleteAccount(DocumentSnapshot<Map<String, dynamic>> userDoc) async {
    // ... [KEEP YOUR EXISTING DELETE LOGIC HERE] ...
    // Included abbreviated version for brevity, paste your full logic back if needed
    final user = _user;
    if (user == null) return;
    
    // (Simulating your existing confirmation dialogs...)
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account'),
        content: const Text('Are you sure? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    // (Add your re-auth and delete batch logic here exactly as you had it)
    try {
      setState(() => _loading = true);
      await user.delete(); // Simplified for example
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
    } catch (e) {
       _showToast("Error deleting: $e");
    } finally {
      if(mounted) setState(() => _loading = false);
    }
  }

  Widget _buildHeader(Map<String, dynamic>? data) {
    final first = (data?['firstName'] ?? '') as String;
    final last = (data?['lastName'] ?? '') as String;
    final email = (data?['email'] ?? _user?.email ?? '') as String;
    final mobile = (data?['mobileNumber'] ?? '') as String;
    final initials = first.isNotEmpty ? first[0].toUpperCase() : (email.isNotEmpty ? email[0].toUpperCase() : 'U');
    
    // Check for profile URL from Firestore
    final profileUrl = data?['profilePhotoUrl'] as String?;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 36, 16, 20),
      decoration: const BoxDecoration(
        color: Color(0xFFF46D3A),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
      ),
      child: Row(
        children: [
          ScaleTransition(
            scale: _avatarScale,
            child: Stack(
              children: [
                // 1. The Avatar Image
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    // Logic: 
                    // 1. If uploading, show transparent (loader is on top)
                    // 2. If local file exists (preview), show FileImage
                    // 3. If Firestore has URL, show NetworkImage
                    // 4. Else show Initials
                    backgroundImage: _localImage != null 
                        ? FileImage(_localImage!) as ImageProvider
                        : (profileUrl != null && profileUrl.isNotEmpty 
                            ? NetworkImage(profileUrl) 
                            : null),
                    child: (_localImage == null && (profileUrl == null || profileUrl.isEmpty) && !_isImageUploading)
                        ? Text(initials, style: const TextStyle(color: Color(0xFFF46D3A), fontSize: 36, fontWeight: FontWeight.bold))
                        : null,
                  ),
                ),

                // 2. Loading Indicator Overlay
                if (_isImageUploading)
                  const Positioned.fill(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),

                // 3. Camera Edit Button
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _isImageUploading ? null : _pickAndUploadImage,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, size: 18, color: Color(0xFFF46D3A)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                "$first $last".trim().isEmpty ? "User Name" : "$first $last",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(email, style: const TextStyle(color: Colors.white70)),
              if (mobile.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(mobile, style: const TextStyle(color: Colors.white70)),
              ],
            ]),
          ),
          IconButton(
            onPressed: () async {
              setState(() => _userDocFuture = _fetchUserDoc());
            },
            icon: const Icon(Icons.refresh, color: Colors.white),
          )
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String title, required VoidCallback onTap, Color? color}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: const Color(0xFFF46D3A).withOpacity(0.12), child: Icon(icon, color: color ?? const Color(0xFFF46D3A))),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color background = Color(0xFFFFF6F0);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF46D3A),
        title: const Text("Profile", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SafeArea(
        child: _loading 
          ? const Center(child: CircularProgressIndicator()) 
          : FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: _userDocFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snap.data?.data();
            return Column(
              children: [
                _buildHeader(data),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(top: 8),
                    children: [
                      const SizedBox(height: 8),
                      _buildActionButton(
                        icon: Icons.edit,
                        title: "Edit Profile",
                        onTap: () async {
                          final updated = await Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen(currentData: data ?? {})));
                          if (updated == true) {
                            _showToast("Profile updated");
                            setState(() => _userDocFuture = _fetchUserDoc());
                          }
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.lock,
                        title: "Change Password",
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen()));
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.logout,
                        title: "Logout",
                        onTap: _logout,
                      ),
                      _buildActionButton(
                        icon: Icons.delete_forever,
                        title: "Delete Account",
                        onTap: () async {
                           final userDoc = await _userDocFuture;
                           await _deleteAccount(userDoc);
                        },
                        color: Colors.red,
                      ),
                      const SizedBox(height: 20),
                      if (data != null && data['lastUpdated'] != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            "Last updated: ${_formatTimestamp(data['lastUpdated'])}",
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic ts) {
    try {
      if (ts is Timestamp) {
        final dt = ts.toDate();
        return "${dt.day.toString().padLeft(2,'0')}-${dt.month.toString().padLeft(2,'0')}-${dt.year} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}";
      }
      return ts.toString();
    } catch (e) {
      return ts.toString();
    }
  }
}