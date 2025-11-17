// lib/features/advanced/profile/screens/profile_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
  bool _loading = false;

  // animation for header
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

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    _showToast("Logged out");
    Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false); // adjust route as your app needs
  }

  Future<void> _deleteAccount(DocumentSnapshot<Map<String, dynamic>> userDoc) async {
    final user = _user;
    if (user == null) return;

    // Determine sign-in method
    final providers = user.providerData.map((p) => p.providerId).toList();
    final usesPassword = providers.contains('password');

    // Ask user to confirm and re-authenticate
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account'),
        content: const Text('This will permanently delete your account and all your notes. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    // Re-auth flow
    if (!usesPassword) {
      // For non-password providers (Google), ask user to sign out and sign in again using the provider to reauthenticate.
      _showToast("Re-auth required. Please sign in with the same provider to delete account.");
      return;
    }

    // Prompt for password to reauthenticate
    final password = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Confirm password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter your current password to confirm account deletion.'),
              const SizedBox(height: 12),
              TextField(controller: controller, obscureText: true, decoration: const InputDecoration(hintText: 'Password')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Confirm', style: TextStyle(color: Colors.red))),
          ],
        );
      },
    );

    if (password == null || password.isEmpty) {
      _showToast("Password required to delete account");
      return;
    }

    try {
      setState(() => _loading = true);
      final credential = EmailAuthProvider.credential(email: user.email!, password: password);
      await user.reauthenticateWithCredential(credential);

      // delete firestore user doc and nested notes
      final batch = FirebaseFirestore.instance.batch();
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final notesSnapshot = await userRef.collection('notes').get();
      for (final doc in notesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(userRef);
      await batch.commit();

      // delete auth user
      await user.delete();

      if (!mounted) return;
      _showToast("Account deleted", bg: Colors.redAccent);
      Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
    } on FirebaseAuthException catch (e) {
      _showToast(e.message ?? "Failed to delete account");
    } catch (e) {
      _showToast("Error: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildHeader(Map<String, dynamic>? data) {
    final first = (data?['firstName'] ?? '') as String;
    final last = (data?['lastName'] ?? '') as String;
    final email = (data?['email'] ?? _user?.email ?? '') as String;
    final mobile = (data?['mobileNumber'] ?? '') as String;
    final initials = first.isNotEmpty ? first[0].toUpperCase() : (email.isNotEmpty ? email[0].toUpperCase() : 'U');

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
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white,
              child: Text(initials, style: const TextStyle(color: Color(0xFFF46D3A), fontSize: 36, fontWeight: FontWeight.bold)),
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
              // refresh
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
        child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
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
