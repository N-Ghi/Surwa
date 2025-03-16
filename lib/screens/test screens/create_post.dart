import 'package:flutter/material.dart';
import 'package:surwa/data/models/profile.dart';
import 'package:surwa/services/profile_service.dart';
import 'package:provider/provider.dart';
import 'package:surwa/data/notifiers/auth_notifier.dart'; // Import AuthNotifier

class ProfileSetupScreen extends StatefulWidget {
  @override
  _ProfileSetupScreenState createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _createProfile() async {
    final authNotifier = Provider.of<AuthNotifier>(context, listen: false);

    // Check if the user is logged in via AuthNotifier
    if (authNotifier.user == null) {
      setState(() {
        _errorMessage = "No user is logged in.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Create the profile
    Profile profile = Profile(
      userId: authNotifier.user!.uid,
      username: _usernameController.text.trim(),
      name: _nameController.text.trim(),
      role: _roleController.text.trim(),
    );

    ProfileService profileService = ProfileService();

    // Call ProfileService to create the profile
    String? result = await profileService.createProfile(profile);

    setState(() {
      _isLoading = false;
      _errorMessage = result;
    });

    if (result == null) {
      // If profile creation is successful, navigate to home screen or desired page
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Complete Your Profile")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: "Username"),
            ),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: "Full Name"),
            ),
            TextField(
              controller: _roleController,
              decoration: InputDecoration(labelText: "Role"),
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _createProfile,
                    child: Text("Create Profile"),
                  ),
            if (_errorMessage != null) ...[
              SizedBox(height: 10),
              Text(_errorMessage!, style: TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}
