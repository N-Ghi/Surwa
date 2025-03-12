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
    print('Picking image...');
    final XFile? pickedFile = await _picker.pickImage(
    source: source,
    maxWidth: 600,
    maxHeight: 600,
    imageQuality: 70,
  );
    
    if (pickedFile != null) {
      print('Image picked successfully.');
      return File(pickedFile.path);
    } 
    else {
      print('No image picked.');
      return null;
    }
  } catch (e) {
    print('Error picking image: $e');
    return null;
  }
}

  // Upload image to Supabase Storage and return the public URL
  Future<String?> uploadProfileImage(File imageFile, String storagePath) async {
  try {
    final fileExt = imageFile.path.split('.').last;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final filePath = '$storagePath/$fileName';
    
    const bucketName = 'profile-images';
    
    final bytes = await imageFile.readAsBytes();
    print('Uploading image...');
    await supabase.storage.from(bucketName).uploadBinary(filePath, bytes);
    print('Image uploaded successfully.');
    
    print('Getting public URL...');
    final publicUrl = supabase.storage.from(bucketName).getPublicUrl(filePath);
    print('Public URL: $publicUrl');
    
    return publicUrl;
  } catch (e) {
    print('Upload Error: $e');
    return null;
  }
  }

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
    
    print('Uploading image to $bucketName/$filePath...');
    
    // Upload the file
    await supabase.storage.from(bucketName).uploadBinary(filePath, bytes);
    print('Image uploaded successfully.');
    
    // Get the public URL
    final publicUrl = supabase.storage.from(bucketName).getPublicUrl(filePath);
    print('Public URL: $publicUrl');
    
    return publicUrl;
  } catch (e) {
    print('Upload Error: $e');
    return null;
  }
}

// Helper function to read file bytes in a separate isolate
static Future<Uint8List> _readFileBytes(String path) async {
  return await File(path).readAsBytes();
}
}