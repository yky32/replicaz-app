import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:replicaz/core/bootstrap/app_bootstrap.dart';
import 'package:replicaz/core/config/app_config.dart';
import 'package:replicaz/features/messaging/data/cmf_socket.dart';
import 'package:replicaz/features/messaging/data/messaging_service.dart';
import 'package:replicaz/features/messaging/domain/chat_message.dart';
import 'package:uuid/uuid.dart';

part 'thread_event.dart';
part 'thread_state.dart';

class ThreadBloc extends Bloc<ThreadEvent, ThreadState> {
  ThreadBloc({
    required this.conversationId,
    MessagingService? messagingService,
    bool? enableRealtime,
  })  : _service = messagingService ?? AppBootstrap.messagingService,
        _enableRealtime = enableRealtime ?? AppConfig.useRemoteBackend,
        super(const ThreadState()) {
    on<ThreadLoadRequested>(_onLoad);
    on<ThreadSendRequested>(_onSend);
    on<ThreadRemoteMessageReceived>(_onRemote);
    on<ThreadConnectionStatusChanged>(_onConnection);
    on<ThreadReconnectRequested>(_onReconnect);
    on<ThreadRetrySendRequested>(_onRetrySend);
    on<ThreadTypingLocalChanged>(_onTypingLocal);
    on<ThreadRemoteTypingChanged>(_onTypingRemote);
    on<ThreadActiveIdentityChanged>(_onActiveIdentity);
  }

  final String conversationId;
  final MessagingService _service;
  final bool _enableRealtime;
  final _uuid = const Uuid();
  CmfSocket? _socket;
  String _identityId = '';
  Timer? _typingStopTimer;
  Timer? _remoteTypingClear;
  bool _localTyping = false;

