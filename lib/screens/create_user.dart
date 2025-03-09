import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:surwa/services/image_picker_service.dart';
import 'package:surwa/services/profile_service.dart';

class createUser extends StatefulWidget {
  const createUser({super.key});

  @override
  State<createUser> createState() => _createUserState();
}

class _createUserState extends State<createUser> {
  final UserService userService = UserService();

  TextEditingController emailController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  String? role;
  File? imageFile; // Declare imageFile here

// Create User
void createUser() {
  showDialog(
    context: context,
    builder: (context) {
      return Center(
        child: SingleChildScrollView(
          child: AlertDialog(
            title: Text("Create Account"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Email"),
                SizedBox(height: 10.0),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Enter your email",
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 20.0),
                Text("Names"),
                SizedBox(height: 10.0),
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Enter your name",
                  ),
                ),
                SizedBox(height: 20.0),
                Text("Role"),
                SizedBox(height: 10.0),
                DropdownButtonFormField<String>(
                  value: role,
                  hint: Text("Select Role"),
                  decoration: InputDecoration(border: OutlineInputBorder()),
                  items: [
                    DropdownMenuItem(
                      child: Text("Artist"),
                      value: "Artist",
                    ),
                    DropdownMenuItem(
                      child: Text("Artisan"),
                      value: "Artisan",
                    ),
                  ],
                  onChanged: (String? value) {
                    setState(() {
                      role = value!;
                    });
                  },
                  validator: (value) => value == null ? 'Please select a role' : null,
                ),
                SizedBox(height: 20.0),
                Row(
                  children: [
                    Text("Profile Picture"),
                    SizedBox(width: 10.0),
                    TextButton(
                      onPressed: () async {
                        File? pickedImage = await pickImage(); 
                        setState(() {
                          imageFile = pickedImage;
                        });
                      },
                      child: Text("Pick Image"),
                    ),
                  ],
                ),
                if (imageFile != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Image.file(imageFile!, height: 50, width: 50),
                  ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  if (emailController.text.trim().isEmpty ||
                      nameController.text.trim().isEmpty ||
                      role == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Please fill all fields")),
                    );
                    return;
                  }

                  if (imageFile != null) {
                    await userService.createProfile(
                      emailController.text.trim(),
                      nameController.text.trim(),
                      imageFile,
                      role!, // Using 'role!' to ensure it's non-null
                      [],
                      [],
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Profile created successfully!")),
                    );
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("No image selected.")),
                    );
                  }
                },
                child: Text("Create Profile"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("Cancel"),
              ),
            ],
          ),
        ),
      );
    },
  );
}

//Edit User
void _editUser(Map<String, dynamic> user) {
  TextEditingController nameController = TextEditingController(text: user['name']);
  String selectedRole = user['role'];

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("Edit User"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: "Name"),
            ),
            SizedBox(height: 10),
            DropdownButton<String>(
              value: selectedRole,
              onChanged: (value) {
                selectedRole = value!;
              },
              items: [
                DropdownMenuItem(value: "Artist", child: Text("Artist")),
                DropdownMenuItem(value: "Artisan", child: Text("Artisan")),
              ],
            ),
            Row(
                  children: [
                    Text("Profile Picture"),
                    SizedBox(width: 10.0),
                    TextButton(
                      onPressed: () async {
                        File? pickedImage = await pickImage(); 
                        setState(() {
                          imageFile = pickedImage;
                        });
                      },
                      child: Text("Pick Image"),
                    ),
                  ],
                ),
                if (imageFile != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Image.file(imageFile!, height: 50, width: 50),
                  ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              userService.updateUser(user['email'], {
                'name': nameController.text,
                'role': selectedRole,
              });
              Navigator.pop(context);
            },
            child: Text("Save Changes"),
          ),
        ],
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CRUD User'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          createUser();
        },
        child: Icon(Icons.add),
      ),
      //Retrive and display all users

      body: SingleChildScrollView(
  child: Column(
    children: [
      StreamBuilder<List<Map<String, dynamic>>>(
        stream: userService.streamAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No users found."));
          }

          List<Map<String, dynamic>> users = snapshot.data!;

          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.7, // Give ListView space
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: users[index]['profilePicture'] != null &&
                            users[index]['profilePicture'] != ''
                        ? NetworkImage(users[index]['profilePicture'])
                        : AssetImage("assets/default_avatar.png") as ImageProvider,
                  ),
                  title: Text(users[index]['name']),
                  subtitle: Text(users[index]['role']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          userService.deleteUser(users[index]['email']);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          _editUser(users[index]);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      )
    ],
  ),
),

    );
  }
}
