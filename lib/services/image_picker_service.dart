import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();
  final SupabaseClient supabase = Supabase.instance.client;

  // Pick an image from gallery or camera
  Future<File?> pickImage(ImageSource source) async {
    print('Picking image...');
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      print('Image picked successfully.');
      return File(pickedFile.path);
    } else {
      print('No image picked.');
      return null;
    }
  }

  // Upload image to Supabase Storage and return the public URL
  Future<String?> uploadImage(File imageFile, String storagePath) async {
    try {
      final fileExt = imageFile.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '$storagePath/$fileName';

      final bytes = await imageFile.readAsBytes();
      print('Uploading image...');
      await supabase.storage.from(storagePath).uploadBinary(filePath, bytes);
      print('Image uploaded successfully.');

      print('Getting public URL...');
      final publicUrl = supabase.storage.from(storagePath).getPublicUrl(filePath);
      print('Public URL: $publicUrl');

      return publicUrl;
    } catch (e) {
      print('Upload Error: $e');
      return null;
    }
  }
}
