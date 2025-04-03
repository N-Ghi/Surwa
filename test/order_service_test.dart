import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:surwa/data/models/order.dart';
import 'package:surwa/services/order_service.dart';

// Mock classes
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock implements CollectionReference {}

class MockDocumentReference extends Mock implements DocumentReference {}

class MockQuerySnapshot extends Mock implements QuerySnapshot {}

class MockQueryDocumentSnapshot extends Mock implements QueryDocumentSnapshot {}

void main() {
  group('OrderService Tests', () {
    late OrderService orderService;
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference mockCollection;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference();
      orderService = OrderService();
      orderService.orderCollection = mockCollection;
    });

    test('addOrder should add a new order and return its ID', () async {
      final mockDoc = MockDocumentReference();
      when(mockCollection.doc()).thenReturn(mockDoc);
      when(mockDoc.id).thenReturn('testOrderId');
      when(mockDoc.set(any)).thenAnswer((_) async => {});

      final order = OrderClass(
        productId: 'testProductId',
        userId: 'testUserId',
        quantity: 2,
        price: '20.00',
      );

      final orderId = await orderService.addOrder(order);

      expect(orderId, 'testOrderId');
      verify(mockDoc.set({
        'orderId': 'testOrderId',
        'productId': 'testProductId',
        'userId': 'testUserId',
        'quantity': 2,
        'price': '20.00',
        'timestamp': FieldValue.serverTimestamp(),
      })).called(1);
    });

    test('getOrdersByUserId should fetch orders for a specific user', () async {
      final mockQuerySnapshot = MockQuerySnapshot();
      final mockQueryDoc = MockQueryDocumentSnapshot();
      when(mockCollection.where('userId', isEqualTo: 'testUserId'))
          .thenReturn(mockCollection);
      when(mockCollection.orderBy('timestamp', descending: true))
          .thenReturn(mockCollection);
      when(mockCollection.snapshots())
          .thenAnswer((_) => Stream.value(mockQuerySnapshot));
      when(mockQuerySnapshot.docs).thenReturn([mockQueryDoc]);
      when(mockQueryDoc.data()).thenReturn({
        'orderId': 'testOrderId',
        'productId': 'testProductId',
        'userId': 'testUserId',
        'quantity': 2,
        'price': '20.00',
        'timestamp': Timestamp.now(),
      });
      when(mockQueryDoc.id).thenReturn('testOrderId');

      final stream = orderService.getOrdersByUserId('testUserId');
      final orders = await stream.first;

      expect(orders.length, 1);
      expect(orders.first.userId, 'testUserId');
    });
  });
}