  Future<void> _onLoad(
    ThreadLoadRequested event,
    Emitter<ThreadState> emit,
  ) async {
    _identityId = event.identityId;
    final bound = _service.identityIdForRoom(conversationId) ?? _identityId;
    emit(
      state.copyWith(
        status: ThreadStatus.loading,
        boundIdentityId: bound,
        activeIdentityId: _identityId,
        canSend: bound.isEmpty || bound == _identityId,
        clearError: true,
        clearSendError: true,
      ),
    );
    try {
      final messages = await _service.messagesFor(
        conversationId,
        identityId: _identityId,
      );
      await _service.markRoomRead(conversationId);
      emit(
        state.copyWith(
          status: ThreadStatus.loaded,
          messages: messages,
          clearError: true,
        ),
      );
      await _connectSocket();
    } catch (e) {
      emit(
        state.copyWith(
          status: ThreadStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _connectSocket() async {
    if (!_enableRealtime) {
      add(const ThreadConnectionStatusChanged(ThreadConnectionStatus.idle));
      return;
    }
    await _socket?.disconnect();
    _socket = CmfSocket(
      roomId: conversationId,
      onMessage: (map) {
        if (isClosed) return;
        final type = (map['type'] ?? '').toString();
        if (type == 'chat-room-typing' || type == 'chat-room-typing-stopped') {
          final room = (map['chatRoomId'] ?? '').toString();
          if (room.isNotEmpty && room != conversationId) return;
          final peer = (map['participantId'] ?? map['from'] ?? '').toString();
          add(
            ThreadRemoteTypingChanged(
              peerId: peer,
              isTyping: type == 'chat-room-typing',
            ),
          );
          return;
        }
        if (type != 'chat-room-message-received') return;
        final room = (map['chatRoomId'] ?? map['to'] ?? '').toString();
        if (room.isNotEmpty && room != conversationId) return;
        final content = (map['content'] ?? map['message'] ?? '').toString();
        if (content.isEmpty) return;
        final id = (map['messageId'] ?? map['id'] ?? '').toString();
        final ts = map['sentTimestamp'] ?? map['timestamp'];
        final created = ts is num
            ? DateTime.fromMillisecondsSinceEpoch(ts.toInt()).toUtc()
            : DateTime.now().toUtc();
        add(
          ThreadRemoteMessageReceived(
            ChatMessage(
              id: id.isEmpty ? created.microsecondsSinceEpoch.toString() : id,
              conversationId: conversationId,
              clientMessageId: id.isEmpty
                  ? created.microsecondsSinceEpoch.toString()
                  : id,
              senderUserId: (map['from'] ?? '').toString(),
              senderIdentityId: _identityId,
              body: content,
              sequence: '${created.millisecondsSinceEpoch}',
              deliveryStatus: MessageDeliveryStatus.delivered,
              createdAt: created,
              serverReceivedAt: created,
            ),
          ),
        );
      },
      onStatus: (status) {
        if (isClosed) return;
        add(ThreadConnectionStatusChanged(_mapCmfStatus(status)));
      },
    );
    await _socket!.connect();
  }

  ThreadConnectionStatus _mapCmfStatus(CmfConnectionStatus s) {
    return switch (s) {
      CmfConnectionStatus.disconnected => ThreadConnectionStatus.idle,
      CmfConnectionStatus.connecting => ThreadConnectionStatus.connecting,
      CmfConnectionStatus.connected => ThreadConnectionStatus.connected,
      CmfConnectionStatus.reconnecting => ThreadConnectionStatus.reconnecting,
      CmfConnectionStatus.failed => ThreadConnectionStatus.failed,
    };
  }

  Future<void> _onConnection(
    ThreadConnectionStatusChanged event,
    Emitter<ThreadState> emit,
  ) async {
    emit(state.copyWith(connection: event.connection));
  }

  Future<void> _onReconnect(
    ThreadReconnectRequested event,
    Emitter<ThreadState> emit,
  ) async {
    if (!_enableRealtime) return;
    if (_socket == null) {
      await _connectSocket();
      return;
    }
    emit(state.copyWith(connection: ThreadConnectionStatus.connecting));
    await _socket!.reconnect();
  }

  Future<void> _onActiveIdentity(
    ThreadActiveIdentityChanged event,
    Emitter<ThreadState> emit,
  ) async {
    final active = event.activeIdentityId;
    final bound = state.boundIdentityId.isNotEmpty
        ? state.boundIdentityId
        : (_service.identityIdForRoom(conversationId) ?? '');
    final canSend = bound.isEmpty || bound == active;
    emit(
      state.copyWith(
        activeIdentityId: active,
        boundIdentityId: bound,
        canSend: canSend,
        sendError: canSend
            ? null
            : 'Switch back to the life that owns this chat to send.',
        clearSendError: canSend,
      ),
    );
  }

  Future<void> _onTypingLocal(
    ThreadTypingLocalChanged event,
    Emitter<ThreadState> emit,
  ) async {
    if (!_enableRealtime || !state.canSend) return;
    if (event.isTyping) {
      if (!_localTyping) {
        _localTyping = true;
        _socket?.sendTypingStart();
      }
      _typingStopTimer?.cancel();
      _typingStopTimer = Timer(const Duration(milliseconds: 1600), () {
        if (!isClosed) add(const ThreadTypingLocalChanged(false));
      });
    } else if (_localTyping) {
      _localTyping = false;
      _typingStopTimer?.cancel();
      _socket?.sendTypingStop();
    }
  }

  Future<void> _onTypingRemote(
    ThreadRemoteTypingChanged event,
    Emitter<ThreadState> emit,
  ) async {
    emit(state.copyWith(peerTyping: event.isTyping));
    _remoteTypingClear?.cancel();
    if (event.isTyping) {
      _remoteTypingClear = Timer(const Duration(seconds: 3), () {
        if (!isClosed) {
          add(const ThreadRemoteTypingChanged(peerId: '', isTyping: false));
        }
      });
    }
  }

  Future<void> _onSend(
    ThreadSendRequested event,
    Emitter<ThreadState> emit,
  ) async {
    final body = event.body.trim();
    if (body.isEmpty || state.sending) return;

    if (!state.canSend || state.identityMismatch) {
      emit(
        state.copyWith(
          sendError: 'Switch back to the life that owns this chat to send.',
        ),
      );
      return;
    }

    // Stop typing indicator on send.
    if (_localTyping) {
      _localTyping = false;
      _socket?.sendTypingStop();
    }

    final clientId = _uuid.v4();
    final now = DateTime.now().toUtc();
    final optimistic = ChatMessage(
      id: clientId,
      conversationId: conversationId,
      clientMessageId: clientId,
      senderUserId: event.senderUserId,
      senderIdentityId: event.senderIdentityId,
      body: body,
      sequence: '${now.millisecondsSinceEpoch}',
      deliveryStatus: MessageDeliveryStatus.pending,
      createdAt: now,
    );

    emit(
      state.copyWith(
        messages: [...state.messages, optimistic],
        sending: true,
        clearSendError: true,
        status: ThreadStatus.loaded,
        peerTyping: false,
      ),
    );

    try {
      final sent = await _service.sendMessage(
        conversationId: conversationId,
        senderUserId: event.senderUserId,
        senderIdentityId: event.senderIdentityId,
        body: body,
        clientMessageId: clientId,
      );
      final messages = state.messages.map((m) {
        if (m.clientMessageId != clientId) return m;
        return sent.copyWith(
          deliveryStatus: MessageDeliveryStatus.sent,
        );
      }).toList();
      if (!messages.any((m) => m.clientMessageId == clientId || m.id == sent.id)) {
        messages.add(sent);
      }
      emit(state.copyWith(messages: messages, sending: false));
    } catch (e) {
      final messages = state.messages.map((m) {
        if (m.clientMessageId != clientId) return m;
        return m.copyWith(deliveryStatus: MessageDeliveryStatus.failed);
      }).toList();
      emit(
        state.copyWith(
          messages: messages,
          sending: false,
          sendError: e.toString(),
        ),
      );
    }
  }

  Future<void> _onRetrySend(
    ThreadRetrySendRequested event,
    Emitter<ThreadState> emit,
  ) async {
    ChatMessage? failed;
    for (final m in state.messages) {
      if (m.clientMessageId == event.clientMessageId &&
          m.deliveryStatus == MessageDeliveryStatus.failed) {
        failed = m;
        break;
      }
    }
    if (failed == null || state.sending) return;
    if (!state.canSend) {
      emit(
        state.copyWith(
          sendError: 'Switch back to the life that owns this chat to send.',
        ),
      );
      return;
    }

    final clientId = failed.clientMessageId;
    final messages = state.messages.map((m) {
      if (m.clientMessageId != clientId) return m;
      return m.copyWith(deliveryStatus: MessageDeliveryStatus.pending);
    }).toList();
    emit(
      state.copyWith(
        messages: messages,
        sending: true,
        clearSendError: true,
      ),
    );

    try {
      final sent = await _service.sendMessage(
        conversationId: conversationId,
        senderUserId: failed.senderUserId,
        senderIdentityId: failed.senderIdentityId,
        body: failed.body,
        clientMessageId: clientId,
      );
      final next = state.messages.map((m) {
        if (m.clientMessageId != clientId) return m;
        return sent.copyWith(deliveryStatus: MessageDeliveryStatus.sent);
      }).toList();
      emit(state.copyWith(messages: next, sending: false));
    } catch (e) {
      final next = state.messages.map((m) {
        if (m.clientMessageId != clientId) return m;
        return m.copyWith(deliveryStatus: MessageDeliveryStatus.failed);
      }).toList();
      emit(
        state.copyWith(
          messages: next,
          sending: false,
          sendError: e.toString(),
        ),
      );
    }
  }

  Future<void> _onRemote(
    ThreadRemoteMessageReceived event,
    Emitter<ThreadState> emit,
  ) async {
    final incoming = event.message;
    await _service.markRoomRead(conversationId, at: incoming.createdAt);

    final existsById = state.messages.any((m) => m.id == incoming.id);
    if (existsById) {
      final upgraded = state.messages.map((m) {
        if (m.id == incoming.id ||
            (m.body == incoming.body &&
                _sameSender(m, incoming) &&
                m.deliveryStatus != MessageDeliveryStatus.delivered &&
                m.createdAt.difference(incoming.createdAt).inSeconds.abs() <
                    12)) {
          return m.copyWith(
            id: incoming.id,
            deliveryStatus: MessageDeliveryStatus.delivered,
            serverReceivedAt: incoming.serverReceivedAt,
          );
        }
        return m;
      }).toList();
      emit(
        state.copyWith(
          messages: upgraded,
          lastInboundAt: DateTime.now().toUtc(),
          peerTyping: false,
        ),
      );
      return;
    }

    final withoutOptimistic = state.messages.where((m) {
      final sameBody = m.body == incoming.body;
      final sameSender = _sameSender(m, incoming);
      final recent =
          m.createdAt.difference(incoming.createdAt).inSeconds.abs() < 12;
      final pendingOrSent = m.deliveryStatus == MessageDeliveryStatus.pending ||
          m.deliveryStatus == MessageDeliveryStatus.sent;
      return !(sameBody && sameSender && recent && pendingOrSent);
    }).toList();

    emit(
      state.copyWith(
        status: ThreadStatus.loaded,
        messages: [...withoutOptimistic, incoming],
        lastInboundAt: DateTime.now().toUtc(),
        peerTyping: false,
      ),
    );
  }

  bool _sameSender(ChatMessage a, ChatMessage b) {
    if (a.senderUserId.isEmpty || b.senderUserId.isEmpty) return true;
    return a.senderUserId == b.senderUserId;
  }

  @override
  Future<void> close() async {
    _typingStopTimer?.cancel();
    _remoteTypingClear?.cancel();
    if (_localTyping) {
      _socket?.sendTypingStop();
    }
    await _socket?.disconnect(manual: true);
    _socket = null;
    return super.close();
  }
}
