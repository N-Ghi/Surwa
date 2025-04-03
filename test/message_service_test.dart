import 'package:flutter_test/flutter_test.dart';
import 'package:surwa/services/message_service.dart';

void main() {
  group('MessageService', () {
    late MessageService messageService;

    setUp(() {
      messageService = MessageService();
    });

    test(
        'getChatId returns correct chat ID when senderID is greater than receiverID',
        () {
      final senderID = 'userB';
      final receiverID = 'userA';

      final chatId = messageService.getChatId(senderID, receiverID);

      expect(chatId, 'userB-userA');
    });

    test(
        'getChatId returns correct chat ID when receiverID is greater than senderID',
        () {
      final senderID = 'userA';
      final receiverID = 'userB';

      final chatId = messageService.getChatId(senderID, receiverID);

      expect(chatId, 'userB-userA');
    });

    test('getChatId returns the same chat ID regardless of parameter order',
        () {
      final senderID = 'userA';
      final receiverID = 'userB';

      final chatId1 = messageService.getChatId(senderID, receiverID);
      final chatId2 = messageService.getChatId(receiverID, senderID);

      expect(chatId1, chatId2);
    });
  });
}
