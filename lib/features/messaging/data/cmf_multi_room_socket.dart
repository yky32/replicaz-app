import 'dart:async';
import 'dart:convert';

import 'package:replicaz/core/config/app_config.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// One CMF connection that can [join] many rooms (inbox live previews).
///
/// CMF allows multiple `join-chat-room` on the same socket. Room set is
/// reconciled via [syncRooms].
class CmfMultiRoomSocket {
  CmfMultiRoomSocket({
    required this.onRoomMessage,
    this.onStatus,
    this.maxAttempts = 8,
  });

  final void Function({
    required String roomId,
    required String body,
    required String from,
    required DateTime at,
    String? messageId,
  }) onRoomMessage;
  final void Function(CmfMultiRoomStatus status)? onStatus;
  final int maxAttempts;

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _reconnect;
  int _attempts = 0;
  bool _manualClose = false;
  final Set<String> _rooms = {};
  CmfMultiRoomStatus _status = CmfMultiRoomStatus.disconnected;

  CmfMultiRoomStatus get status => _status;
  Set<String> get joinedRooms => Set.unmodifiable(_rooms);

  Future<void> syncRooms(Iterable<String> roomIds) async {
    final next = roomIds.where((id) => id.isNotEmpty).toSet();
    final same = next.length == _rooms.length && next.containsAll(_rooms);
    if (same && _channel != null && _status == CmfMultiRoomStatus.connected) {
      return;
    }
    _rooms
      ..clear()
      ..addAll(next);
    if (_rooms.isEmpty) {
      await disconnect(manual: true);
      return;
    }
    if (_channel == null || _status == CmfMultiRoomStatus.failed) {
      await connect();
    } else {
      _joinAll();
    }
  }

  Future<void> connect() async {
    if (_rooms.isEmpty) return;
    await disconnect(manual: false);
    _manualClose = false;
    _setStatus(
      _attempts == 0
          ? CmfMultiRoomStatus.connecting
          : CmfMultiRoomStatus.reconnecting,
    );

    try {
      final uri = Uri.parse(AppConfig.cmfWsUrl);
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      _sub = channel.stream.listen(
        (raw) {
          _attempts = 0;
          if (_status != CmfMultiRoomStatus.connected) {
            _setStatus(CmfMultiRoomStatus.connected);
          }
          _handleFrame(raw);
        },
        onDone: _scheduleReconnect,
        onError: (_) => _scheduleReconnect(),
        cancelOnError: true,
      );
      _joinAll();
      _setStatus(CmfMultiRoomStatus.connected);
      _attempts = 0;
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _joinAll() {
    final channel = _channel;
    if (channel == null) return;
    for (final roomId in _rooms) {
      channel.sink.add(
        jsonEncode({
          'type': 'join-chat-room',
          'chatRoomId': roomId,
        }),
      );
    }
  }

  void _handleFrame(dynamic raw) {
    try {
      final map = jsonDecode(raw as String) as Map<String, dynamic>;
      if (map['type'] != 'chat-room-message-received') return;
      final room = (map['chatRoomId'] ?? map['to'] ?? '').toString();
      if (room.isEmpty || !_rooms.contains(room)) return;
      final content = (map['content'] ?? map['message'] ?? '').toString();
      if (content.isEmpty) return;
      final ts = map['sentTimestamp'] ?? map['timestamp'];
      final created = ts is num
          ? DateTime.fromMillisecondsSinceEpoch(ts.toInt()).toUtc()
          : DateTime.now().toUtc();
      final id = (map['messageId'] ?? map['id'] ?? '').toString();
      onRoomMessage(
        roomId: room,
        body: content,
        from: (map['from'] ?? '').toString(),
        at: created,
        messageId: id.isEmpty ? null : id,
      );
    } catch (_) {}
  }

  Future<void> reconnect() async {
    if (_manualClose || _rooms.isEmpty) return;
    _attempts = 0;
    await connect();
  }

  void _scheduleReconnect() {
    if (_manualClose || _rooms.isEmpty) return;
    if (_attempts >= maxAttempts) {
      _setStatus(CmfMultiRoomStatus.failed);
      return;
    }
    _attempts += 1;
    _setStatus(CmfMultiRoomStatus.reconnecting);
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
      _setStatus(CmfMultiRoomStatus.disconnected);
    }
  }

  void _setStatus(CmfMultiRoomStatus next) {
    if (_status == next) return;
    _status = next;
    onStatus?.call(next);
  }
}

enum CmfMultiRoomStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed,
}
