import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:notes/core/features/advanced/screens/ads_screen.dart';
import 'package:notes/core/features/advanced/screens/ai_tools_screen.dart';
import 'package:notes/core/features/advanced/screens/profile_screen.dart';
import 'package:notes/core/features/advanced/screens/settings_page.dart';
import 'package:notes/core/features/auth/screen/login_screen.dart';
import 'package:notes/core/features/notes/screens/add_edit_note_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? user;
  Stream<QuerySnapshot>? notesStream;
  late Future<DocumentSnapshot> userDataFuture;

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  String appBarTitle = "My Notes"; // default

 @override
void initState() {
  super.initState();

  // AUTO REDIRECT IF USER DELETED
  FirebaseAuth.instance.authStateChanges().listen((User? user) {
    if (user == null) {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  });

  // OLD CODE (user, streams, etc)
  user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    userDataFuture = FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .get();

    notesStream = FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .collection("notes")
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  _initRemoteConfig();
}


  // --- SETUP REMOTE CONFIG ---
  Future<void> _initRemoteConfig() async {
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: Duration.zero, // fetch every time
        ),
      );

      // Default values
      await _remoteConfig.setDefaults({"home_title": "My Notes"});

      // Fetch & Apply
      await _remoteConfig.fetchAndActivate();

      final newTitle = _remoteConfig.getString("home_title");

      if (mounted) {
        setState(() {
          appBarTitle = newTitle;
        });
      }
    } catch (e) {
      print("REMOTE CONFIG ERROR: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color orange = Color(0xFFF46D3A);

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle, style: const TextStyle(color: Colors.white)),
        backgroundColor: orange,
        elevation: 0,
      ),

     drawer: Drawer(
  child: ListView(
    padding: EdgeInsets.zero,
    children: [
      FutureBuilder<DocumentSnapshot>(
        future: userDataFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: orange),
              accountName: Text("Loading..."),
              accountEmail: Text("Loading..."),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;

          final first = data?["firstName"] ?? "";
          final last = data?["lastName"] ?? "";
          final email = data?["email"] ?? user!.email;
          final initial = first.isNotEmpty
              ? first[0].toUpperCase()
              : (email.isNotEmpty ? email[0].toUpperCase() : "U");

          return UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: orange),
            accountName: Text(
              "$first $last".trim().isEmpty
                  ? "User Name"
                  : "$first $last",
            ),
            accountEmail: Text(email ?? "No email"),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                initial,
                style: const TextStyle(
                  color: orange,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),

      // ⭐ ADD THIS ⭐
      ListTile(
        leading: const Icon(Icons.person),
        title: const Text("Profile"),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          );
        },
      ),

      ListTile(
        leading: const Icon(Icons.ad_units),
        title: const Text("Show Ads"),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdsScreen()),
          );
        },
      ),

      ListTile(
        leading: const Icon(Icons.smart_toy),
        title: const Text("AI Tools"),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AiToolsScreen()),
          );
        },
      ),

      ListTile(
        leading: const Icon(Icons.settings),
        title: const Text("Settings"),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsPage()),
          );
        },
      ),

      const Divider(),

      ListTile(
        leading: const Icon(Icons.logout, color: Colors.red),
        title: const Text("Logout", style: TextStyle(color: Colors.red)),
        onTap: () async {
          await FirebaseAuth.instance.signOut();
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        },
      ),
    ],
  ),
),

      body: StreamBuilder<QuerySnapshot>(
        stream: notesStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notes = snapshot.data!.docs;

          if (notes.isEmpty) {
            return Center(
              child: Text(
                "No notes yet.\nTap + to create your first note!",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];

              return Dismissible(
                key: Key(note.id),
                direction: DismissDirection.endToStart,

                // RED DELETE BACKGROUND
                background: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.centerRight,
                  child: const Icon(
                    Icons.delete,
                    size: 28,
                    color: Colors.white,
                  ),
                ),

                // DELETE FUNCTION
                onDismissed: (_) async {
                  await FirebaseFirestore.instance
                      .collection("users")
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .collection("notes")
                      .doc(note.id)
                      .delete();

                  Fluttertoast.showToast(msg: "Note deleted");
                },

                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEditNoteScreen(note: note),
                      ),
                    );
                  },

                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12.withOpacity(0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note["title"],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF46D3A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          note["content"],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: orange,
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditNoteScreen()),
          );
        },
      ),
    );
  }
}
