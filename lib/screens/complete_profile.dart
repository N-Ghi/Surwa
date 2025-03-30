import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:surwa/data/notifiers/profile_completion_notifier.dart';
import 'package:surwa/screens/feeds.dart';
import 'package:surwa/services/profile_service.dart';
import 'package:surwa/data/models/profile.dart';

class CompleteProfile extends StatefulWidget {
  const CompleteProfile({super.key});

  @override
  _CompleteProfileState createState() => _CompleteProfileState();
}

class _CompleteProfileState extends State<CompleteProfile> {
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
      role == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please fill all fields")),
    );
    return;
  }

  Profile newProfile = Profile(
    userId: "", // Will be updated in ProfileService
    username: _usernameController.text.trim(),
    name: _nameController.text.trim(),
    lowercase_username: '', // Will be updated in ProfileService
    profilePicture: '', // Will be updated in ProfileService
    role: role!, // Safe to use ! because we checked for null above
    followers: [],
    following: [],
  );

  try {
    // Pass the selected image to the profile service
    await _profileService.createProfile(newProfile, imageFile: _selectedImage);
    
    // Explicitly set profile completion and notify
    Provider.of<ProfileCompletionNotifier>(context, listen: false)
        .setProfileCompletion(true);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile created successfully!")),
    );
    
    // Optional: You might want to navigate programmatically as a backup
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => DashboardScreen()),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error creating profile: $e")),
    );
  }
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
      backgroundColor: Color(0xFFFFD62C),
      body: Container(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                Center(
                  child: Image.asset(
                    'assets/images/surwa_logo.png',
                    width: MediaQuery.of(context).size.width * 0.7, // Responsive width
                    height: 200, // Fixed height, but you can make this responsive too
                    fit: BoxFit.contain,
                  ),
                ),              SizedBox(height: 16),
              Text(
                "Complete Profile",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  labelStyle: TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                ),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black
                  ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  ),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Role',
                  labelStyle: TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                ),
                value: role,
                hint: const Text('Select a role', style: TextStyle(color: Colors.black54)),
                onChanged: (value) => setState(() => role = value),
                items: const [
                  DropdownMenuItem(
                    value: "Artist",
                    child: Text("Artist"),
                  ),
                  DropdownMenuItem(
                    value: "Artisan",
                    child: Text("Artisan"),
                  ),
                ],
                selectedItemBuilder: (BuildContext context) => [
                  const Text("Artist", style: TextStyle(color: Colors.black)),
                  const Text("Artisan", style: TextStyle(color: Colors.black)),
                ],
              ),

              SizedBox(height: 24),
              Row(
                children: [
                  Text("Profile Picture:", style: TextStyle(fontSize: 16, color: Colors.black54)),
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
      ),
    );
  }
}