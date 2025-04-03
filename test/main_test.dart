import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('WidgetsFlutterBinding.ensureInitialized is called',
      (WidgetTester tester) async {
    // Ensure that WidgetsFlutterBinding is initialized
    WidgetsFlutterBinding.ensureInitialized();

    // Verify that no exceptions are thrown during initialization
    expect(() => WidgetsFlutterBinding.ensureInitialized(), returnsNormally);
  });
}
