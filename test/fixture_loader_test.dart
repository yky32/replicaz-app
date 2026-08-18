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
  });
}
