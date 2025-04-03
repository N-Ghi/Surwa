import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:surwa/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:surwa/data/notifiers/auth_notifier.dart';
import 'package:surwa/data/notifiers/profile_completion_notifier.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockUserCredential extends Mock implements UserCredential {}

class MockUser extends Mock implements User {}

class MockAuthNotifier extends Mock implements AuthNotifier {}

class MockProfileCompletionNotifier extends Mock
    implements ProfileCompletionNotifier {}

void main() {
  late AuthService authService;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockFirebaseFirestore mockFirebaseFirestore;
  late MockAuthNotifier mockAuthNotifier;
  late MockProfileCompletionNotifier mockProfileCompletionNotifier;

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockFirebaseFirestore = MockFirebaseFirestore();
    mockAuthNotifier = MockAuthNotifier();
    mockProfileCompletionNotifier = MockProfileCompletionNotifier();
    authService = AuthService(
      firebaseAuth: mockFirebaseAuth,
      firebaseFirestore: mockFirebaseFirestore,
    );
  });

  group('AuthService', () {
    test('signUpWithEmail should return null on success', () async {
      final mockUserCredential = MockUserCredential();
      final mockUser = MockUser();

      when(mockFirebaseAuth.createUserWithEmailAndPassword(
              email: anyNamed('email'), password: anyNamed('password')))
          .thenAnswer((_) async => mockUserCredential);
      when(mockUserCredential.user).thenReturn(mockUser);
      when(mockUser.sendEmailVerification()).thenAnswer((_) async {});

      final result = await authService.signUpWithEmail(
        'test@example.com',
        'password123',
      );

      expect(result, null);
    });

    test('signInWithEmail should return null on success', () async {
      final mockUserCredential = MockUserCredential();
      final mockUser = MockUser();

      when(mockFirebaseAuth.signInWithEmailAndPassword(
              email: anyNamed('email'), password: anyNamed('password')))
          .thenAnswer((_) async => mockUserCredential);
      when(mockUserCredential.user).thenReturn(mockUser);
      when(mockUser.emailVerified).thenReturn(true);
      when(mockFirebaseFirestore.collection('profiles').doc(any).get())
          .thenAnswer((_) async => MockDocumentSnapshot());

      final result = await authService.signInWithEmail(
        'test@example.com',
        'password123',
        mockAuthNotifier,
      );

      expect(result, null);
    });

    test('resetPassword should complete without errors', () async {
      when(mockFirebaseAuth.sendPasswordResetEmail(email: anyNamed('email')))
          .thenAnswer((_) async {});

      expect(
        authService.resetPassword('test@example.com'),
        completes,
      );
    });

    test('updatePassword should return null on success', () async {
      final mockUser = MockUser();
      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(mockUser.updatePassword(any)).thenAnswer((_) async {});

      final result = await authService.updatePassword('newPassword123');
      expect(result, null);
    });

    test('updateEmail should return null on success', () async {
      final mockUser = MockUser();
      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(mockUser.updateEmail(any)).thenAnswer((_) async {});

      final result = await authService.updateEmail('newemail@example.com');
      expect(result, null);
    });

    test('deleteAccount should return null on success', () async {
      final mockUser = MockUser();
      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('testUserId');
      when(mockFirebaseFirestore.collection(any).doc(any).delete())
          .thenAnswer((_) async {});
      when(mockUser.delete()).thenAnswer((_) async {});

      final result = await authService.deleteAccount();
      expect(result, null);
    });
  });
}

class MockDocumentSnapshot extends Mock implements DocumentSnapshot {
  @override
  bool exists() => true;
}

