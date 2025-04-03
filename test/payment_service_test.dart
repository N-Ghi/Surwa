import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:surwa/data/models/payment.dart';
import 'package:surwa/services/payment_service.dart';

class MockCollectionReference extends Mock implements CollectionReference {}

class MockDocumentReference extends Mock implements DocumentReference {}

class MockQuerySnapshot extends Mock implements QuerySnapshot {}

class MockQueryDocumentSnapshot extends Mock implements QueryDocumentSnapshot {}

class MockDocumentSnapshot extends Mock implements DocumentSnapshot {}

void main() {
  group('PaymentService', () {
    late PaymentService paymentService;
    late MockCollectionReference mockCollectionReference;

    setUp(() {
      mockCollectionReference = MockCollectionReference();
      paymentService = PaymentService();
      paymentService.paymentCollection = mockCollectionReference;
    });

    test('addPayment should add a payment with transactionRefNo', () async {
      final payment = Payment(
        payerId: 'payer123',
        cartId: 'cart456',
        paymentAmount: '100.00',
        transactionRefNo: 'txn789',
      );

      when(mockCollectionReference.add(any))
          .thenAnswer((_) async => MockDocumentReference());

      await paymentService.addPayment(payment);

      verify(mockCollectionReference
              .add(argThat(containsPair('transactionRefNo', 'txn789'))))
          .called(1);
    });

    test('getPayments should fetch all payments ordered by timestamp',
        () async {
      final mockQuerySnapshot = MockQuerySnapshot();
      final mockQueryDocumentSnapshot = MockQueryDocumentSnapshot();

      when(mockCollectionReference.orderBy('timestamp', descending: true))
          .thenReturn(mockCollectionReference);
      when(mockCollectionReference.snapshots())
          .thenAnswer((_) => Stream.value(mockQuerySnapshot));
      when(mockQuerySnapshot.docs).thenReturn([mockQueryDocumentSnapshot]);
      when(mockQueryDocumentSnapshot.data()).thenReturn({
        'payerId': 'payer123',
        'cartId': 'cart456',
        'paymentAmount': '100.00',
        'transactionRefNo': 'txn789',
      });
      when(mockQueryDocumentSnapshot.id).thenReturn('paymentId123');

      final paymentsStream = paymentService.getPayments();

      await expectLater(
        paymentsStream,
        emits(isA<List<Payment>>().having(
            (payments) => payments.first.transactionRefNo,
            'transactionRefNo',
            'txn789')),
      );
    });
  });
}
