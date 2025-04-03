import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:surwa/services/cart_service.dart';
import 'package:surwa/data/models/cart.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock implements CollectionReference {}

class MockQuery extends Mock implements Query {}

class MockQuerySnapshot extends Mock implements QuerySnapshot {}

class MockQueryDocumentSnapshot extends Mock implements QueryDocumentSnapshot {}

class MockDocumentReference extends Mock implements DocumentReference {}

void main() {
  group('CartService', () {
    late CartService cartService;
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference mockCartCollection;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCartCollection = MockCollectionReference();
      cartService = CartService();
      cartService.cartCollection = mockCartCollection;
    });

    test('should query carts with status PENDING', () async {
      final mockQuery = MockQuery();
      final mockQuerySnapshot = MockQuerySnapshot();
      final mockQueryDocumentSnapshot = MockQueryDocumentSnapshot();

      when(mockCartCollection.where('buyerId',
              isEqualTo: anyNamed('isEqualTo')))
          .thenReturn(mockQuery);
      when(mockQuery.where('status', isEqualTo: 'PENDING'))
          .thenReturn(mockQuery);
      when(mockQuery.limit(1)).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([mockQueryDocumentSnapshot]);
      when(mockQueryDocumentSnapshot['orderIds']).thenReturn([]);
      when(mockQueryDocumentSnapshot['totalPrice']).thenReturn('0.0');

      await cartService.createOrUpdateCart('userId', 'orderId', '10.0');

      verify(mockCartCollection.where('buyerId', isEqualTo: 'userId'))
          .called(1);
      verify(mockQuery.where('status', isEqualTo: 'PENDING')).called(1);
    });
  });
}
