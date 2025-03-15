import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:surwa/firebase_options.dart';
import 'package:surwa/screens/test%20screens/create_user.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Supabase with environment variables
  await Supabase.initialize(
    url: dotenv.env['supabaseUrl']!,
    anonKey: dotenv.env['supabaseKey']!,
  );

  runApp(const SurWa());
}


class SurWa extends StatelessWidget {
  const SurWa({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CreateProfile(),
    );
  }
}
