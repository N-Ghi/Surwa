import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:surwa/data/models/post.dart';
import 'package:surwa/services/post_service.dart';
import 'package:surwa/services/image_picker_service.dart';
import 'package:surwa/services/profile_service.dart';

import '../lib/services/post_service_test.mocks.dart';

@GenerateMocks([
  FirebaseFirestore,
  auth.FirebaseAuth,
  ImagePickerService,
  ProfileService,
  CollectionReference,
  DocumentReference,
  WriteBatch,
  QuerySnapshot,
  QueryDocumentSnapshot
])
void main() {
  late PostService postService;
  late MockFirebaseFirestore mockFirestore;
  late MockFirebaseAuth mockAuth;
  late MockImagePickerService mockImagePickerService;
  late MockProfileService mockProfileService;
  late MockCollectionReference mockPostsCollection;
  late MockDocumentReference mockUserDocRef;
  late MockWriteBatch mockBatch;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockImagePickerService = MockImagePickerService();
    mockProfileService = MockProfileService();
    mockPostsCollection = MockCollectionReference();
    mockUserDocRef = MockDocumentReference();
    mockBatch = MockWriteBatch();

    postService = PostService();
  });

  group('PostService', () {
    test('createPost uploads image and creates a post', () async {
      final mockUser = MockUser();
      final mockFile = MockFile();
      final post = Post(
        postID: 'testPostID',
        posterID: 'testUserID',
        description: 'Test description',
        dateCreated: Timestamp.now(),
        imageUrl: null,
      );

      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('testUserID');
      when(mockImagePickerService.uploadPostImage(mockFile, any))
          .thenAnswer((_) async => 'testImageUrl');
      when(mockFirestore.collection('Post')).thenReturn(mockPostsCollection);
      when(mockPostsCollection.doc('testUserID')).thenReturn(mockUserDocRef);
      when(mockFirestore.batch()).thenReturn(mockBatch);

      await postService.createPost(post, mockFile);

      verify(mockImagePickerService.uploadPostImage(
              mockFile, 'testUserID/testPostID'))
          .called(1);
      verify(mockBatch.set(any, any, any)).called(2);
      verify(mockBatch.commit()).called(1);
    });

    test('streamAllPostsExceptCurrentUser streams posts excluding current user',
        () async {
      final mockUser = MockUser();
      final mockSnapshot = MockQuerySnapshot();
      final mockDoc = MockQueryDocumentSnapshot();

      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('testUserID');
      when(mockFirestore.collection('Post')).thenReturn(mockPostsCollection);
      when(mockPostsCollection.snapshots())
          .thenAnswer((_) => Stream.value(mockSnapshot));
      when(mockSnapshot.docs).thenReturn([mockDoc]);
      when(mockDoc.id).thenReturn('otherUserID');
      when(mockFirestore
              .collection('Post')
              .doc('otherUserID')
              .collection('posts')
              .orderBy('DateCreated', descending: true)
              .get())
          .thenAnswer((_) async => mockSnapshot);
      when(mockSnapshot.docs).thenReturn([mockDoc]);
      when(mockDoc.data()).thenReturn({
        'postID': 'testPostID',
        'posterID': 'otherUserID',
        'description': 'Test description',
        'dateCreated': Timestamp.now(),
        'imageUrl': null,
      });

      final stream = postService.streamAllPostsExceptCurrentUser();
      final posts = await stream.first;

      expect(posts.length, 1);
      expect(posts.first.posterID, 'otherUserID');
    });

    test('deletePost deletes post and associated comments', () async {
      final mockUser = MockUser();
      final mockCommentsQuery = MockQuerySnapshot();
      final mockCommentDoc = MockQueryDocumentSnapshot();

      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('testUserID');
      when(mockFirestore.collection('Comment')).thenReturn(mockPostsCollection);
      when(mockPostsCollection.where('postID', isEqualTo: 'testPostID').get())
          .thenAnswer((_) async => mockCommentsQuery);
      when(mockCommentsQuery.docs).thenReturn([mockCommentDoc]);
      when(mockFirestore.batch()).thenReturn(mockBatch);

      final result = await postService.deletePost('testPostID');

      expect(result, true);
      verify(mockBatch.delete(mockCommentDoc.reference)).called(1);
      verify(mockBatch.commit()).called(1);
      verify(mockFirestore
              .collection('Post')
              .doc('testUserID')
              .collection('posts')
              .doc('testPostID')
              .delete())
          .called(1);
    });
  });
}
