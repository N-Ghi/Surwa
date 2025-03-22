import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:surwa/screens/test_screens/login_page.dart';
import 'package:surwa/screens/test_screens/register_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset("assets/lotties/home.json"),
                FittedBox(
                  child: Text("SuRwa",
                    style: TextStyle(
                      fontSize: 50.0,
                      letterSpacing: 25.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 20.0,),
                FilledButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                        MaterialPageRoute(builder:
                            (context) => RegisterScreen())
                      );
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: Size(double.infinity, 40.0),
                  ),
                  child: Text("Get Started"),
                  ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder:
                            (context) => LoginScreen())
                    );
                  },
                  style: TextButton.styleFrom(
                    minimumSize: Size(double.infinity, 40.0),
                  ),
                  child: Text("Login"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}