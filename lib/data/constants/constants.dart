import 'dart:math';

import 'package:flutter/material.dart';

class KTestStyle {

  static const TextStyle titleText = TextStyle(
    color: Colors.purpleAccent,
    fontWeight: FontWeight.bold,
    fontSize: 20.0,
  );
  static const TextStyle descriptionText = TextStyle(
    fontSize: 16.0,
  );
  static const TextStyle heroText = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 50.0,
    letterSpacing: 50.0,
  );
}

class KConstants {
  static const themeModeKey = 'themeModeKey';
}

String generateTransactionId() {
  Random random = Random();
  String digits = List.generate(6, (index) => random.nextInt(10).toString()).join();
  return 'trans-$digits';
}