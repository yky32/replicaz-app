import 'package:flutter_test/flutter_test.dart';
import 'package:replicaz/core/demo/demo_seed.dart';
import 'package:replicaz/core/bootstrap/app_bootstrap.dart';
import 'package:replicaz/core/constants/storage_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fixtures seed identities contacts chats', () async {
    SharedPreferences.setMockInitialValues({});
    await AppBootstrap.init();
    final user = await DemoSeed.ensureFromFixtures(force: true);
    expect(user.id, 'user_demo');
    final ids = AppBootstrap.store.getJsonList(StorageKeys.identities);
    expect(ids.length, 3);
    final contacts = AppBootstrap.store.getJsonList(StorageKeys.contacts);
    expect(contacts.length, greaterThanOrEqualTo(6));
    final convos = AppBootstrap.store.getJsonList(StorageKeys.conversations);
    expect(convos.length, 6);
    final msgs = AppBootstrap.store.getJsonList(StorageKeys.messages);
    expect(msgs.length, greaterThanOrEqualTo(10));
    final fus = AppBootstrap.store.getJsonList(StorageKeys.followUps);
    expect(fus.length, 6);

    final lifeIds = ['id_personal', 'id_job', 'id_freelance'];
    final now = DateTime.now().toUtc();
    final soonCutoff = now.add(const Duration(days: 2, hours: 12));

    for (final lifeId in lifeIds) {
      final lifeConvos = convos.where((c) => c['ownerIdentityId'] == lifeId);
      expect(
        lifeConvos.any((c) => (c['unreadCount'] as num? ?? 0) >= 1),
        isTrue,
        reason: '$lifeId needs ≥1 unread chat',
      );

      final openSoon = fus.where((f) {
        if (f['identityId'] != lifeId) return false;
        if (f['status'] != 'open') return false;
        final dueRaw = f['dueAt'] as String?;
        if (dueRaw == null) return false;
        final due = DateTime.parse(dueRaw).toUtc();
        return !due.isAfter(soonCutoff);
      });
      expect(
        openSoon.isNotEmpty,
        isTrue,
        reason: '$lifeId needs ≥1 open FU due soon/overdue',
      );
    }

    // Chat titles should resolve to contacts (Circle hub / FU contactName).
    final contactNames =
        contacts.map((c) => c['name'] as String).toSet();
    for (final c in convos) {
      final title = c['title'] as String?;
      expect(title, isNotNull);
      expect(
        contactNames.contains(title),
        isTrue,
        reason: 'chat "$title" should have matching contact',
      );
    }

    // Relative seed: messages get fresh createdAt (not ancient absolute ISO).
    for (final m in msgs) {
      expect(m['createdAt'], isNotNull);
      final created = DateTime.parse(m['createdAt'] as String).toUtc();
      expect(
        created.isAfter(now.subtract(const Duration(days: 3))),
        isTrue,
        reason: 'message ${m['id']} createdAt should be relative/recent',
      );
    }
  });
}
