import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:surwa/data/constants/constants.dart';
import 'package:surwa/data/notifiers/auth_notifier.dart';
import 'package:surwa/data/notifiers/notifiers.dart';
import 'package:surwa/data/notifiers/profile_completion_notifier.dart';
import 'package:surwa/firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:surwa/widgets/auth_wrap.dart';

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

  runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => ProfileCompletionNotifier()),
          ChangeNotifierProvider(create: (context) => AuthNotifier()),
        ],
        child: MyApp(),
      ),
    );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    initThemeMode();
    super.initState();
  }

  void initThemeMode() async{
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool? repeat = prefs.getBool(KConstants.themeModeKey);
    isDarkModeNotifier.value = repeat ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDark, child) {
        return MaterialApp(
          title: 'SuRwa App',
          theme: ThemeData(
            primarySwatch: Colors.yellow,
            brightness: isDark ? Brightness.dark : Brightness.light,
          ),
          debugShowCheckedModeBanner: false,
          home: AuthWrapper(),
        );
      },);
  }
}