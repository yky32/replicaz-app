import 'package:replicaz/core/constants/storage_keys.dart';
import 'package:replicaz/core/storage/local_store.dart';
import 'package:replicaz/features/contacts/domain/contact.dart';

class ContactService {
  ContactService({required this.store});

  final LocalStore store;

  List<Contact> _read() =>
      store.getJsonList(StorageKeys.contacts).map(Contact.fromJson).toList();

  Future<void> _write(List<Contact> items) => store.setJson(
        StorageKeys.contacts,
        items.map((e) => e.toJson()).toList(),
      );

  Future<List<Contact>> byIdentity(String identityId) async {
    return _read().where((e) => e.identityId == identityId).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<Contact?> getById(String id) async {
    try {
      return _read().firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Contact> save(Contact contact) async {
    final items = _read();
    final index = items.indexWhere((e) => e.id == contact.id);
    if (index < 0) {
      items.add(contact);
    } else {
      items[index] = contact;
    }
    await _write(items);
    return contact;
  }

  Future<void> delete(String id) async {
    final items = _read()..removeWhere((e) => e.id == id);
    await _write(items);
  }
}
