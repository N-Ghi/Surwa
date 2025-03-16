import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:surwa/data/notifiers/auth_notifier.dart';
import 'package:surwa/services/auth_service.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authNotifier = Provider.of<AuthNotifier>(context);
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(title: Text("Home")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Welcome, ${authNotifier.user?.email}"),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await authService.signOut(authNotifier);
              },
              child: Text("Logout"),
            ),
          ],
        ),
      ),
    );
  }
}
