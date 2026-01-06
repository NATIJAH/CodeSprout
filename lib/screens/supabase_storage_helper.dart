import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStorageHelper {
  final SupabaseClient supabase;

  SupabaseStorageHelper({required this.supabase});

  /// Pick an image from gallery or camera and upload to Supabase
  Future<Map<String, String>?> pickAndUploadImage({required String bucketName}) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return null;

      String fileName = pickedFile.name;

      Uint8List fileBytes;

      if (kIsWeb) {
        // Web returns bytes directly
        fileBytes = await pickedFile.readAsBytes();
      } else {
        // Mobile
        final file = File(pickedFile.path);
        fileBytes = await file.readAsBytes();
      }

      final storage = supabase.storage.from(bucketName);

      // Upload file
      final response = await storage.uploadBinary(fileName, fileBytes, fileOptions: FileOptions(cacheControl: '3600', upsert: true));

      // uploadBinary returns void, if no exception, it's OK
      final publicUrl = storage.getPublicUrl(fileName);

      return {'url': publicUrl};
    } catch (e) {
      print("Upload failed: $e");
      return null;
    }
  }

  /// Delete an image from Supabase storage
  Future<bool> deleteImage(String fileName, {required String bucketName}) async {
    try {
      final storage = supabase.storage.from(bucketName);
      await storage.remove([fileName]);
      return true;
    } catch (e) {
      print("Delete failed: $e");
      return false;
    }
  }
}
