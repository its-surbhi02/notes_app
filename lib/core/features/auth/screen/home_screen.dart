


// lib/core/features/auth/screen/home_screen.dart
// lib/core/features/auth/screen/home_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart'; // <--- CACHING PACKAGE

import 'package:notes/core/features/advanced/screens/ai_tools_screen.dart';
import 'package:notes/core/features/advanced/screens/ads_screen.dart';
import 'package:notes/core/features/advanced/screens/profile_screen.dart';
import 'package:notes/core/features/advanced/screens/settings_page.dart';
import 'package:notes/core/features/auth/screen/login_screen.dart';
import 'package:notes/core/features/notes/screens/add_edit_note_screen.dart';
import 'trash_screen.dart';

enum LayoutMode { grid, list }
enum SortBy { custom, dateCreated, dateModified }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Firebase & streams
  User? user;
  Stream<QuerySnapshot>? notesStream;
  late Future<DocumentSnapshot> userDataFuture;
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  // App UI state
  String appBarTitle = "My Notes";
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";
  bool _showChips = false;

  LayoutMode layoutMode = LayoutMode.grid;
  SortBy sortBy = SortBy.dateCreated; 

  final List<String> categories = ["All", "Work", "Personal", "Shopping", "Ideas"];
  String selectedCategory = "All";

  // Multi-select state
  bool selectionMode = false;
  final Set<String> selectedIds = {};

  // Expanded state per note
  final Set<String> expandedIds = {};

  // Undo overlay handling
  OverlayEntry? _undoOverlay;
  Timer? _undoTimer;
  int _undoSecondsLeft = 0;
  List<String> _pendingDeletedIds = [];

  @override
  void initState() {
    super.initState();

    FirebaseAuth.instance.authStateChanges().listen((u) {
      if (u == null) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
        }
      }
    });

    user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _refreshUserData(); 
      notesStream = FirebaseFirestore.instance
          .collection("users")
          .doc(user!.uid)
          .collection("notes")
          .orderBy('createdAt', descending: false)
          .snapshots();
    }

    _initRemoteConfig();

    _searchController.addListener(() {
      setState(() {
        searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  void _refreshUserData() {
    if (user != null) {
      setState(() {
        userDataFuture = FirebaseFirestore.instance.collection("users").doc(user!.uid).get();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cancelUndoOverlay();
    super.dispose();
  }

  Future<void> _initRemoteConfig() async {
    try {
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: Duration.zero,
      ));
      await _remoteConfig.setDefaults({"home_title": "My Notes"});
      await _remoteConfig.fetchAndActivate();
      final newTitle = _remoteConfig.getString("home_title");
      if (mounted) setState(() => appBarTitle = newTitle);
    } catch (e) {
      print("REMOTE CONFIG ERROR: $e");
    }
  }

  DateTime _toDate(dynamic tsOrDate) {
    try {
      if (tsOrDate == null) return DateTime.fromMillisecondsSinceEpoch(0);
      if (tsOrDate is Timestamp) return tsOrDate.toDate();
      if (tsOrDate is DateTime) return tsOrDate;
      return DateTime.parse(tsOrDate.toString());
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  List<QueryDocumentSnapshot> _processNotes(Iterable<QueryDocumentSnapshot> docs) {
    final list = docs.toList();

    final filteredByCategory = list.where((doc) {
      if (selectedCategory == "All") return true;
      final noteCategory = (doc.data() as Map<String, dynamic>?)?['category'] as String?;
      return (noteCategory ?? "").toLowerCase() == selectedCategory.toLowerCase();
    });

    final filteredBySearch = filteredByCategory.where((doc) {
      if (searchQuery.isEmpty) return true;
      final data = doc.data() as Map<String, dynamic>?;
      final title = (data?['title'] ?? "").toString().toLowerCase();
      final content = (data?['content'] ?? "").toString().toLowerCase();
      return title.contains(searchQuery) || content.contains(searchQuery);
    }).toList();

    if (sortBy == SortBy.dateCreated) {
      filteredBySearch.sort((a, b) {
        final aa = (a.data() as Map<String, dynamic>?)?['createdAt'];
        final bb = (b.data() as Map<String, dynamic>?)?['createdAt'];
        DateTime da = _toDate(aa);
        DateTime db = _toDate(bb);
        return da.compareTo(db);
      });
    } else if (sortBy == SortBy.dateModified) {
      filteredBySearch.sort((a, b) {
        final aa = (a.data() as Map<String, dynamic>?)?['modifiedAt'] ?? (a.data() as Map<String, dynamic>?)?['createdAt'];
        final bb = (b.data() as Map<String, dynamic>?)?['modifiedAt'] ?? (b.data() as Map<String, dynamic>?)?['createdAt'];
        DateTime da = _toDate(aa);
        DateTime db = _toDate(bb);
        return db.compareTo(da);
      });
    }

    return filteredBySearch;
  }

  Future<void> _softDeleteNoteByDoc(QueryDocumentSnapshot note) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final noteId = note.id;
    final noteData = Map<String, dynamic>.from(note.data() as Map<String, dynamic>? ?? {});
    final trashRef = FirebaseFirestore.instance.collection('users').doc(uid).collection('trash').doc(noteId);
    final notesRef = FirebaseFirestore.instance.collection('users').doc(uid).collection('notes').doc(noteId);
    noteData['deletedAt'] = FieldValue.serverTimestamp();
    noteData['originalId'] = noteId;
    try {
      await trashRef.set(noteData);
      await notesRef.delete();
    } catch (e) {
      Fluttertoast.showToast(msg: "Delete failed: $e");
    }
  }

  Future<void> _softDeleteMultipleByDocs(List<QueryDocumentSnapshot> notes) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final batch = FirebaseFirestore.instance.batch();
    final trashCol = FirebaseFirestore.instance.collection('users').doc(uid).collection('trash');
    final notesCol = FirebaseFirestore.instance.collection('users').doc(uid).collection('notes');
    for (final note in notes) {
      final noteId = note.id;
      final noteData = Map<String, dynamic>.from(note.data() as Map<String, dynamic>? ?? {});
      noteData['deletedAt'] = FieldValue.serverTimestamp();
      noteData['originalId'] = noteId;
      batch.set(trashCol.doc(noteId), noteData);
      batch.delete(notesCol.doc(noteId));
    }
    try {
      await batch.commit();
    } catch (e) {
      Fluttertoast.showToast(msg: "Bulk delete failed: $e");
    }
  }

  Future<void> _undoDeleteFromTrash(List<String> docIds) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final trashCol = FirebaseFirestore.instance.collection('users').doc(uid).collection('trash');
    final notesCol = FirebaseFirestore.instance.collection('users').doc(uid).collection('notes');
    final batch = FirebaseFirestore.instance.batch();
    for (final id in docIds) {
      final trashDoc = await trashCol.doc(id).get();
      if (!trashDoc.exists) continue;
      final data = Map<String, dynamic>.from(trashDoc.data() as Map<String, dynamic>? ?? {});
      data.remove('deletedAt');
      data.remove('originalId');
      batch.set(notesCol.doc(id), data);
      batch.delete(trashCol.doc(id));
    }
    try {
      await batch.commit();
      Fluttertoast.showToast(msg: "Restored");
    } catch (e) {
      Fluttertoast.showToast(msg: "Undo failed: $e");
    }
  }

  void _enterSelectionModeWith(String id) {
    setState(() {
      selectionMode = true;
      selectedIds.add(id);
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (selectedIds.contains(id)) selectedIds.remove(id);
      else selectedIds.add(id);
      if (selectedIds.isEmpty) selectionMode = false;
    });
  }

  void _clearSelection() {
    setState(() {
      selectionMode = false;
      selectedIds.clear();
    });
  }

  Future<void> _onNoteLongPress(QueryDocumentSnapshot note) async {
    if (selectionMode) {
      _toggleSelection(note.id);
      return;
    }
    final willDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete note"),
        content: const Text("Are you sure you want to delete this note?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (willDelete == true) {
      await _softDeleteNoteByDoc(note);
      _showUndoOverlay([note.id]);
    }
  }

  Future<void> _deleteSelectedNotes() async {
    if (selectedIds.isEmpty) return;
    final willDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete selected notes"),
        content: Text("Delete ${selectedIds.length} selected note(s)? They will be moved to Trash."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (willDelete != true) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final notesCol = FirebaseFirestore.instance.collection('users').doc(uid).collection('notes');
    final fetchedDocs = <QueryDocumentSnapshot>[];
    for (final id in selectedIds) {
      final doc = await notesCol.doc(id).get();
      if (doc.exists) fetchedDocs.add(doc as QueryDocumentSnapshot);
    }
    await _softDeleteMultipleByDocs(fetchedDocs);
    final deletedIds = selectedIds.toList();
    _clearSelection();
    _showUndoOverlay(deletedIds);
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 8),
            const Text("Sort by", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListTile(
              leading: Icon(sortBy == SortBy.custom ? Icons.check_circle : Icons.circle_outlined),
              title: const Text("Custom (server order)"),
              onTap: () {
                setState(() => sortBy = SortBy.custom);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: Icon(sortBy == SortBy.dateCreated ? Icons.check_circle : Icons.circle_outlined),
              title: const Text("Date created (oldest first)"),
              onTap: () {
                setState(() => sortBy = SortBy.dateCreated);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: Icon(sortBy == SortBy.dateModified ? Icons.check_circle : Icons.circle_outlined),
              title: const Text("Date modified (newest first)"),
              onTap: () {
                setState(() => sortBy = SortBy.dateModified);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 12),
          ]),
        );
      },
    );
  }

  void _openTrashScreen() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const TrashScreen()));
  }

  void _showUndoOverlay(List<String> deletedIds) {
    _cancelUndoOverlay();
    _pendingDeletedIds = List.from(deletedIds);
    _undoSecondsLeft = 5;
    _undoOverlay = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: 12,
          right: 12,
          bottom: 20,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: Colors.grey.shade900, borderRadius: BorderRadius.circular(12), boxShadow: [
                BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
              ]),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Expanded(child: Text("Moved to Trash", style: TextStyle(color: Colors.white))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text("${_undoSecondsLeft}s", style: const TextStyle(color: Colors.white70)),
                  ),
                  TextButton(
                    onPressed: _undoOverlay == null
                        ? null
                        : () async {
                            await _undoDeleteFromTrash(_pendingDeletedIds);
                            _cancelUndoOverlay();
                          },
                    child: const Text("Undo", style: TextStyle(color: Color(0xFFF46D3A))),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    Overlay.of(context)!.insert(_undoOverlay!);
    _undoTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        _cancelUndoOverlay();
        return;
      }
      setState(() {
        _undoSecondsLeft -= 1;
      });
      _undoOverlay?.markNeedsBuild();
      if (_undoSecondsLeft <= 0) {
        t.cancel();
        _cancelUndoOverlay();
      }
    });
  }

  void _cancelUndoOverlay() {
    try {
      _undoTimer?.cancel();
    } catch (_) {}
    _undoTimer = null;
    _pendingDeletedIds = [];
    _undoSecondsLeft = 0;
    _undoOverlay?.remove();
    _undoOverlay = null;
  }

  @override
  Widget build(BuildContext context) {
    const Color orange = Color(0xFFF46D3A);

    final topAppBar = AppBar(
      centerTitle: true,
      title: selectionMode ? Text("${selectedIds.length} selected") : Text(appBarTitle, style: const TextStyle(color: Colors.white)),
      backgroundColor: orange,
      elevation: 0,
      leading: Builder(builder: (context) {
        if (selectionMode) {
          return IconButton(icon: const Icon(Icons.close), onPressed: _clearSelection);
        } else {
          return IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(context).openDrawer());
        }
      }),
      actions: [
        if (selectionMode) ...[
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _deleteSelectedNotes),
        ] else ...[
          // --- PROFILE AVATAR (AppBar) ---
          FutureBuilder<DocumentSnapshot>(
            future: userDataFuture,
            builder: (context, snapshot) {
              String initial = "U";
              String? photoUrl;

              if (snapshot.hasData && snapshot.data!.data() != null) {
                final data = snapshot.data!.data() as Map<String, dynamic>?;
                final first = (data?["firstName"] ?? "") as String;
                final email = (data?["email"] ?? user?.email ?? "") as String;
                photoUrl = data?['profilePhotoUrl'] as String?;

                if (first.isNotEmpty) initial = first[0].toUpperCase();
                else if (email.isNotEmpty) initial = email[0].toUpperCase();
              } else {
                final email = user?.email ?? "";
                if (email.isNotEmpty) initial = email[0].toUpperCase();
              }

              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: GestureDetector(
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                    _refreshUserData();
                  },
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white,
                    // CACHED IMAGE HERE
                    backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                        ? CachedNetworkImageProvider(photoUrl) 
                        : null,
                    child: (photoUrl == null || photoUrl.isEmpty)
                        ? Text(initial, style: TextStyle(color: orange, fontSize: 16, fontWeight: FontWeight.bold))
                        : null,
                  ),
                ),
              );
            },
          ),
        ]
      ],
    );

    return Scaffold(
      appBar: topAppBar,
      drawer: Drawer(
        child: ListView(padding: EdgeInsets.zero, children: [
          // --- PROFILE AVATAR (Drawer) ---
          FutureBuilder<DocumentSnapshot>(
            future: userDataFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const UserAccountsDrawerHeader(decoration: BoxDecoration(color: orange), accountName: Text("Loading..."), accountEmail: Text("Loading..."));
              }

              final data = snapshot.data!.data() as Map<String, dynamic>?;
              final first = data?['firstName'] ?? '';
              final last = data?['lastName'] ?? '';
              final email = data?['email'] ?? user!.email;
              final photoUrl = data?['profilePhotoUrl'] as String?;
              
              final initial = (first as String).isNotEmpty ? (first as String)[0].toUpperCase() : (email as String).isNotEmpty ? (email as String)[0].toUpperCase() : "U";

              return UserAccountsDrawerHeader(
                decoration: const BoxDecoration(color: orange),
                accountName: Text("$first $last".trim().isEmpty ? "User Name" : "$first $last"),
                accountEmail: Text(email ?? "No email"),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  // CACHED IMAGE HERE
                  backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) 
                      ? CachedNetworkImageProvider(photoUrl) 
                      : null,
                  child: (photoUrl == null || photoUrl.isEmpty)
                      ? Text(initial, style: const TextStyle(color: orange, fontSize: 40, fontWeight: FontWeight.bold))
                      : null,
                ),
              );
            },
          ),
          ListTile(leading: const Icon(Icons.ad_units), title: const Text("Show Ads"), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdsScreen()))),
          ListTile(leading: const Icon(Icons.smart_toy), title: const Text("AI Tools"), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiToolsScreen()))),
          ListTile(leading: const Icon(Icons.restore_from_trash), title: const Text("Trash"), onTap: _openTrashScreen),
          ListTile(leading: const Icon(Icons.settings), title: const Text("Settings"), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()))),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout", style: TextStyle(color: Colors.red)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
            },
          ),
        ]),
      ),

      body: Column(children: [
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            Expanded(
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(28)),
                child: Row(children: [
                  const Icon(Icons.search, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(hintText: 'Search notes', border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                      textInputAction: TextInputAction.search,
                      onTap: () {
                        setState(() => _showChips = true);
                      },
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.label_outline, color: Colors.grey), onPressed: () => setState(() => _showChips = !_showChips)),
                  if (searchQuery.isNotEmpty) IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => setState(() {
                        _searchController.clear();
                        searchQuery = "";
                      })),
                  if (_showChips) IconButton(icon: const Icon(Icons.keyboard_arrow_up, color: Colors.grey), onPressed: () => setState(() => _showChips = false)),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() => layoutMode = layoutMode == LayoutMode.grid ? LayoutMode.list : LayoutMode.grid),
              child: Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
                child: Icon(layoutMode == LayoutMode.grid ? Icons.grid_view : Icons.view_agenda, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _showSortBottomSheet,
              child: Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
                child: const Icon(Icons.sort, color: Colors.grey),
              ),
            ),
          ]),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          child: Visibility(
            visible: _showChips,
            child: SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final cat = categories[idx];
                    final isSelected = selectedCategory == cat;
                    return ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          selectedCategory = cat;
                        });
                      },
                      selectedColor: orange,
                      backgroundColor: Colors.grey.shade300,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: notesStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              final processed = _processNotes(docs);
              if (processed.isEmpty) {
                return Center(
                  child: Text(
                    "No notes.\nTap + to create one.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 18),
                  ),
                );
              }
              if (layoutMode == LayoutMode.grid) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                  child: MasonryGridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    itemCount: processed.length,
                    itemBuilder: (context, index) {
                      final note = processed[index];
                      final data = note.data() as Map<String, dynamic>?;
                      final isSelected = selectedIds.contains(note.id);
                      final isExpanded = expandedIds.contains(note.id);
                      return Dismissible(
                        key: Key(note.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                          alignment: Alignment.centerRight,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          final willDelete = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Delete note"),
                              content: const Text("Move this note to Trash?"),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          );
                          if (willDelete == true) {
                            await _softDeleteNoteByDoc(note);
                            _showUndoOverlay([note.id]);
                          }
                          return willDelete == true;
                        },
                        child: GestureDetector(
                          onLongPress: () => _onNoteLongPress(note),
                          onTap: () {
                            if (selectionMode) {
                              _toggleSelection(note.id);
                            } else {
                              setState(() {
                                if (isExpanded) expandedIds.remove(note.id);
                                else expandedIds.add(note.id);
                              });
                            }
                          },
                          child: Stack(children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
                              ),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        (data?['title'] ?? '').toString(),
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFF46D3A)),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditNoteScreen(note: note))),
                                      child: const Padding(
                                        padding: EdgeInsets.only(left: 8.0),
                                        child: Icon(Icons.edit, size: 18, color: Colors.grey),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  (data?['content'] ?? '').toString(),
                                  maxLines: isExpanded ? null : 6,
                                  overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.3),
                                ),
                                const SizedBox(height: 8),
                                if (!isExpanded)
                                  Text(
                                    "Tap to expand",
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                                  ),
                              ]),
                            ),
                            if (selectionMode)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: CircleAvatar(
                                  radius: 14,
                                  backgroundColor: isSelected ? orange : Colors.white,
                                  child: Icon(isSelected ? Icons.check : Icons.circle_outlined, color: isSelected ? Colors.white : Colors.grey, size: 16),
                                ),
                              ),
                          ]),
                        ),
                      );
                    },
                  ),
                );
              } else {
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: processed.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final note = processed[index];
                    final data = note.data() as Map<String, dynamic>?;
                    final isSelected = selectedIds.contains(note.id);
                    return Dismissible(
                      key: Key(note.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                        alignment: Alignment.centerRight,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        final willDelete = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text("Delete note"),
                            content: const Text("Move this note to Trash?"),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        );
                        if (willDelete == true) {
                          await _softDeleteNoteByDoc(note);
                          _showUndoOverlay([note.id]);
                        }
                        return willDelete == true;
                      },
                      child: GestureDetector(
                        onLongPress: () => _onNoteLongPress(note),
                        onTap: () {
                          if (selectionMode) {
                            _toggleSelection(note.id);
                          } else {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditNoteScreen(note: note)));
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            if (selectionMode)
                              Padding(
                                padding: const EdgeInsets.only(right: 12.0, top: 4),
                                child: CircleAvatar(
                                  radius: 14,
                                  backgroundColor: isSelected ? orange : Colors.white,
                                  child: Icon(isSelected ? Icons.check : Icons.circle_outlined, color: isSelected ? Colors.white : Colors.grey, size: 16),
                                ),
                              ),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text((data?['title'] ?? '').toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFF46D3A))),
                                const SizedBox(height: 8),
                                Text((data?['content'] ?? '').toString(), maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade700)),
                              ]),
                            ),
                          ]),
                        ),
                      ),
                    );
                  },
                );
              }
            },
          ),
        ),
      ]),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFF46D3A),
        child: const Icon(Icons.add),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditNoteScreen())),
      ),
    );
  }
}