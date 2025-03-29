class Payment {
  final String paymentId;
  final String payerId;
  final String cartId;
  final String paymentAmount;
  final String transactionRefNo;
  final String timeStamp;

  Payment({
    required this.paymentId,
    required this.payerId,
    required this.cartId,
    required this.paymentAmount,
    required this.transactionRefNo,
    required this.timeStamp,
  });

  // Convert Firestore DocumentSnapshot to Payment Object
  factory Payment.fromFirestore(Map<String, dynamic> data, String docId) {
    return Payment(
      paymentId: docId,
      payerId: data['payerId'] ?? '',
      cartId: data['cartId'] ?? '',
      paymentAmount: data['paymentAmount'] ?? '',
      transactionRefNo: data['transactionRefNo']?? '',
      timeStamp: data['timeStamp'] ?? '',
    );
  }

  // Convert Payment Object to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'payerId': payerId,
      'cartId': cartId,
      'paymentAmount': paymentAmount,
      'timeStamp': timeStamp,
    };
  }
}
