import 'package:flutter/material.dart';
import 'package:surwa/data/models/profile.dart';
import 'package:surwa/services/profile_service.dart';
import 'package:provider/provider.dart';
import 'package:surwa/data/notifiers/auth_notifier.dart'; // Import AuthNotifier

class PostSetup extends StatefulWidget {
  const PostSetup({Key? key}) : super(key: key);

  @override
  _PostSetupState createState() => _PostSetupState();
}

class _PostSetupState extends State<PostSetup> {
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
      debugPrint("Profile creation successful");
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      debugPrint("Profile creation failed: $result");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Complete Your Profile")),
      body: Text("Posting Page"),
    );
  }
}
