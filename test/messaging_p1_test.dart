import 'package:flutter_test/flutter_test.dart';
import 'package:replicaz/core/constants/storage_keys.dart';
import 'package:replicaz/core/storage/local_store.dart';
import 'package:replicaz/features/messaging/data/messaging_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MessagingService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    service = MessagingService(store: LocalStore(prefs), remote: null);
  });

  test('hideRoom keeps room out of identity list', () async {
    final c = await service.createDirectConversation(
      ownerIdentityId: 'id-personal',
      createdByUserId: 'u1',
      title: 'Bob',
    );
    var list = await service.conversationsForIdentity('id-personal');
    expect(list.any((e) => e.id == c.id), isTrue);

    await service.hideRoom(c.id);
    list = await service.conversationsForIdentity('id-personal');
    expect(list.any((e) => e.id == c.id), isFalse);
  });

  test('markRoomRead clears unread after activity', () async {
    final c = await service.createDirectConversation(
      ownerIdentityId: 'id-personal',
      createdByUserId: 'u1',
      title: 'Bob',
    );
    // Simulate inbound by writing local conversation preview newer than read.
    final store = service.store;
    final all = store.getJsonList(StorageKeys.conversations);
    final idx = all.indexWhere((e) => e['id'] == c.id);
    all[idx] = {
      ...all[idx],
      'lastMessageAt': DateTime.now().toUtc().add(const Duration(minutes: 1)).toIso8601String(),
      'lastMessagePreview': 'hello',
    };
    await store.setJson(StorageKeys.conversations, all);

    var list = await service.conversationsForIdentity('id-personal');
    final row = list.firstWhere((e) => e.id == c.id);
    expect(row.unreadCount, greaterThan(0));

    await service.markRoomRead(
      c.id,
      at: DateTime.now().toUtc().add(const Duration(minutes: 2)),
    );
    list = await service.conversationsForIdentity('id-personal');
    expect(list.firstWhere((e) => e.id == c.id).unreadCount, 0);
  });
}
