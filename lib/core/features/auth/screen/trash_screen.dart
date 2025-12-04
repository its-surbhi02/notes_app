// lib/core/features/auth/screen/trash_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  User? user;
  Stream<QuerySnapshot>? trashStream;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      trashStream = FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('trash').orderBy('deletedAt', descending: true).snapshots();
    }
  }

  Future<void> _restoreFromTrash(DocumentSnapshot trashDoc) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final id = trashDoc.id;
    final data = Map<String, dynamic>.from(trashDoc.data() as Map<String, dynamic>? ?? {});
    data.remove('deletedAt');
    data.remove('originalId');

    final notesRef = FirebaseFirestore.instance.collection('users').doc(uid).collection('notes').doc(id);
    final trashRef = FirebaseFirestore.instance.collection('users').doc(uid).collection('trash').doc(id);

    try {
      await notesRef.set(data);
      await trashRef.delete();
      Fluttertoast.showToast(msg: "Restored");
    } catch (e) {
      Fluttertoast.showToast(msg: "Restore failed: $e");
    }
  }

  Future<void> _permanentlyDelete(DocumentSnapshot trashDoc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete permanently"),
        content: const Text("This will permanently delete the note. Are you sure?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('trash').doc(trashDoc.id).delete();
      Fluttertoast.showToast(msg: "Deleted permanently");
    } catch (e) {
      Fluttertoast.showToast(msg: "Delete failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color orange = Color(0xFFF46D3A);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Trash"),
        backgroundColor: orange,
      ),
      body: user == null
          ? const Center(child: Text("Not logged in"))
          : StreamBuilder<QuerySnapshot>(
              stream: trashStream,
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snap.data!.docs;
                if (docs.isEmpty) return Center(child: Text("Trash is empty", style: TextStyle(color: Colors.grey.shade600)));
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final d = docs[i];
                    final data = d.data() as Map<String, dynamic>?;
                    final title = (data?['title'] ?? '').toString();
                    final content = (data?['content'] ?? '').toString();
                    final deletedAt = data?['deletedAt'];
                    final deletedTime = deletedAt is Timestamp ? deletedAt.toDate() : null;

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(
                          children: [
                            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
                            IconButton(icon: const Icon(Icons.restore), onPressed: () => _restoreFromTrash(d)),
                            IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _permanentlyDelete(d)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(content, maxLines: 3, overflow: TextOverflow.ellipsis),
                        if (deletedTime != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text("Deleted on ${deletedTime.toLocal()}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ),
                      ]),
                    );
                  },
                );
              },
            ),
    );
  }
}
