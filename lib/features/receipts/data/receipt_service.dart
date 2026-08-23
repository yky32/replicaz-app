import 'dart:io';

import 'package:replicaz/core/constants/storage_keys.dart';
import 'package:replicaz/core/storage/local_store.dart';
import 'package:replicaz/features/receipts/domain/receipt.dart';

class ReceiptService {
  ReceiptService({required this.store});

  final LocalStore store;

  List<Receipt> _read() =>
      store.getJsonList(StorageKeys.receipts).map(Receipt.fromJson).toList();

  Future<void> _write(List<Receipt> items) => store.setJson(
        StorageKeys.receipts,
        items.map((e) => e.toJson()).toList(),
      );

  Future<List<Receipt>> byIdentity(String identityId) async {
    return _read().where((e) => e.identityId == identityId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<Receipt?> getById(String id) async {
    try {
      return _read().firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Receipt> save(Receipt receipt) async {
    final items = _read();
    final index = items.indexWhere((e) => e.id == receipt.id);
    if (index < 0) {
      items.add(receipt);
    } else {
      items[index] = receipt;
    }
    await _write(items);
    await rememberKind(receipt.kind);
    return receipt;
  }

  Future<void> delete(String id) async {
    final items = _read();
    Receipt? doomed;
    for (final e in items) {
      if (e.id == id) {
        doomed = e;
        break;
      }
    }
    items.removeWhere((e) => e.id == id);
    await _write(items);
    final path = doomed?.imagePath ?? '';
    if (path.isNotEmpty) {
      try {
        final f = File(path);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
  }

  ReceiptKind? lastKind() {
    final raw = store.getString(StorageKeys.lastReceiptKind);
    if (raw == null || raw.isEmpty) return null;
    return ReceiptKind.fromStorage(raw);
  }

  Future<void> rememberKind(ReceiptKind kind) =>
      store.setString(StorageKeys.lastReceiptKind, kind.name);
}
