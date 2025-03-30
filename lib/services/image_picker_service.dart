import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();
  final SupabaseClient supabase = Supabase.instance.client;

  // Pick an image from gallery
  Future<File?> pickImage(ImageSource source) async {
  try {
    final XFile? pickedFile = await _picker.pickImage(
    source: source,
    maxWidth: 600,
    maxHeight: 600,
    imageQuality: 70,
  );
    
    if (pickedFile != null) {
      return File(pickedFile.path);
    } 
    else {
      return null;
    }
  } catch (e) {
    return null;
  }
}

  // Upload profile image
  Future<String?> uploadProfileImage(File imageFile, String storagePath) async {
  try {
    final fileExt = imageFile.path.split('.').last;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final filePath = '$storagePath/$fileName';
    
    const bucketName = 'profile-images';
    final bytes = await imageFile.readAsBytes();
    await supabase.storage.from(bucketName).uploadBinary(filePath, bytes);
    final publicUrl = supabase.storage.from(bucketName).getPublicUrl(filePath);
    return publicUrl;
  } catch (e) {
    return ("There was an error uploading the image. Please try again.");
  }
  }

  // Upload post image
  Future<String?> uploadPostImage(File imageFile, String storagePath) async {
    try {
      // Get file extension
      final fileExt = imageFile.path.split('.').last;
      // Create a unique filename
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      // Construct the full path
      final filePath = '$storagePath/$fileName';
      // Your bucket name
      const bucketName = 'user_uploads';
      // Read file bytes in a separate isolate to prevent UI freezing
      final bytes = await compute(_readFileBytes, imageFile.path);
      // Upload the file
      await supabase.storage.from(bucketName).uploadBinary(filePath, bytes);
      // Get the public URL
      final publicUrl = supabase.storage.from(bucketName).getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      return null;
    }
  }

// Upload product image
  Future<String?> uploadProductImage(File imageFile, String storagePath) async {
    try {
      // Get file extension
      final fileExt = imageFile.path.split('.').last;
      // Create a unique filename
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      // Construct the full path
      final filePath = '$storagePath/$fileName';
      // Your bucket name
      const bucketName = 'product-images';
      // Read file bytes in a separate isolate to prevent UI freezing
      final bytes = await compute(_readFileBytes, imageFile.path);
      // Upload the file
      await supabase.storage.from(bucketName).uploadBinary(filePath, bytes);
      // Get the public URL
      final publicUrl = supabase.storage.from(bucketName).getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      return null;
    }
  }

// Helper function to read file bytes in a separate isolate
static Future<Uint8List> _readFileBytes(String path) async {
  return await File(path).readAsBytes();
}
}