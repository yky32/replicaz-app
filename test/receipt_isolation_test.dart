import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:replicaz/core/constants/storage_keys.dart';
import 'package:replicaz/core/storage/local_store.dart';
import 'package:replicaz/features/receipts/data/receipt_service.dart';
import 'package:replicaz/features/receipts/domain/receipt.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('receipts isolate by identity', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalStore(prefs);
    final svc = ReceiptService(store: store);
    final now = DateTime.now().toUtc();
    await svc.save(Receipt(
      id: 'a',
      identityId: 'job',
      kind: ReceiptKind.pos,
      title: 'Job slip',
      createdAt: now,
      updatedAt: now,
    ));
    await svc.save(Receipt(
      id: 'b',
      identityId: 'personal',
      kind: ReceiptKind.handwritten,
      title: 'Personal slip',
      createdAt: now,
      updatedAt: now,
    ));
    final job = await svc.byIdentity('job');
    final personal = await svc.byIdentity('personal');
    expect(job.map((e) => e.id), ['a']);
    expect(personal.map((e) => e.id), ['b']);
    expect(store.getJsonList(StorageKeys.receipts).length, 2);
    expect(svc.lastKind(), ReceiptKind.handwritten);
  });

  test('delete removes image file', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalStore(prefs);
    final svc = ReceiptService(store: store);
    final tmp = File(
      '${Directory.systemTemp.path}/rcpt_test_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await tmp.writeAsBytes([1, 2, 3, 4]);
    expect(tmp.existsSync(), isTrue);
    final now = DateTime.now().toUtc();
    await svc.save(Receipt(
      id: 'img1',
      identityId: 'job',
      kind: ReceiptKind.handwritten,
      title: 'With photo',
      imagePath: tmp.path,
      createdAt: now,
      updatedAt: now,
    ));
    await svc.delete('img1');
    expect(await svc.getById('img1'), isNull);
    expect(tmp.existsSync(), isFalse);
  });
}
