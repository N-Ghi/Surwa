import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../lib/services/follow_service.dart';
import '../lib/services/follow_service_test.mocks.dart';

@GenerateMocks([
  FirebaseFirestore,
  auth.FirebaseAuth,
  auth.User,
  DocumentReference,
  Transaction,
  DocumentSnapshot
])
void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late FollowService followService;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();

    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn('currentUserId');

    followService = FollowService();
    followService.firestore = mockFirestore;
  });

  group('FollowService', () {
    test(
        'followUser adds target user to following and current user to followers',
        () async {
      final mockCurrentUserRef = MockDocumentReference();
      final mockTargetUserRef = MockDocumentReference();
      final mockTransaction = MockTransaction();
      final mockCurrentUserSnapshot = MockDocumentSnapshot();
      final mockTargetUserSnapshot = MockDocumentSnapshot();

      when(mockFirestore.collection('Profile'))
          .thenReturn(MockCollectionReference());
      when(mockFirestore.collection('Profile').doc('currentUserId'))
          .thenReturn(mockCurrentUserRef);
      when(mockFirestore.collection('Profile').doc('targetUserId'))
          .thenReturn(mockTargetUserRef);

      when(mockCurrentUserSnapshot.exists).thenReturn(true);
      when(mockTargetUserSnapshot.exists).thenReturn(true);
      when(mockCurrentUserSnapshot['following']).thenReturn([]);
      when(mockTargetUserSnapshot['followers']).thenReturn([]);

      when(mockFirestore.runTransaction(any)).thenAnswer((invocation) async {
        final transactionHandler = invocation.positionalArguments[0]
            as Future<void> Function(Transaction);
        await transactionHandler(mockTransaction);
        return null;
      });

      when(mockTransaction.get(mockCurrentUserRef))
          .thenAnswer((_) async => mockCurrentUserSnapshot);
      when(mockTransaction.get(mockTargetUserRef))
          .thenAnswer((_) async => mockTargetUserSnapshot);

      await followService.followUser('targetUserId');

      verify(mockTransaction.update(mockCurrentUserRef, {
        'following': ['targetUserId']
      })).called(1);
      verify(mockTransaction.update(mockTargetUserRef, {
        'followers': ['currentUserId']
      })).called(1);
    });
  });
}
