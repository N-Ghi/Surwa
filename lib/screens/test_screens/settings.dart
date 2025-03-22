import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:surwa/data/constants/constants.dart';
import 'package:surwa/data/notifiers/notifiers.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        centerTitle: true,
      ),
      body: Column(
          // mainAxisAlignment: MainAxisAlignment.start,
          // crossAxisAlignment: CrossAxisAlignment.center,
          children:<Widget>[
            Text(
                'Settings of Flutter Mapp',
                style: TextStyle(fontSize: 24),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Dark Mode?'),
                IconButton(
                  onPressed: () async{
                    isDarkModeNotifier.value = !isDarkModeNotifier.value;
                    final SharedPreferences prefs = await SharedPreferences.getInstance();
                    await prefs.setBool(KConstants.themeModeKey, isDarkModeNotifier.value);
                  },
                  icon: ValueListenableBuilder(
                    valueListenable: isDarkModeNotifier,
                    builder: (context, isDarkMode, child) {
                      return Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode);
                    },)
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    duration: Duration(seconds: 5),
                    content: Text("SnackBar"),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Text("Open SnackBar"),
            ),
            ElevatedButton(
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text("Alert Title"),
                        content: Text("Alert Content"),
                        actions: [
                          FilledButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text("Close"),
                          ),
                        ],
                      );
                    },
                );
              },
              child: Text("Open Dialog"),
            ),
          ],
      )
    );
  }
}