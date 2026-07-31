import 'dart:async';
import 'dart:convert';

import 'package:replicaz/core/config/app_config.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

typedef CmfMessageHandler = void Function(Map<String, dynamic> message);

/// tgt-rn style: join room on open; receive `chat-room-message-received`.
class CmfSocket {
  CmfSocket({required this.roomId, required this.onMessage});

  final String roomId;
  final CmfMessageHandler onMessage;

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _reconnect;
  int _attempts = 0;
  bool _manualClose = false;

  Future<void> connect() async {
    await disconnect(manual: false);
    _manualClose = false;
    final uri = Uri.parse(AppConfig.cmfWsUrl);
    final channel = WebSocketChannel.connect(uri);
    _channel = channel;
    _sub = channel.stream.listen(
      (raw) {
        try {
          final map = jsonDecode(raw as String) as Map<String, dynamic>;
          onMessage(map);
        } catch (_) {}
      },
      onDone: _scheduleReconnect,
      onError: (_) => _scheduleReconnect(),
      cancelOnError: true,
    );
    channel.sink.add(
      jsonEncode({
        'type': 'join-chat-room',
        'chatRoomId': roomId,
      }),
    );
    _attempts = 0;
  }

  void _scheduleReconnect() {
    if (_manualClose || _attempts >= 5) return;
    _attempts += 1;
    _reconnect?.cancel();
    _reconnect = Timer(const Duration(seconds: 3), connect);
  }

  Future<void> disconnect({bool manual = true}) async {
    _manualClose = manual;
    _reconnect?.cancel();
    await _sub?.cancel();
    _sub = null;
    await _channel?.sink.close();
    _channel = null;
  }
}
