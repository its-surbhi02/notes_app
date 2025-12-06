
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

// --- IMPORTS FOR NEW SERVICES ---
// Ensure you have created these files in 'lib/core/services/' as discussed
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

  // Category support
  final List<String> _categories = ['General', 'Work', 'Personal', 'Shopping', 'Ideas'];
  String _selectedCategory = 'General';

  // --- Image Variables ---
  File? _pickedImage;           
  String? _existingImageUrl;    
  final ImagePicker _picker = ImagePicker();
  
  // --- NEW: Audio & AI Variables ---
  bool _isUploading = false;     // General loading state (save/upload)
  bool _isRecording = false;     // Is the mic active?
  bool _isTranscribing = false;  // Is AssemblyAI processing?
  String? _audioUrl;             // URL of uploaded audio (to save in Firestore)

  // --- Services ---
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
      
      // Load existing image URL
      if (data["imageUrl"] != null) {
        _existingImageUrl = data["imageUrl"].toString();
      }
      // Load existing audio URL
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
    _recorderService.dispose(); // Clean up recorder
    super.dispose();
  }

  // --- Image Functions ---
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

  // --- NEW: Audio Recording & Transcription Logic ---
  Future<void> _toggleRecording() async {
    if (_isTranscribing) return; // Block input while processing

    try {
      if (_isRecording) {
        // STOP RECORDING
        await _stopRecordingAndTranscribe();
      } else {
        // START RECORDING
        // Check permissions first (handled inside service, but good to debug)
        bool hasPermission = await _recorderService.hasPermission();
        if (!hasPermission) {
          Fluttertoast.showToast(msg: "Microphone permission denied");
          return;
        }

        await _recorderService.startRecording();
        setState(() => _isRecording = true);
        Fluttertoast.showToast(msg: "Recording started...");
        print("DEBUG: Recording Started");
      }
    } catch (e) {
      print("DEBUG: Error toggling recording: $e");
      Fluttertoast.showToast(msg: "Error: $e");
      setState(() => _isRecording = false); // Reset state on error
    }
  }

  Future<void> _stopRecordingAndTranscribe() async {
    try {
      print("DEBUG: Stopping recording...");
      // 1. Stop Recorder
      final String? path = await _recorderService.stopRecording();
      setState(() => _isRecording = false);
      
      if (path == null) {
        Fluttertoast.showToast(msg: "Recording failed (File not found)");
        return;
      }

      print("DEBUG: Recorded file at $path");
      setState(() => _isTranscribing = true); // Show loading spinner
      Fluttertoast.showToast(msg: "Processing audio...");

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Fluttertoast.showToast(msg: "User not logged in");
        setState(() => _isTranscribing = false);
        return;
      }

      // 2. Upload Audio to Supabase
      // Path: audio/{uid}/{timestamp}.m4a
      final storagePath = 'audio/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.m4a';
      final uploadedUrl = await _storageService.uploadImage(File(path), storagePath);

      if (uploadedUrl == null) {
        throw Exception("Failed to upload audio file");
      }
      
      print("DEBUG: Uploaded audio to $uploadedUrl");

      // Save URL for Firestore
      setState(() {
        _audioUrl = uploadedUrl;
      });

      // 3. Send to AssemblyAI for Transcription
      final String? text = await _assemblyService.transcribeAudio(uploadedUrl);

      // 4. Update Content
      if (text != null && text.isNotEmpty) {
        setState(() {
          if (_content.text.isEmpty) {
            _content.text = text;
          } else {
            _content.text = "${_content.text}\n\n$text";
          }
        });
        Fluttertoast.showToast(msg: "Transcription complete!");
      } else {
        Fluttertoast.showToast(msg: "Could not transcribe audio.");
        print("DEBUG: Transcription returned null");
      }

    } catch (e) {
      print("DEBUG: Transcription process error: $e");
      Fluttertoast.showToast(msg: "Error: $e");
    } finally {
      setState(() => _isTranscribing = false);
    }
  }
  // ---------------------------

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

    setState(() => _isUploading = true); // Start loading

    final ref = FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("notes");

    try {
      String? finalImageUrl = _existingImageUrl;

      // 1. Upload Image to Supabase if a new one is picked
      if (_pickedImage != null) {
        final path = 'notes/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final url = await _storageService.uploadImage(_pickedImage!, path);
        if (url != null) {
          finalImageUrl = url;
        } else {
          Fluttertoast.showToast(msg: "Image upload failed");
        }
      }

      // 2. Prepare Data (Including new Audio URL)
      final Map<String, dynamic> dataToSave = {
        "title": title,
        "content": content,
        "category": _selectedCategory,
        "imageUrl": finalImageUrl, 
        "audioUrl": _audioUrl, // NEW: Save the audio link
        "modifiedAt": FieldValue.serverTimestamp(),
      };

      // 3. Save to Firestore
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

  // Helper widget to display the image
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

  // New helper to show audio attached indicator
  Widget _buildAudioIndicator() {
    if (_audioUrl == null) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.mic, size: 20, color: Color(0xFFF46D3A)),
          SizedBox(width: 8),
          Text("Audio attached", style: TextStyle(color: Color(0xFFF46D3A), fontWeight: FontWeight.bold)),
          SizedBox(width: 8),
          Icon(Icons.check_circle, size: 16, color: Colors.green),
        ],
      ),
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
          // --- NEW: Microphone Button ---
          IconButton(
            onPressed: (_isUploading || _isTranscribing) ? null : _toggleRecording,
            icon: _isTranscribing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Icon(
                    _isRecording ? Icons.stop_circle : Icons.mic,
                    color: _isRecording ? Colors.redAccent : Colors.white,
                    size: 28,
                  ),
            tooltip: _isRecording ? 'Stop & Transcribe' : 'Record Audio',
          ),

          // Attachment Button
          IconButton(
            icon: const Icon(Icons.attach_file, color: Colors.white),
            onPressed: (_isUploading || _isRecording) ? null : _pickImage,
            tooltip: 'Attach Image',
          ),

          // Save Button
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

                  // Image Preview 
                  _buildImagePreview(),

                  // Audio Indicator (New)
                  _buildAudioIndicator(),

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