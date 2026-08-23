import 'package:replicaz/core/bootstrap/app_bootstrap.dart';
import 'package:replicaz/core/constants/storage_keys.dart';
import 'package:replicaz/core/demo/fixture_loader.dart';
import 'package:replicaz/features/auth/domain/user_account.dart';

/// Seeds local stores from `assets/fixtures/demo/*.json`.
///
/// Dates: prefer `*OffsetDays` / `*OffsetHours` relative to now so Needs you
/// always has overdue / due-today / recent chats.
///
/// Bump `meta.json` → `version` to force re-seed on next demo login.
abstract final class DemoSeed {
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

    final now = DateTime.now().toUtc();
    final identities = _withRelativeDates(
      await FixtureLoader.loadList('identities.json'),
      now,
    );
    final contacts = _withRelativeDates(
      await FixtureLoader.loadList('contacts.json'),
      now,
    );
    final notes = _withRelativeDates(
      await FixtureLoader.loadList('notes.json'),
      now,
    );
    final followUps = _withRelativeDates(
      await FixtureLoader.loadList('follow_ups.json'),
      now,
    );
    List<Map<String, dynamic>> receipts = [];
    try {
      receipts = _withRelativeDates(
        await FixtureLoader.loadList('receipts.json'),
        now,
      );
    } catch (_) {}
    final conversations = _withRelativeDates(
      await FixtureLoader.loadList('conversations.json'),
      now,
    );
    final messages = _withRelativeDates(
      await FixtureLoader.loadList('messages.json'),
      now,
    );
    final bindings = await FixtureLoader.loadMap('room_identity_bindings.json');
    final cursors = await FixtureLoader.loadMap('room_read_cursors.json');

    await store.setJson(StorageKeys.identities, identities);
    await store.setJson(StorageKeys.contacts, contacts);
    await store.setJson(StorageKeys.notes, notes);
    await store.setJson(StorageKeys.followUps, followUps);
    await store.setJson(StorageKeys.receipts, receipts);
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
    } catch (_) {}

    return user;
  }

  static List<Map<String, dynamic>> _withRelativeDates(
    List<Map<String, dynamic>> rows,
    DateTime now,
  ) {
    return rows.map((raw) {
      final m = Map<String, dynamic>.from(raw);
      void day(String offsetKey, String isoKey) {
        final o = m.remove(offsetKey);
        if (o is int) {
          m[isoKey] = now.add(Duration(days: o)).toIso8601String();
        } else if (o is num) {
          m[isoKey] = now.add(Duration(days: o.toInt())).toIso8601String();
        }
      }

      void hours(String offsetKey, String isoKey) {
        final o = m.remove(offsetKey);
        if (o is int) {
          m[isoKey] = now.add(Duration(hours: o)).toIso8601String();
        } else if (o is num) {
          m[isoKey] = now.add(Duration(hours: o.toInt())).toIso8601String();
        }
      }

      day('dueOffsetDays', 'dueAt');
      day('createdOffsetDays', 'createdAt');
      day('updatedOffsetDays', 'updatedAt');
      hours('lastMessageOffsetHours', 'lastMessageAt');
      hours('createdOffsetHours', 'createdAt');
      hours('updatedOffsetHours', 'updatedAt');
      hours('serverReceivedOffsetHours', 'serverReceivedAt');

      // Defaults if still missing absolute fields.
      m['createdAt'] ??= now.subtract(const Duration(days: 2)).toIso8601String();
      m['updatedAt'] ??= now.subtract(const Duration(hours: 3)).toIso8601String();
      return m;
    }).toList(growable: false);
  }

  static Future<void> ensureShellData({required String userId}) async {
    await ensureFromFixtures();
  }
}
