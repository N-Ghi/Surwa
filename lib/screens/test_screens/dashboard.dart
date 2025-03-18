import 'dart:io';
import 'package:flutter/material.dart';
import 'package:surwa/services/profile_service.dart';
import 'package:surwa/data/models/profile.dart';
import 'package:image_picker/image_picker.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProfileService _profileService = ProfileService();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  File? _selectedImage;
  Profile? _existingProfile;

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  // Method to load the existing profile if available
  Future<void> _loadExistingProfile() async {
    _existingProfile = await _profileService.getLoggedInUserProfile();
    if (_existingProfile != null) {
      _usernameController.text = _existingProfile!.username;
      _nameController.text = _existingProfile!.name;
    }
    setState(() {});
  }

  // Method to update the profile
  Future<void> _updateProfile() async {
    final profile = _existingProfile!.copyWith(
      name: _nameController.text,
      username: _usernameController.text,
    );

    String? result = await _profileService.updateProfile(
      name: profile.name,
      username: profile.username,
      newProfileImage: _selectedImage,
    );
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result ?? 'Profile updated successfully!')));
  }

  // Method to delete the profile
  Future<void> _deleteProfile() async {
    await _profileService.deleteProfile();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile deleted successfully')));
  }

  // Method to pick an image from the gallery
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_existingProfile == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Dashboard')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Pick Profile Picture'),
            ),
            if (_existingProfile != null)
              ElevatedButton(
                onPressed: _updateProfile,
                child: Text('Update Profile'),
              ),
            ElevatedButton(
              onPressed: _deleteProfile,
              child: Text('Delete Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
