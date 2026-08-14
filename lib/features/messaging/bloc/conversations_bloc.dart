import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:replicaz/core/bootstrap/app_bootstrap.dart';
import 'package:replicaz/core/config/app_config.dart';
import 'package:replicaz/features/identities/bloc/identities_bloc.dart';
import 'package:replicaz/features/messaging/data/cmf_multi_room_socket.dart';
import 'package:replicaz/features/messaging/data/messaging_service.dart';
import 'package:replicaz/features/messaging/domain/conversation.dart';

part 'conversations_event.dart';
part 'conversations_state.dart';

class ConversationsBloc extends Bloc<ConversationsEvent, ConversationsState> {
  ConversationsBloc({
    required IdentitiesBloc identitiesBloc,
    MessagingService? messagingService,
    bool? enableInboxRealtime,
  })  : _identitiesBloc = identitiesBloc,
        _service = messagingService ?? AppBootstrap.messagingService,
        _enableInboxRealtime =
            enableInboxRealtime ?? AppConfig.effectiveRemoteBackend,
        super(const ConversationsState()) {
    on<ConversationsLoadRequested>(_onLoad);
    on<ConversationsRefreshRequested>(_onRefresh);
    on<ConversationsCreateRequested>(_onCreate);
    on<ConversationsPreviewUpdated>(_onPreview);
    on<ConversationsMarkReadRequested>(_onMarkRead);
    on<ConversationsLeaveRequested>(_onLeave);
    on<ConversationsRealtimeTick>(_onRealtimeTick);
    on<ConversationsInboxResumeRequested>(_onInboxResume);
    on<ConversationsLastCreatedConsumed>(_onLastCreatedConsumed);

    _identitySub = _identitiesBloc.stream
        .map((s) => s.activeIdentityId)
        .distinct()
        .listen((id) {
      if (id != null) add(ConversationsLoadRequested(identityId: id));
    });

    final initialId = _identitiesBloc.state.activeIdentityId;
    if (initialId != null) {
      add(ConversationsLoadRequested(identityId: initialId));
    }

    // Soft REST backup while inbox is alive (missed WS / new peer rooms).
    if (_enableInboxRealtime) {
      _pollTimer = Timer.periodic(const Duration(seconds: 12), (_) {
        if (!isClosed) add(const ConversationsRealtimeTick());
      });
    }
  }

  final IdentitiesBloc _identitiesBloc;
  final MessagingService _service;
  final bool _enableInboxRealtime;
  StreamSubscription<String?>? _identitySub;
  Timer? _pollTimer;
  CmfMultiRoomSocket? _inboxSocket;

  Future<void> _onLoad(
    ConversationsLoadRequested event,
    Emitter<ConversationsState> emit,
  ) async {
    final switching =
        state.identityId != null && state.identityId != event.identityId;
    emit(
      state.copyWith(
        status: ConversationsStatus.loading,
        identityId: event.identityId,
        conversations: switching ? const [] : state.conversations,
        clearError: true,
      ),
    );
    try {
      final conversations =
          await _service.conversationsForIdentity(event.identityId);
      if (state.identityId != null && state.identityId != event.identityId) {
        return;
      }
      emit(
        state.copyWith(
          status: ConversationsStatus.loaded,
          conversations: conversations,
          identityId: event.identityId,
          clearError: true,
        ),
      );
      await _syncInboxSocket(conversations.map((c) => c.id));
    } catch (e) {
      if (state.identityId != null && state.identityId != event.identityId) {
        return;
      }
      emit(
        state.copyWith(
          status: ConversationsStatus.failure,
          errorMessage: e.toString(),
          identityId: event.identityId,
          conversations: switching ? const [] : state.conversations,
        ),
      );
    }
  }

  Future<void> _onRefresh(
    ConversationsRefreshRequested event,
    Emitter<ConversationsState> emit,
  ) async {
    final identityId =
        state.identityId ?? _identitiesBloc.state.activeIdentityId;
    if (identityId == null) return;
    try {
      final conversations =
          await _service.conversationsForIdentity(identityId);
      if (state.identityId != null && state.identityId != identityId) return;
      emit(
        state.copyWith(
          status: ConversationsStatus.loaded,
          conversations: conversations,
          identityId: identityId,
          clearError: true,
        ),
      );
      await _syncInboxSocket(conversations.map((c) => c.id));
    } catch (e) {
      if (state.conversations.isEmpty) {
        emit(
          state.copyWith(
            status: ConversationsStatus.failure,
            errorMessage: e.toString(),
          ),
        );
      }
    }
  }

