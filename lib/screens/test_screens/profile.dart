import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:surwa/screens/test_screens/create_user.dart';
import 'package:surwa/services/profile_service.dart';
import 'package:surwa/data/models/profile.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  File? _selectedImage;
  Profile? _existingProfile;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    _existingProfile = await _profileService.getLoggedInUserProfile();
    if (_existingProfile != null) {
      _usernameController.text = _existingProfile!.username;
      _nameController.text = _existingProfile!.name;
      _emailController.text = _currentUser!.email ?? '';
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _updateProfileForm() async {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Update Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(labelText: 'Username'),
                ),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextField(
                  controller: _currentPasswordController,
                  decoration: InputDecoration(labelText: 'Current Password'),
                  obscureText: true,
                ),
                TextField(
                  controller: _newPasswordController,
                  decoration: InputDecoration(labelText: 'New Password'),
                  obscureText: true,
                ),
                ElevatedButton(
                  onPressed: _pickImage,
                  child: Text('Profile Picture'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!mounted) return;

                final profile = _existingProfile!.copyWith(
                  name: _nameController.text,
                  username: _usernameController.text,
                );

                String? result = await _profileService.updateProfile(
                  name: profile.name,
                  username: profile.username,
                  email: _emailController.text.isNotEmpty ? _emailController.text : null,
                  newPassword: _newPasswordController.text.isNotEmpty ? _newPasswordController.text : null,
                  newProfileImage: _selectedImage,
                  currentPassword: _currentPasswordController.text,
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result ?? 'Profile updated successfully!')),
                  );
                  Navigator.pop(dialogContext);
                }
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteProfile() async {
    await _profileService.deleteProfile();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile deleted successfully')));
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (mounted) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_existingProfile == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Profile'), centerTitle: true),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 50),
              SizedBox(height: 10),
              Text('No profile found!'),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ProfileTestScreen()));
                },
                child: Icon(Icons.add),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Profile'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: _selectedImage != null
                  ? FileImage(_selectedImage!)
                  : _existingProfile!.profilePicture != null
                      ? NetworkImage(_existingProfile!.profilePicture!)
                      : null,
              child: _selectedImage == null && _existingProfile!.profilePicture == null
                  ? Icon(Icons.person, size: 50)
                  : null,
            ),
            Divider(),
            Text('Username: ${_existingProfile!.username}'),
            SizedBox(height: 8),
            Text('Name: ${_existingProfile!.name}'),
            SizedBox(height: 8),
            Text('Email: ${_currentUser!.email ?? "Not provided"}'),
            SizedBox(height: 8),
            Text('Role: ${_existingProfile!.role}'),
            Divider(),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _updateProfileForm,
                  child: Text('Update Profile'),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _deleteProfile,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: Text('Delete Profile'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
