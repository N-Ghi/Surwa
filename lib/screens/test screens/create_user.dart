import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:surwa/data/models/profile.dart';
import 'package:surwa/screens/test%20screens/create_post.dart';
import 'package:surwa/services/image_picker_service.dart';
import 'package:surwa/services/profile_service.dart';

class CreateProfile extends StatefulWidget {
  const CreateProfile({super.key});

  @override
  State<CreateProfile> createState() => _CreateProfileState();
}

class _CreateProfileState extends State<CreateProfile> {
  final ProfileService _profileService = ProfileService();
  final ImagePickerService _imagePickerService = ImagePickerService();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  String? _role;
  File? _imageFile;

  Future<void> _pickImage() async {
    File? pickedImage = await _imagePickerService.pickImage(ImageSource.gallery);
    if (pickedImage != null) {
      setState(() => _imageFile = pickedImage);
    }
  }

  Future<void> _createProfile() async {
    if (_usernameController.text.trim().isEmpty ||
        _nameController.text.trim().isEmpty ||
        _role == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    Profile newProfile = Profile(
      username: _usernameController.text.trim(),
      name: _nameController.text.trim(),
      profilePicture: '', // Will be updated in ProfileService
      role: _role!, // Not null because we checked above
      followers: [],
      following: [],
    );

    await _profileService.createProfile(newProfile);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile created successfully!")),
    );
    _clearForm();
  }

  void _clearForm() {
    _usernameController.clear();
    _nameController.clear();
    setState(() {
      _role = null;
      _imageFile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CRUD Profile'), centerTitle: true),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile creation form
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Create New Profile',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Role',
                          border: OutlineInputBorder(),
                        ),
                        value: _role,
                        onChanged: (value) => setState(() => _role = value),
                        items: const [
                          DropdownMenuItem(value: "Artist", child: Text("Artist")),
                          DropdownMenuItem(value: "Artisan", child: Text("Artisan")),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: _createProfile,
                            child: const Text("Create Profile"),
                          ),
                          ElevatedButton(
                            onPressed: _pickImage,
                            child: const Text("Pick Image"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Existing profiles list
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Existing Profiles',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            StreamBuilder<List<Profile>>(
              stream: _profileService.streamAllProfiles(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No profiles found."));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    Profile profile = snapshot.data![index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: profile.profilePicture != null && profile.profilePicture!.isNotEmpty
                            ? NetworkImage(profile.profilePicture ?? "")
                            : const AssetImage("assets/images/default_avatar.png") 
                                as ImageProvider,
                      ),
                      title: Text(profile.name),
                      subtitle: Text(profile.role),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteProfile(profile.username),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editProfile(profile),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return  PostTestScreen();
                },));
              },
              child: Text("Add Post"))
          ],
        ),
      ),
    );
  }

  Future<void> _deleteProfile(String username) async {
    await _profileService.deleteProfile(username);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile deleted successfully!")),
    );
  }

  void _editProfile(Profile profile) {
    // Create local controllers for the dialog
    TextEditingController nameController = TextEditingController(text: profile.name);
    String selectedRole = profile.role;
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Edit Profile"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: "Name"),
                    ),
                    const SizedBox(height: 16),
                    DropdownButton<String>(
                      value: selectedRole,
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedRole = value);
                        }
                      },
                      items: const [
                        DropdownMenuItem(value: "Artist", child: Text("Artist")),
                        DropdownMenuItem(value: "Artisan", child: Text("Artisan")),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Update the profile with name and role fields
                    await _profileService.updateProfile(profile.username, {
                      'name': nameController.text,
                      'role': selectedRole,
                    });
                    
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Profile updated successfully!")),
                    );
                  },
                  child: const Text("Save Changes"),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}