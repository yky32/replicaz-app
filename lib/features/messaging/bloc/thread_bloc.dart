import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:replicaz/core/bootstrap/app_bootstrap.dart';
import 'package:replicaz/core/config/app_config.dart';
import 'package:replicaz/features/messaging/data/cmf_socket.dart';
import 'package:replicaz/features/messaging/data/messaging_service.dart';
import 'package:replicaz/features/messaging/domain/chat_message.dart';

part 'thread_event.dart';
part 'thread_state.dart';

class ThreadBloc extends Bloc<ThreadEvent, ThreadState> {
  ThreadBloc({
    required this.conversationId,
    MessagingService? messagingService,
  })  : _service = messagingService ?? AppBootstrap.messagingService,
        super(const ThreadState()) {
    on<ThreadLoadRequested>(_onLoad);
    on<ThreadSendRequested>(_onSend);
    on<ThreadRemoteMessageReceived>(_onRemote);
  }

  final String conversationId;
  final MessagingService _service;
  CmfSocket? _socket;
  String _identityId = '';

  Future<void> _onLoad(
    ThreadLoadRequested event,
    Emitter<ThreadState> emit,
  ) async {
    _identityId = event.identityId;
    emit(state.copyWith(status: ThreadStatus.loading));
    final messages = await _service.messagesFor(
      conversationId,
      identityId: _identityId,
    );
    emit(state.copyWith(status: ThreadStatus.loaded, messages: messages));
    await _connectSocket();
  }

  Future<void> _connectSocket() async {
    if (!AppConfig.useRemoteBackend) return;
    await _socket?.disconnect();
    _socket = CmfSocket(
      roomId: conversationId,
      onMessage: (map) {
        if (map['type'] != 'chat-room-message-received') return;
        if (map['chatRoomId'] != conversationId) return;
        final content =
            (map['content'] ?? map['message'] ?? '').toString();
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
              clientMessageId: id,
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
    );
    await _socket!.connect();
  }

  Future<void> _onSend(
    ThreadSendRequested event,
    Emitter<ThreadState> emit,
  ) async {
    emit(state.copyWith(sending: true));
    final optimistic = await _service.sendMessage(
      conversationId: conversationId,
      senderUserId: event.senderUserId,
      senderIdentityId: event.senderIdentityId,
      body: event.body,
    );
    if (AppConfig.useRemoteBackend) {
      // Keep optimistic bubble; WS / reload will dedupe by id/body.
      final merged = [...state.messages];
      if (!merged.any((m) => m.body == optimistic.body &&
          m.senderUserId == optimistic.senderUserId &&
          (m.createdAt.difference(optimistic.createdAt).inSeconds).abs() < 3)) {
        merged.add(optimistic);
      }
      emit(state.copyWith(messages: merged, sending: false));
      return;
    }
    final messages = await _service.messagesFor(
      conversationId,
      identityId: event.senderIdentityId,
    );
    emit(
      state.copyWith(
        status: ThreadStatus.loaded,
        messages: messages,
        sending: false,
      ),
    );
  }

  Future<void> _onRemote(
    ThreadRemoteMessageReceived event,
    Emitter<ThreadState> emit,
  ) async {
    final exists = state.messages.any((m) => m.id == event.message.id);
    if (exists) return;
    // Replace matching optimistic local send.
    final withoutOptimistic = state.messages.where((m) {
      final sameBody = m.body == event.message.body;
      final sameSender = m.senderUserId == event.message.senderUserId ||
          m.senderUserId.isEmpty;
      final recent =
          m.createdAt.difference(event.message.createdAt).inSeconds.abs() < 8;
      return !(sameBody && sameSender && recent && m.id != event.message.id);
    }).toList();
    emit(
      state.copyWith(
        status: ThreadStatus.loaded,
        messages: [...withoutOptimistic, event.message],
      ),
    );
  }

  @override
  Future<void> close() async {
    await _socket?.disconnect();
    return super.close();
  }
}
