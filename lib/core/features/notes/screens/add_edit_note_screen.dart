// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:intl/intl.dart';

// class AddEditNoteScreen extends StatefulWidget {
//   final DocumentSnapshot? note;

//   const AddEditNoteScreen({super.key, this.note});

//   @override
//   State<AddEditNoteScreen> createState() => _AddEditNoteScreenState();
// }

// class _AddEditNoteScreenState extends State<AddEditNoteScreen> {
//   final _title = TextEditingController();
//   final _content = TextEditingController();
//   bool get isEditing => widget.note != null;

//   @override
//   void initState() {
//     super.initState();
//     if (isEditing) {
//       _title.text = widget.note!["title"];
//       _content.text = widget.note!["content"];
//     }
//   }

//   @override
//   void dispose() {
//     _title.dispose();
//     _content.dispose();
//     super.dispose();
//   }

//   Future<void> _saveNote() async {
//     final title = _title.text.trim();
//     final content = _content.text.trim();
//     final user = FirebaseAuth.instance.currentUser;

//     if (title.isEmpty) {
//       Fluttertoast.showToast(msg: "Title cannot be empty");
//       return;
//     }

//     if (user == null) {
//       Fluttertoast.showToast(msg: "User not logged in");
//       return;
//     }

//     final ref = FirebaseFirestore.instance
//         .collection("users")
//         .doc(user.uid)
//         .collection("notes");

//     try {
//       if (isEditing) {
//         await ref.doc(widget.note!.id).update({
//           "title": title,
//           "content": content,
//           "updatedAt": FieldValue.serverTimestamp(),
//         });

//         Fluttertoast.showToast(msg: "Note updated");
//       } else {
//         await ref.add({
//           "title": title,
//           "content": content,
//           "createdAt": FieldValue.serverTimestamp(),
//           "updatedAt": FieldValue.serverTimestamp(),
//         });

//         Fluttertoast.showToast(msg: "Note created");
//       }

//       if (mounted) Navigator.pop(context);

//     } catch (e) {
//       Fluttertoast.showToast(msg: "Error: $e");
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     const Color orange = Color(0xFFF46D3A);

//     DateTime? updatedTime;
//     if (isEditing && widget.note!.data().toString().contains("updatedAt")) {
//       Timestamp? t = widget.note!["updatedAt"];
//       if (t != null) updatedTime = t.toDate();
//     }

//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: orange,
//         elevation: 0,
//         title: Text(
//           isEditing ? "Edit Note" : "Create Note",
//           style: const TextStyle(color: Colors.white),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.check, color: Colors.white),
//             onPressed: _saveNote,
//           )
//         ],
//       ),

//       backgroundColor: Colors.white,

//       body: Column(
//         children: [
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
//               child: Column(
//                 children: [
//                   // TITLE FIELD
//                   TextField(
//                     controller: _title,
//                     style: const TextStyle(
//                       fontSize: 26,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black87,
//                     ),
//                     decoration: const InputDecoration(
//                       hintText: "Title",
//                       hintStyle: TextStyle(
//                         fontSize: 26,
//                         fontWeight: FontWeight.bold,
//                         color: Color(0xFFC9C9C9),
//                       ),
//                       border: InputBorder.none,
//                     ),
//                   ),

//                   const SizedBox(height: 10),

//                   // CONTENT FIELD
//                   Expanded(
//                     child: TextField(
//                       controller: _content,
//                       maxLines: null,
//                       expands: true,
//                       style: const TextStyle(
//                         fontSize: 18,
//                         color: Colors.black54,
//                         height: 1.5,
//                       ),
//                       decoration: const InputDecoration(
//                         hintText: "Start writing...",
//                         hintStyle: TextStyle(
//                           fontSize: 18,
//                           color: Color(0xFFC9C9C9),
//                         ),
//                         border: InputBorder.none,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           // LAST EDITED SECTION
//           if (isEditing && updatedTime != null)
//             Padding(
//               padding: const EdgeInsets.only(bottom: 18),
//               child: Text(
//                 "Last edited on ${DateFormat('dd MMM yyyy • hh:mm a').format(updatedTime!)}",
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: Colors.grey.shade600,
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

