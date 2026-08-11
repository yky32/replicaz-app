import 'package:replicaz/app/theme/app_colors.dart';
import 'package:replicaz/core/constants/storage_keys.dart';
import 'package:replicaz/core/storage/local_store.dart';
import 'package:replicaz/features/identities/domain/identity.dart';
import 'package:uuid/uuid.dart';

class IdentityService {
  IdentityService({required this.store});

  final LocalStore store;
  final _uuid = const Uuid();

  List<Identity> _read() =>
      store.getJsonList(StorageKeys.identities).map(Identity.fromJson).toList();

  Future<void> _write(List<Identity> items) => store.setJson(
        StorageKeys.identities,
        items.map((e) => e.toJson()).toList(),
      );

  Future<List<Identity>> getAll() async {
    final items = _read()
      ..sort((a, b) {
        // Personal first, then alpha — stable “home life” at top of lists.
        if (a.type == IdentityType.personal && b.type != IdentityType.personal) {
          return -1;
        }
        if (b.type == IdentityType.personal && a.type != IdentityType.personal) {
          return 1;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    return items;
  }

  Future<String?> getActiveId() async =>
      store.getString(StorageKeys.activeIdentityId);

  Future<void> setActiveId(String id) =>
      store.setString(StorageKeys.activeIdentityId, id);

  Future<Identity> create(Identity identity) async {
    final items = _read()..add(identity);
    await _write(items);
    if (await getActiveId() == null) {
      await setActiveId(identity.id);
    }
    return identity;
  }

  Future<Identity> update(Identity identity) async {
    final items = _read();
    final index = items.indexWhere((e) => e.id == identity.id);
    if (index < 0) throw StateError('Identity not found');
    items[index] = identity;
    await _write(items);
    return identity;
  }

  Future<void> delete(String id) async {
    final items = _read()..removeWhere((e) => e.id == id);
    await _write(items);
    final active = await getActiveId();
    if (active == id) {
      if (items.isNotEmpty) {
        final personal = items.where((e) => e.type == IdentityType.personal);
        await setActiveId(
          personal.isNotEmpty ? personal.first.id : items.first.id,
        );
      } else {
        await store.remove(StorageKeys.activeIdentityId);
      }
    }
  }

  /// Ensures at least a Personal identity exists; sets active if missing.
  ///
  /// Called on every identities load so first login never needs manual setup.
  Future<void> ensureOnboarded() async {
    final existing = _read();
    if (existing.isEmpty) {
      await _seedStarterIdentities();
      return;
    }

    final active = await getActiveId();
    final activeValid =
        active != null && existing.any((e) => e.id == active);
    if (!activeValid) {
      final personal = existing.where((e) => e.type == IdentityType.personal);
      await setActiveId(
        personal.isNotEmpty ? personal.first.id : existing.first.id,
      );
    }
  }

  Future<void> _seedStarterIdentities() async {
    final now = DateTime.now().toUtc();
    final personal = Identity(
      id: _uuid.v4(),
      name: 'Personal',
      type: IdentityType.personal,
      colorValue: AppColors.identityPersonal.toARGB32(),
      tagline: 'Life outside work',
      createdAt: now,
      updatedAt: now,
    );
    final job = Identity(
      id: _uuid.v4(),
      name: 'Job',
      type: IdentityType.job,
      colorValue: AppColors.identityJob.toARGB32(),
      tagline: 'Work context',
      createdAt: now,
      updatedAt: now,
    );
    final freelance = Identity(
      id: _uuid.v4(),
      name: 'Freelance',
      type: IdentityType.freelance,
      colorValue: AppColors.identityFreelance.toARGB32(),
      tagline: 'Client work',
      createdAt: now,
      updatedAt: now,
    );
    // Personal first in storage intent; active is always Personal for new users.
    await _write([personal, job, freelance]);
    await setActiveId(personal.id);
  }

  /// @deprecated Use [ensureOnboarded].
  Future<void> seedDefaultsIfEmpty() => ensureOnboarded();
}
