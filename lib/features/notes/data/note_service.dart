import 'package:replicaz/core/constants/storage_keys.dart';
import 'package:replicaz/core/storage/local_store.dart';
import 'package:replicaz/features/notes/domain/note.dart';

class NoteService {
  NoteService({required this.store});

  final LocalStore store;

  List<Note> _read() =>
      store.getJsonList(StorageKeys.notes).map(Note.fromJson).toList();

  Future<void> _write(List<Note> items) =>
      store.setJson(StorageKeys.notes, items.map((e) => e.toJson()).toList());

  Future<List<Note>> byIdentity(String identityId) async {
    return _read().where((e) => e.identityId == identityId).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<Note?> getById(String id) async {
    try {
      return _read().firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Note> save(Note note) async {
    final items = _read();
    final index = items.indexWhere((e) => e.id == note.id);
    if (index < 0) {
      items.add(note);
    } else {
      items[index] = note;
    }
    await _write(items);
    return note;
  }

  Future<void> delete(String id) async {
    final items = _read()..removeWhere((e) => e.id == id);
    await _write(items);
  }
}
