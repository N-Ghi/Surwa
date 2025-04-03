import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:surwa/widgets/auth_wrap.dart';
import 'package:surwa/data/notifiers/profile_completion_notifier.dart';
import 'package:surwa/screens/complete_profile.dart';
import 'package:surwa/screens/feeds.dart';
import 'package:surwa/screens/login.dart';

import 'auth_service_test.dart';

@GenerateMocks([FirebaseAuth, ProfileCompletionNotifier])
void main() {
  testWidgets('Displays LoginScreen when user is not logged in',
      (WidgetTester tester) async {
    // Mock FirebaseAuth to return null for currentUser
    final mockFirebaseAuth = MockFirebaseAuth();
    when(mockFirebaseAuth.currentUser).thenReturn(null);

    await tester.pumpWidget(
      Provider<FirebaseAuth>.value(
        value: mockFirebaseAuth,
        child: const MaterialApp(
          home: AuthWrapper(),
        ),
      ),
    );

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('Displays DashboardScreen when profile is complete',
      (WidgetTester tester) async {
    // Mock FirebaseAuth to return a user
    final mockFirebaseAuth = MockFirebaseAuth();
    when(mockFirebaseAuth.currentUser).thenReturn(MockUser());

    // Mock ProfileCompletionNotifier to indicate profile is complete
    final mockProfileNotifier = MockProfileCompletionNotifier();
    when(mockProfileNotifier.hasCheckedProfile).thenReturn(true);
    when(mockProfileNotifier.isProfileComplete).thenReturn(true);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<FirebaseAuth>.value(value: mockFirebaseAuth),
          ChangeNotifierProvider<ProfileCompletionNotifier>.value(
              value: mockProfileNotifier),
        ],
        child: const MaterialApp(
          home: AuthWrapper(),
        ),
      ),
    );

    expect(find.byType(DashboardScreen), findsOneWidget);
  });

  testWidgets('Displays CompleteProfile when profile is incomplete',
      (WidgetTester tester) async {
    // Mock FirebaseAuth to return a user
    final mockFirebaseAuth = MockFirebaseAuth();
    when(mockFirebaseAuth.currentUser).thenReturn(MockUser());

    // Mock ProfileCompletionNotifier to indicate profile is incomplete
    final mockProfileNotifier = MockProfileCompletionNotifier();
    when(mockProfileNotifier.hasCheckedProfile).thenReturn(true);
    when(mockProfileNotifier.isProfileComplete).thenReturn(false);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<FirebaseAuth>.value(value: mockFirebaseAuth),
          ChangeNotifierProvider<ProfileCompletionNotifier>.value(
              value: mockProfileNotifier),
        ],
        child: const MaterialApp(
          home: AuthWrapper(),
        ),
      ),
    );

    expect(find.byType(CompleteProfile), findsOneWidget);
  });

  testWidgets('Displays loading indicator while profile is being checked',
      (WidgetTester tester) async {
    // Mock FirebaseAuth to return a user
    final mockFirebaseAuth = MockFirebaseAuth();
    when(mockFirebaseAuth.currentUser).thenReturn(MockUser());

    // Mock ProfileCompletionNotifier to indicate profile check is not complete
    final mockProfileNotifier = MockProfileCompletionNotifier();
    when(mockProfileNotifier.hasCheckedProfile).thenReturn(false);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<FirebaseAuth>.value(value: mockFirebaseAuth),
          ChangeNotifierProvider<ProfileCompletionNotifier>.value(
              value: mockProfileNotifier),
        ],
        child: const MaterialApp(
          home: AuthWrapper(),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text("Loading profile..."), findsOneWidget);
  });
}

class MockUser extends Mock implements User {}

