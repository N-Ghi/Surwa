import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

Future<File?> pickImage() async {
  final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
  if (pickedFile != null) {
    return File(pickedFile.path);
  }
  return null;
}

Future<String?> uploadProfilePicture(File imageFile, String userId) async {
  try {
    // Create a storage reference
    Reference storageRef = FirebaseStorage.instance.ref().child('profile_pictures/$userId.jpg');

    // Upload the file
    UploadTask uploadTask = storageRef.putFile(imageFile);

    // Wait for the upload to complete
    TaskSnapshot snapshot = await uploadTask;

    // Get the download URL
    String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  } catch (e) {
    print("Error uploading image: $e");
    return null;
  }
}