class AddEditNoteScreen extends StatefulWidget {
  final DocumentSnapshot? note;

  const AddEditNoteScreen({super.key, this.note});

  @override
  State<AddEditNoteScreen> createState() => _AddEditNoteScreenState();
}

class _AddEditNoteScreenState extends State<AddEditNoteScreen> {
  final _title = TextEditingController();
  final _content = TextEditingController();
  bool get isEditing => widget.note != null;

  // Category support
  final List<String> _categories = ['General', 'Work', 'Personal', 'Shopping', 'Ideas'];
  String _selectedCategory = 'General';

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final data = widget.note!.data() as Map<String, dynamic>? ?? {};
      _title.text = (data["title"] ?? '').toString();
      _content.text = (data["content"] ?? '').toString();
      final cat = (data["category"] ?? '').toString();
      if (cat.isNotEmpty && _categories.contains(cat)) {
        _selectedCategory = cat;
      } else if (cat.isNotEmpty) {
        // if firestore has a custom category not in our list, use it and add to list locally
        _selectedCategory = cat;
        if (!_categories.contains(cat)) _categories.insert(0, cat);
      }
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final title = _title.text.trim();
    final content = _content.text.trim();
    final user = FirebaseAuth.instance.currentUser;

    if (title.isEmpty) {
      Fluttertoast.showToast(msg: "Title cannot be empty");
      return;
    }

    if (user == null) {
      Fluttertoast.showToast(msg: "User not logged in");
      return;
    }

    final ref = FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("notes");

    try {
      if (isEditing) {
        await ref.doc(widget.note!.id).update({
          "title": title,
          "content": content,
          "category": _selectedCategory,
          "modifiedAt": FieldValue.serverTimestamp(), // standardized field name
        });

        Fluttertoast.showToast(msg: "Note updated");
      } else {
        await ref.add({
          "title": title,
          "content": content,
          "category": _selectedCategory,
          "createdAt": FieldValue.serverTimestamp(),
          "modifiedAt": FieldValue.serverTimestamp(),
        });

        Fluttertoast.showToast(msg: "Note created");
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e");
    }
  }

  DateTime? _getDateTimeFromField(Map<String, dynamic>? data, String fieldName) {
    if (data == null) return null;
    final val = data[fieldName];
    if (val == null) return null;
    try {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      return DateTime.parse(val.toString());
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color orange = Color(0xFFF46D3A);

    DateTime? modifiedTime;
    DateTime? createdTime;
    if (isEditing) {
      final data = widget.note!.data() as Map<String, dynamic>?;
      modifiedTime = _getDateTimeFromField(data, 'modifiedAt');
      createdTime = _getDateTimeFromField(data, 'createdAt');
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: orange,
        elevation: 0,
        title: Text(
          isEditing ? "Edit Note" : "Create Note",
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            onPressed: _saveNote,
          )
        ],
      ),

      backgroundColor: Colors.white,

      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
              child: Column(
                children: [
                  // TITLE FIELD
                  TextField(
                    controller: _title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    decoration: const InputDecoration(
                      hintText: "Title",
                      hintStyle: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFC9C9C9),
                      ),
                      border: InputBorder.none,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // CATEGORY DROPDOWN
                  Row(
                    children: [
                      const SizedBox(width: 2),
                      const Icon(Icons.label_outline, color: Colors.black45),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          items: _categories
                              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() {
                              _selectedCategory = v;
                            });
                          },
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // CONTENT FIELD
                  Expanded(
                    child: TextField(
                      controller: _content,
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.black54,
                        height: 1.5,
                      ),
                      decoration: const InputDecoration(
                        hintText: "Start writing...",
                        hintStyle: TextStyle(
                          fontSize: 18,
                          color: Color(0xFFC9C9C9),
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // META: Creation / Last edited section
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(
              children: [
                if (isEditing && modifiedTime != null)
                  Text(
                    "Last edited on ${DateFormat('dd MMM yyyy • hh:mm a').format(modifiedTime)}",
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                if (isEditing && createdTime != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      "Created on ${DateFormat('dd MMM yyyy • hh:mm a').format(createdTime)}",
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
