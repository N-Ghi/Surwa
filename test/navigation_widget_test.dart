import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surwa/widgets/navigation_widget.dart';

void main() {
  testWidgets('NavbarWidget updates selected index on tap',
      (WidgetTester tester) async {
    int currentIndex = 0;
    void onTap(int index) {
      currentIndex = index;
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: NavbarWidget(
            currentIndex: currentIndex,
            onTap: onTap,
          ),
        ),
      ),
    );

    // Verify initial state
    expect(currentIndex, 0);

    // Tap on the second BottomNavigationBarItem (Market)
    await tester.tap(find.text('Market'));
    await tester.pumpAndSettle();

    // Verify the index is updated
    expect(currentIndex, 1);

    // Tap on the third BottomNavigationBarItem (Post)
    await tester.tap(find.text('Post'));
    await tester.pumpAndSettle();

    // Verify the index is updated
    expect(currentIndex, 2);
  });
}
