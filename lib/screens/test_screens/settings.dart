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
          ],
      )
    );
  }
}