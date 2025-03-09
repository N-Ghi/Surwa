import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:surwa/firebase_options.dart';
import 'package:surwa/screens/create_user.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SurWa());
}

class SurWa extends StatelessWidget {
  const SurWa({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: createUser(),
    );
  }
}