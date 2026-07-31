import 'package:replicaz/core/constants/storage_keys.dart';
import 'package:replicaz/core/storage/local_store.dart';
import 'package:replicaz/features/follow_ups/domain/follow_up.dart';

class FollowUpService {
  FollowUpService({required this.store});

  final LocalStore store;

  List<FollowUp> _read() =>
      store.getJsonList(StorageKeys.followUps).map(FollowUp.fromJson).toList();

  Future<void> _write(List<FollowUp> items) => store.setJson(
        StorageKeys.followUps,
        items.map((e) => e.toJson()).toList(),
      );

  Future<List<FollowUp>> byIdentity(String identityId) async {
    return _read().where((e) => e.identityId == identityId).toList()
      ..sort((a, b) {
        if (a.status != b.status) {
          return a.status == FollowUpStatus.open ? -1 : 1;
        }
        final aDue = a.dueAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDue = b.dueAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aDue.compareTo(bDue);
      });
  }

  Future<FollowUp> save(FollowUp item) async {
    final items = _read();
    final index = items.indexWhere((e) => e.id == item.id);
    if (index < 0) {
      items.add(item);
    } else {
      items[index] = item;
    }
    await _write(items);
    return item;
  }

  Future<void> delete(String id) async {
    final items = _read()..removeWhere((e) => e.id == id);
    await _write(items);
  }
}
