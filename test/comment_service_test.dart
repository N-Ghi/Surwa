import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:surwa/data/models/comment.dart';
import 'package:surwa/services/comment_service.dart';

import '../lib/services/comment_service_test.mocks.dart';

@GenerateMocks([
  FirebaseFirestore,
  FirebaseAuth,
  User,
  CollectionReference,
  DocumentReference
])
void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late MockCollectionReference mockCollection;
  late MockDocumentReference mockDocument;
  late CommentService commentService;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    mockCollection = MockCollectionReference();
    mockDocument = MockDocumentReference();

    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn('testUserId');
    when(mockFirestore.collection('Comment')).thenReturn(mockCollection);
    when(mockCollection.doc(any)).thenReturn(mockDocument);
    when(mockDocument.collection('comments')).thenReturn(mockCollection);

    commentService = CommentService();
  });

  test('createComment should create a new comment successfully', () async {
    final comment = Comment(
      commentId: '',
      postId: 'testPostId',
      commenterId: '',
      message: 'Test message',
      timeStamp: Timestamp.now(),
    );

    when(mockDocument.set(any)).thenAnswer((_) async => Future.value());

    await commentService.createComment(comment);

    verify(mockDocument.set(any)).called(1);
  });

  test('createComment should handle errors gracefully', () async {
    final comment = Comment(
      commentId: '',
      postId: 'testPostId',
      commenterId: '',
      message: 'Test message',
      timeStamp: Timestamp.now(),
    );

    when(mockDocument.set(any)).thenThrow(Exception('Test exception'));

    await commentService.createComment(comment);

    verify(mockDocument.set(any)).called(1);
  });
}