  Future<void> _onCreate(
    ConversationsCreateRequested event,
    Emitter<ConversationsState> emit,
  ) async {
    final identityId =
        state.identityId ?? _identitiesBloc.state.activeIdentityId;
    if (identityId == null) return;
    emit(state.copyWith(creating: true, clearError: true));
    try {
      final created = await _service.createDirectConversation(
        ownerIdentityId: identityId,
        createdByUserId: event.userId,
        title: event.title ?? 'New chat',
        participantUserId: event.participantUserId,
      );
      final conversations =
          await _service.conversationsForIdentity(identityId);
      emit(
        state.copyWith(
          status: ConversationsStatus.loaded,
          conversations: conversations,
          creating: false,
          lastCreatedConversationId: created.id,
          clearError: true,
        ),
      );
      await _syncInboxSocket(conversations.map((c) => c.id));
    } catch (e) {
      emit(
        state.copyWith(
          creating: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onPreview(
    ConversationsPreviewUpdated event,
    Emitter<ConversationsState> emit,
  ) async {
    final list = [...state.conversations];
    final index = list.indexWhere((c) => c.id == event.conversationId);
    if (index < 0) {
      add(const ConversationsRefreshRequested());
      return;
    }
    final current = list[index];
    final unread = event.fromSelf
        ? 0
        : (current.unreadCount <= 0 ? 1 : current.unreadCount + 1);
    if (event.fromSelf) {
      await _service.markRoomRead(event.conversationId, at: event.at);
    }
    final updated = current.copyWith(
      lastMessageAt: event.at,
      lastMessagePreview: event.preview,
      updatedAt: event.at,
      unreadCount: unread,
    );
    list
      ..removeAt(index)
      ..insert(0, updated);
    emit(
      state.copyWith(
        conversations: list,
        status: ConversationsStatus.loaded,
      ),
    );
  }

  Future<void> _onMarkRead(
    ConversationsMarkReadRequested event,
    Emitter<ConversationsState> emit,
  ) async {
    await _service.markRoomRead(event.conversationId);
    final list = state.conversations.map((c) {
      if (c.id != event.conversationId) return c;
      return c.copyWith(unreadCount: 0);
    }).toList();
    emit(state.copyWith(conversations: list));
  }

  Future<void> _onLeave(
    ConversationsLeaveRequested event,
    Emitter<ConversationsState> emit,
  ) async {
    await _service.hideRoom(event.conversationId);
    final list =
        state.conversations.where((c) => c.id != event.conversationId).toList();
    emit(state.copyWith(conversations: list));
    await _syncInboxSocket(list.map((c) => c.id));
  }

  Future<void> _onRealtimeTick(
    ConversationsRealtimeTick event,
    Emitter<ConversationsState> emit,
  ) async {
    if (state.status != ConversationsStatus.loaded &&
        state.status != ConversationsStatus.initial) {
      return;
    }
    add(const ConversationsRefreshRequested());
  }

  Future<void> _onInboxResume(
    ConversationsInboxResumeRequested event,
    Emitter<ConversationsState> emit,
  ) async {
    add(const ConversationsRefreshRequested());
    await _inboxSocket?.reconnect();
  }

  Future<void> _onLastCreatedConsumed(
    ConversationsLastCreatedConsumed event,
    Emitter<ConversationsState> emit,
  ) async {
    emit(state.copyWith(clearLastCreated: true));
  }

  Future<void> _syncInboxSocket(Iterable<String> roomIds) async {
    if (!_enableInboxRealtime) return;
    final ids = roomIds.toList();
    if (ids.isEmpty) {
      await _inboxSocket?.disconnect(manual: true);
      _inboxSocket = null;
      return;
    }
    _inboxSocket ??= CmfMultiRoomSocket(
      onRoomMessage: ({
        required String roomId,
        required String body,
        required String from,
        required DateTime at,
        String? messageId,
      }) {
        if (isClosed) return;
        add(
          ConversationsPreviewUpdated(
            conversationId: roomId,
            preview: body,
            at: at,
          ),
        );
      },
    );
    await _inboxSocket!.syncRooms(ids);
  }

  @override
  Future<void> close() async {
    _identitySub?.cancel();
    _pollTimer?.cancel();
    await _inboxSocket?.disconnect(manual: true);
    _inboxSocket = null;
    return super.close();
  }
}
