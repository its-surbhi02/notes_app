import 'dart:io';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SupabaseStorageService {
  final SupabaseClient supabase = Supabase.instance.client;

  /// Upload image file to Supabase Storage
  Future<String?> uploadImage(File file, String storagePath) async {
    try {
      final bytes = await file.readAsBytes();
      final contentType = lookupMimeType(file.path);

      final response = await supabase.storage.from('profiles').uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(contentType: contentType),
          );

      if (response.isNotEmpty) {
        String publicUrl = getPublicUrl(storagePath);
        Fluttertoast.showToast(msg: "Image uploaded successfully!");
        return publicUrl;
      } else {
        Fluttertoast.showToast(msg: "Upload failed (empty response).");
        return null;
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Upload failed: $e");
      print("Upload error: $e");
      return null;
    }
  }

  /// Generate public URL
  String getPublicUrl(String storagePath) {
    return supabase.storage.from('profiles').getPublicUrl(storagePath);
  }

  /// Delete file from bucket
  Future<bool> deleteFile(String storagePath) async {
    try {
      await supabase.storage.from('profiles').remove([storagePath]);
      Fluttertoast.showToast(msg: "Image deleted successfully!");
      return true;
    } catch (e) {
      Fluttertoast.showToast(msg: "Delete failed: $e");
      print("Delete error: $e");
      return false;
    }
  }
}
