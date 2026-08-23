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
  });
}
