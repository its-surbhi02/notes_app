
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

//   // Category support
//   final List<String> _categories = ['General', 'Work', 'Personal', 'Shopping', 'Ideas'];
//   String _selectedCategory = 'General';

//   @override
//   void initState() {
//     super.initState();
//     if (isEditing) {
//       final data = widget.note!.data() as Map<String, dynamic>? ?? {};
//       _title.text = (data["title"] ?? '').toString();
//       _content.text = (data["content"] ?? '').toString();
//       final cat = (data["category"] ?? '').toString();
//       if (cat.isNotEmpty && _categories.contains(cat)) {
//         _selectedCategory = cat;
//       } else if (cat.isNotEmpty) {
//         // if firestore has a custom category not in our list, use it and add to list locally
//         _selectedCategory = cat;
//         if (!_categories.contains(cat)) _categories.insert(0, cat);
//       }
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
//           "category": _selectedCategory,
//           "modifiedAt": FieldValue.serverTimestamp(), // standardized field name
//         });

//         Fluttertoast.showToast(msg: "Note updated");
//       } else {
//         await ref.add({
//           "title": title,
//           "content": content,
//           "category": _selectedCategory,
//           "createdAt": FieldValue.serverTimestamp(),
//           "modifiedAt": FieldValue.serverTimestamp(),
//         });

//         Fluttertoast.showToast(msg: "Note created");
//       }

//       if (mounted) Navigator.pop(context);
//     } catch (e) {
//       Fluttertoast.showToast(msg: "Error: $e");
//     }
//   }

//   DateTime? _getDateTimeFromField(Map<String, dynamic>? data, String fieldName) {
//     if (data == null) return null;
//     final val = data[fieldName];
//     if (val == null) return null;
//     try {
//       if (val is Timestamp) return val.toDate();
//       if (val is DateTime) return val;
//       return DateTime.parse(val.toString());
//     } catch (_) {
//       return null;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     const Color orange = Color(0xFFF46D3A);

//     DateTime? modifiedTime;
//     DateTime? createdTime;
//     if (isEditing) {
//       final data = widget.note!.data() as Map<String, dynamic>?;
//       modifiedTime = _getDateTimeFromField(data, 'modifiedAt');
//       createdTime = _getDateTimeFromField(data, 'createdAt');
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

//                   const SizedBox(height: 8),

//                   // CATEGORY DROPDOWN
//                   Row(
//                     children: [
//                       const SizedBox(width: 2),
//                       const Icon(Icons.label_outline, color: Colors.black45),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         child: DropdownButtonFormField<String>(
//                           value: _selectedCategory,
//                           items: _categories
//                               .map((c) => DropdownMenuItem(value: c, child: Text(c)))
//                               .toList(),
//                           onChanged: (v) {
//                             if (v == null) return;
//                             setState(() {
//                               _selectedCategory = v;
//                             });
//                           },
//                           decoration: const InputDecoration(
//                             isDense: true,
//                             contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                             border: OutlineInputBorder(borderSide: BorderSide.none),
//                           ),
//                         ),
//                       ),
//                     ],
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

//           // META: Creation / Last edited section
//           Padding(
//             padding: const EdgeInsets.only(bottom: 18),
//             child: Column(
//               children: [
//                 if (isEditing && modifiedTime != null)
//                   Text(
//                     "Last edited on ${DateFormat('dd MMM yyyy • hh:mm a').format(modifiedTime)}",
//                     style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
//                   ),
//                 if (isEditing && createdTime != null)
//                   Padding(
//                     padding: const EdgeInsets.only(top: 6),
//                     child: Text(
//                       "Created on ${DateFormat('dd MMM yyyy • hh:mm a').format(createdTime)}",
//                       style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// lib/features/notes/screens/add_edit_note_screen.dart
import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:notes/core/features/auth/services/assemblyai_service.dart';
import 'package:notes/core/features/auth/services/audio_recorder_service.dart';

