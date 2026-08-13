import 'package:flutter_test/flutter_test.dart';
import 'package:replicaz/features/messaging/data/cmf_multi_room_socket.dart';

void main() {
  test('CmfMultiRoomStatus enum is stable for UI/debug', () {
    expect(CmfMultiRoomStatus.values.length, 5);
    expect(CmfMultiRoomStatus.connected.name, 'connected');
  });
}
