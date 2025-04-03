import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:surwa/data/models/profile.dart';
import 'package:surwa/services/image_picker_service.dart';
import 'package:surwa/services/profile_service.dart';

import 'auth_service_test.dart';
import 'post_service_test.mocks.dart';

@GenerateMocks([
  FirebaseFirestore,
  auth.FirebaseAuth,
  ImagePickerService,
  CollectionReference,
  DocumentSnapshot,
  QuerySnapshot
])
void main() {
  late ProfileService profileService;
  late MockFirebaseFirestore mockFirestore;
  late MockFirebaseAuth mockAuth;
  late MockImagePickerService mockImagePickerService;
  late MockCollectionReference mockProfileCollection;
  late MockCollectionReference mockUserMapCollection;
  late MockDocumentSnapshot mockDocumentSnapshot;
  late MockQuerySnapshot mockQuerySnapshot;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockImagePickerService = MockImagePickerService();
    mockProfileCollection = MockCollectionReference();
    mockUserMapCollection = MockCollectionReference();
    mockDocumentSnapshot = MockDocumentSnapshot();
    mockQuerySnapshot = MockQuerySnapshot();

    when(mockFirestore.collection('Profile')).thenReturn(mockProfileCollection);
    when(mockFirestore.collection('UserMap')).thenReturn(mockUserMapCollection);

    profileService = ProfileService();
  });

  group('ProfileService', () {
    test('createProfile should return error if user is not logged in',
        () async {
      when(mockAuth.currentUser).thenReturn(null);

      final result = await profileService
          .createProfile(Profile(username: 'test', name: 'Test User'));

      expect(result, 'Error: User is not logged in');
    });

    test('createProfile should return error if username is empty', () async {
      when(mockAuth.currentUser).thenReturn(MockUser());

      final result = await profileService
          .createProfile(Profile(username: '', name: 'Test User'));

      expect(result, 'Username cannot be empty');
    });

    test('createProfile should return error if username is already taken',
        () async {
      when(mockAuth.currentUser).thenReturn(MockUser());
      when(mockProfileCollection.where('username', isEqualTo: 'test'))
          .thenReturn(mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([mockDocumentSnapshot]);

      final result = await profileService
          .createProfile(Profile(username: 'test', name: 'Test User'));

      expect(result, 'Username already taken');
    });

    test('createProfile should upload image and save profile if valid',
        () async {
      final mockUser = MockUser();
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('123');
      when(mockProfileCollection.where('username', isEqualTo: 'test'))
          .thenReturn(mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([]);
      when(mockImagePickerService.uploadProfileImage(any, any))
          .thenAnswer((_) async => 'image_url');

      final result = await profileService.createProfile(
        Profile(username: 'test', name: 'Test User'),
        imageFile: File('path/to/image'),
      );

      expect(result, null);
      verify(mockProfileCollection.doc('123').set(any)).called(1);
      verify(mockUserMapCollection.doc('test').set(any)).called(1);
    });

    test('getCurrentUsername should return username if profile exists',
        () async {
      final mockUser = MockUser();
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('123');
      when(mockProfileCollection.doc('123')).thenReturn(mockDocumentSnapshot);
      when(mockDocumentSnapshot.get())
          .thenAnswer((_) async => {'username': 'test'});

      final result = await profileService.getCurrentUsername();

      expect(result, 'test');
    });

    test('getCurrentUsername should return null if profile does not exist',
        () async {
      final mockUser = MockUser();
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('123');
      when(mockProfileCollection.doc('123')).thenReturn(mockDocumentSnapshot);
      when(mockDocumentSnapshot.get()).thenAnswer((_) async => null);

      final result = await profileService.getCurrentUsername();

      expect(result, null);
    });
  });
}
