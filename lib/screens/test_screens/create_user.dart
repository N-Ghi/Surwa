import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:surwa/services/profile_service.dart';
import 'package:surwa/data/models/profile.dart';

class ProfileTestScreen extends StatefulWidget {
  const ProfileTestScreen({super.key});

  @override
  _ProfileTestScreenState createState() => _ProfileTestScreenState();
}

class _ProfileTestScreenState extends State<ProfileTestScreen> {
  final ProfileService _profileService = ProfileService();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  String? role; // Changed to nullable String instead of empty string
  File? _selectedImage;

  // Method to pick an image from the gallery
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // Method to create a profile
  Future<void> _createProfile() async {
    if (_usernameController.text.trim().isEmpty ||
        _nameController.text.trim().isEmpty ||
        role == null) { // Now correctly checks for null
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    Profile newProfile = Profile(
      userId: "", // Will be updated in ProfileService
      username: _usernameController.text.trim(),
      name: _nameController.text.trim(),
      profilePicture: '', // Will be updated in ProfileService
      role: role!, // Safe to use ! because we checked for null above
      followers: [],
      following: [],
    );

    // Pass the selected image to the profile service
    await _profileService.createProfile(newProfile, imageFile: _selectedImage);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile created successfully!")),
    );
    _clearForm();
  }

  void _clearForm() {
    _usernameController.clear();
    _nameController.clear();
    setState(() {
      role = null;
      _selectedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Role',
                border: OutlineInputBorder(),
              ),
              value: role, // Now correctly handles null as initial value
              hint: Text('Select a role'), // Added hint text for initial state
              onChanged: (value) => setState(() => role = value),
              items: const [
                DropdownMenuItem(value: "Artist", child: Text("Artist")),
                DropdownMenuItem(value: "Artisan", child: Text("Artisan")),
              ],
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Text("Profile Picture:"),
                SizedBox(width: 8),
                ElevatedButton.icon(
                onPressed: _pickImage,
                icon: Icon(Icons.photo),
                label: Text('Pick Picture'),
                ),
                SizedBox(width: 8),
                if (_selectedImage != null) // Show indicator when image is selected
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: FileImage(_selectedImage!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: _createProfile,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text('Create Profile', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}