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
    final items = _read()..sort((a, b) => a.name.compareTo(b.name));
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
        await setActiveId(items.first.id);
      } else {
        await store.remove(StorageKeys.activeIdentityId);
      }
    }
  }

  Future<void> seedDefaultsIfEmpty() async {
    if (_read().isNotEmpty) return;
    final now = DateTime.now().toUtc();
    final defaults = [
      Identity(
        id: _uuid.v4(),
        name: 'Job',
        type: IdentityType.job,
        colorValue: AppColors.identityJob.toARGB32(),
        tagline: 'Work context',
        createdAt: now,
        updatedAt: now,
      ),
      Identity(
        id: _uuid.v4(),
        name: 'Freelance',
        type: IdentityType.freelance,
        colorValue: AppColors.identityFreelance.toARGB32(),
        tagline: 'Client work',
        createdAt: now,
        updatedAt: now,
      ),
      Identity(
        id: _uuid.v4(),
        name: 'Personal',
        type: IdentityType.personal,
        colorValue: AppColors.identityPersonal.toARGB32(),
        tagline: 'Life outside work',
        createdAt: now,
        updatedAt: now,
      ),
    ];
    await _write(defaults);
    await setActiveId(defaults.first.id);
  }
}
