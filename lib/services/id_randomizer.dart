import 'dart:math';

String generateRandomId() {
  const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  final Random random = Random();
  int length = 6 + random.nextInt(3); // Random length between 6 and 8
  return List.generate(length, (index) => chars[random.nextInt(chars.length)]).join();
}
