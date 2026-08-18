import 'package:replicaz/core/bootstrap/app_bootstrap.dart';
import 'package:replicaz/core/constants/storage_keys.dart';
import 'package:replicaz/core/demo/fixture_loader.dart';
import 'package:replicaz/core/storage/local_store.dart';
import 'package:replicaz/features/auth/domain/user_account.dart';

/// Seeds local stores from `assets/fixtures/demo/*.json`.
///
/// ## Switch to real Dio API later
/// 1. Stop calling [ensureFromFixtures] (only used by offline demo login).
/// 2. Keep `AppConfig.useRemoteBackend=true` and clear demo session.
/// 3. Messaging/auth go through [RemoteMessagingApi] / Dio — fixtures untouched.
///
/// Bump `meta.json` → `version` to force re-seed on next demo login.
abstract final class DemoSeed {
  /// Apply fixture pack into [LocalStore] (+ optional auth user).
  ///
  /// [force]: overwrite even if version matches (debug).
  static Future<UserAccount> ensureFromFixtures({
    bool force = false,
  }) async {
    final store = AppBootstrap.store;
    final meta = await FixtureLoader.meta();
    final version = meta['version'] as int? ?? 1;
    final applied = store.getInt(StorageKeys.fixtureVersion) ?? 0;

    if (!force && applied == version) {
      final existing = store.getJsonMap(StorageKeys.authUser);
      if (existing != null) {
        return UserAccount.fromJson(existing);
      }
    }

    final demoUserRaw = Map<String, dynamic>.from(
      meta['demoUser'] as Map? ?? {},
    );
    final user = UserAccount(
      id: demoUserRaw['id'] as String? ?? 'user_demo',
      email: demoUserRaw['email'] as String? ?? 'demo@replicaz.local',
      displayName: demoUserRaw['displayName'] as String? ?? 'Demo',
      alias: demoUserRaw['alias'] as String? ??
          demoUserRaw['displayName'] as String? ??
          'Demo',
    );

    final identities = await FixtureLoader.loadList('identities.json');
    final contacts = await FixtureLoader.loadList('contacts.json');
    final notes = await FixtureLoader.loadList('notes.json');
    final followUps = await FixtureLoader.loadList('follow_ups.json');
    final conversations = await FixtureLoader.loadList('conversations.json');
    final messages = await FixtureLoader.loadList('messages.json');
    final bindings = await FixtureLoader.loadMap('room_identity_bindings.json');
    final cursors = await FixtureLoader.loadMap('room_read_cursors.json');

    await store.setJson(StorageKeys.identities, identities);
    await store.setJson(StorageKeys.contacts, contacts);
    await store.setJson(StorageKeys.notes, notes);
    await store.setJson(StorageKeys.followUps, followUps);
    await store.setJson(StorageKeys.conversations, conversations);
    await store.setJson(StorageKeys.messages, messages);
    await store.setJson(StorageKeys.roomIdentityBindings, bindings);
    await store.setJson(StorageKeys.roomReadCursors, cursors);
    await store.remove(StorageKeys.hiddenRoomIds);

    final activeId = meta['activeIdentityId'] as String? ??
        (identities.isNotEmpty ? identities.first['id'] as String : null);
    if (activeId != null) {
      await store.setString(StorageKeys.activeIdentityId, activeId);
    }

    await store.setJson(StorageKeys.authUser, user.toJson());
    await store.setInt(StorageKeys.fixtureVersion, version);

    try {
      await AppBootstrap.secureStorage.write(
        key: StorageKeys.authToken,
        value: 'fixture-${user.id}',
      );
    } catch (_) {
      // Tests / hosts without secure_storage plugin — local session still works.
    }

    return user;
  }

  /// @deprecated Prefer [ensureFromFixtures]. Kept for call-site compatibility.
  static Future<void> ensureShellData({required String userId}) async {
    await ensureFromFixtures();
  }
}
