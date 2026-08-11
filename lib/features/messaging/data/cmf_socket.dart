import 'dart:async';
import 'dart:convert';

import 'package:replicaz/core/config/app_config.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

typedef CmfMessageHandler = void Function(Map<String, dynamic> message);
typedef CmfStatusHandler = void Function(CmfConnectionStatus status);

enum CmfConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed,
}

/// tgt-rn style: join room on open; receive `chat-room-message-received`.
///
/// Reconnects with exponential backoff after drop; [disconnect] stops retries.
class CmfSocket {
  CmfSocket({
    required this.roomId,
    required this.onMessage,
    this.onStatus,
    this.maxAttempts = 8,
  });

  final String roomId;
  final CmfMessageHandler onMessage;
  final CmfStatusHandler? onStatus;
  final int maxAttempts;

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _reconnect;
  int _attempts = 0;
  bool _manualClose = false;
  CmfConnectionStatus _status = CmfConnectionStatus.disconnected;

  CmfConnectionStatus get status => _status;

  Future<void> connect() async {
    await disconnect(manual: false);
    _manualClose = false;
    _setStatus(
      _attempts == 0
          ? CmfConnectionStatus.connecting
          : CmfConnectionStatus.reconnecting,
    );

    try {
      final uri = Uri.parse(AppConfig.cmfWsUrl);
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      _sub = channel.stream.listen(
        (raw) {
          _attempts = 0;
          if (_status != CmfConnectionStatus.connected) {
            _setStatus(CmfConnectionStatus.connected);
          }
          try {
            final map = jsonDecode(raw as String) as Map<String, dynamic>;
            onMessage(map);
          } catch (_) {}
        },
        onDone: _scheduleReconnect,
        onError: (_) => _scheduleReconnect(),
        cancelOnError: true,
      );

      // join after stream is listening
      channel.sink.add(
        jsonEncode({
          'type': 'join-chat-room',
          'chatRoomId': roomId,
        }),
      );
      // Assume connected once join is sent; first frame confirms.
      _setStatus(CmfConnectionStatus.connected);
      _attempts = 0;
    } catch (_) {
      _scheduleReconnect();
    }
  }

  /// Force a reconnect cycle (e.g. app resumed from background).
  Future<void> reconnect() async {
    if (_manualClose) return;
    _attempts = 0;
    await connect();
  }

  void _scheduleReconnect() {
    if (_manualClose) return;
    if (_attempts >= maxAttempts) {
      _setStatus(CmfConnectionStatus.failed);
      return;
    }
    _attempts += 1;
    _setStatus(CmfConnectionStatus.reconnecting);
    _reconnect?.cancel();
    final delay = Duration(seconds: (1 << (_attempts - 1).clamp(0, 4)));
    _reconnect = Timer(delay, () {
      if (!_manualClose) connect();
    });
  }

  Future<void> disconnect({bool manual = true}) async {
    _manualClose = manual;
    _reconnect?.cancel();
    _reconnect = null;
    await _sub?.cancel();
    _sub = null;
    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    if (manual) {
      _attempts = 0;
      _setStatus(CmfConnectionStatus.disconnected);
    }
  }

  void _setStatus(CmfConnectionStatus next) {
    if (_status == next) return;
    _status = next;
    onStatus?.call(next);
  }
}