import 'package:notes/core/services/supabase_storage_service.dart';
 

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

  final List<String> _categories = ['General', 'Work', 'Personal', 'Shopping', 'Ideas'];
  String _selectedCategory = 'General';

  File? _pickedImage;           
  String? _existingImageUrl;    
  final ImagePicker _picker = ImagePicker();
  
  bool _isUploading = false;     
  bool _isRecording = false;     
  bool _isTranscribing = false;  
  String? _audioUrl;             

  final SupabaseStorageService _storageService = SupabaseStorageService();
  final AudioRecorderService _recorderService = AudioRecorderService();
  final AssemblyAIService _assemblyService = AssemblyAIService();

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final data = widget.note!.data() as Map<String, dynamic>? ?? {};
      _title.text = (data["title"] ?? '').toString();
      _content.text = (data["content"] ?? '').toString();
      
      if (data["imageUrl"] != null) {
        _existingImageUrl = data["imageUrl"].toString();
      }
      if (data["audioUrl"] != null) {
        _audioUrl = data["audioUrl"].toString();
      }

      final cat = (data["category"] ?? '').toString();
      if (cat.isNotEmpty && _categories.contains(cat)) {
        _selectedCategory = cat;
      } else if (cat.isNotEmpty) {
        _selectedCategory = cat;
        if (!_categories.contains(cat)) _categories.insert(0, cat);
      }
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    _recorderService.dispose(); 
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, 
        maxWidth: 1200,
      );
      if (picked != null) {
        setState(() {
          _pickedImage = File(picked.path);
        });
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error picking image: $e");
    }
  }

  void _removeImage() {
    setState(() {
      _pickedImage = null;
      _existingImageUrl = null;
    });
  }

  Future<void> _toggleRecording() async {
    if (_isTranscribing) return; 

    try {
      if (_isRecording) {
        await _stopRecordingAndTranscribe();
      } else {
        bool hasPermission = await _recorderService.hasPermission();
        if (!hasPermission) {
          Fluttertoast.showToast(msg: "Microphone permission denied");
          return;
        }

        await _recorderService.startRecording();
        setState(() => _isRecording = true);
        // Toast removed to keep UI clean, or keep minimal:
        // Fluttertoast.showToast(msg: "Recording..."); 
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e");
      setState(() => _isRecording = false);
    }
  }

  Future<void> _stopRecordingAndTranscribe() async {
    try {
      final String? path = await _recorderService.stopRecording();
      setState(() => _isRecording = false);
      
      if (path == null) return;

      setState(() => _isTranscribing = true); 
      // Removed "Processing audio..." toast per your request

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isTranscribing = false);
        return;
      }

      final storagePath = 'audio/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.m4a';
      final uploadedUrl = await _storageService.uploadImage(File(path), storagePath);

      if (uploadedUrl == null) throw Exception("Upload failed");
      
      setState(() {
        _audioUrl = uploadedUrl;
      });

      final String? text = await _assemblyService.transcribeAudio(uploadedUrl);

      if (text != null && text.isNotEmpty) {
        setState(() {
          if (_content.text.isEmpty) {
            _content.text = text;
          } else {
            _content.text = "${_content.text}\n\n$text";
          }
        });
        // Removed "Transcription complete!" toast per your request
      } else {
        // We only show toast if it failed completely
        Fluttertoast.showToast(msg: "No speech detected");
      }

    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e");
    } finally {
      setState(() => _isTranscribing = false);
    }
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

    setState(() => _isUploading = true); 

    final ref = FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("notes");

    try {
      String? finalImageUrl = _existingImageUrl;

      if (_pickedImage != null) {
        final path = 'notes/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final url = await _storageService.uploadImage(_pickedImage!, path);
        if (url != null) {
          finalImageUrl = url;
        } else {
          Fluttertoast.showToast(msg: "Image upload failed");
        }
      }

      final Map<String, dynamic> dataToSave = {
        "title": title,
        "content": content,
        "category": _selectedCategory,
        "imageUrl": finalImageUrl, 
        "audioUrl": _audioUrl, 
        "modifiedAt": FieldValue.serverTimestamp(),
      };

      if (isEditing) {
        await ref.doc(widget.note!.id).update(dataToSave);
        Fluttertoast.showToast(msg: "Note updated");
      } else {
        dataToSave["createdAt"] = FieldValue.serverTimestamp();
        await ref.add(dataToSave);
        Fluttertoast.showToast(msg: "Note created");
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e");
    } finally {
      if (mounted) setState(() => _isUploading = false);
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

  Widget _buildImagePreview() {
    if (_pickedImage == null && (_existingImageUrl == null || _existingImageUrl!.isEmpty)) {
      return const SizedBox.shrink(); 
    }

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.shade100,
            image: DecorationImage(
              fit: BoxFit.cover,
              image: _pickedImage != null
                  ? FileImage(_pickedImage!) as ImageProvider
                  : NetworkImage(_existingImageUrl!),
            ),
          ),
        ),
        Positioned(
          top: 15,
          right: 5,
          child: GestureDetector(
            onTap: _removeImage,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
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
          // --- UPDATED: Microphone / Stop Button ---
          IconButton(
            onPressed: (_isUploading || _isTranscribing) ? null : _toggleRecording,
            icon: _isTranscribing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Icon(
                    // If recording, show a Square (Stop), else show Mic
                    _isRecording ? Icons.stop : Icons.mic,
                    // Use WHITE for both so it is visible on Orange background
                    color: Colors.white, 
                    size: 28,
                  ),
            tooltip: _isRecording ? 'Stop Recording' : 'Record Audio',
          ),

          IconButton(
            icon: const Icon(Icons.attach_file, color: Colors.white),
            onPressed: (_isUploading || _isRecording) ? null : _pickImage,
            tooltip: 'Attach Image',
          ),

          IconButton(
            icon: _isUploading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.check, color: Colors.white),
            onPressed: (_isUploading || _isRecording || _isTranscribing) ? null : _saveNote,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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

                  _buildImagePreview(),

                  // Removed _buildAudioIndicator() call here

                  const SizedBox(height: 8),

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
                      decoration: InputDecoration(
                        hintText: _isRecording ? "Listening..." : "Start writing...",
                        hintStyle: const TextStyle(
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