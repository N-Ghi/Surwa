import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:surwa/data/constants/constants.dart';
import 'package:surwa/data/notifiers/notifiers.dart';
import 'package:surwa/services/auth_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AuthService authService = AuthService();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController newEmailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void handleResetPassword() async {
    await authService.resetPassword(emailController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Password reset email sent if the email exists.")),
    );
  }

  void handleUpdateEmail() async {
    String? result = await authService.updateEmail(newEmailController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result ?? "Email updated successfully")),
    );
  }

  void handleUpdatePassword() async {
    String? result = await authService.updatePassword(passwordController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result ?? "Password updated successfully")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Dark Mode?'),
                IconButton(
                  onPressed: () async {
                    isDarkModeNotifier.value = !isDarkModeNotifier.value;
                    final SharedPreferences prefs = await SharedPreferences.getInstance();
                    await prefs.setBool(KConstants.themeModeKey, isDarkModeNotifier.value);
                  },
                  icon: ValueListenableBuilder(
                    valueListenable: isDarkModeNotifier,
                    builder: (context, isDarkMode, child) {
                      return Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Reset Password
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Forgot Password?'),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Reset Password"),
                        content: TextField(
                          controller: emailController,
                          decoration: const InputDecoration(labelText: "Enter your email"),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel"),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              handleResetPassword();
                              Navigator.pop(context);
                            },
                            child: const Text("Send Email"),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text("Reset"),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Update Email
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Update Email'),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Update Email"),
                        content: TextField(
                          controller: newEmailController,
                          decoration: const InputDecoration(labelText: "New Email"),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel"),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              handleUpdateEmail();
                              Navigator.pop(context);
                            },
                            child: const Text("Update"),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text("Update"),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Update Password
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Update Password'),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Update Password"),
                        content: TextField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: "New Password"),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel"),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              handleUpdatePassword();
                              Navigator.pop(context);
                            },
                            child: const Text("Update"),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text("Update"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
