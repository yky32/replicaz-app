import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:replicaz/core/bootstrap/app_bootstrap.dart';
import 'package:replicaz/features/identities/bloc/identities_bloc.dart';
import 'package:replicaz/features/messaging/data/messaging_service.dart';
import 'package:replicaz/features/messaging/domain/conversation.dart';

part 'conversations_event.dart';
part 'conversations_state.dart';

class ConversationsBloc extends Bloc<ConversationsEvent, ConversationsState> {
  ConversationsBloc({
    required IdentitiesBloc identitiesBloc,
    MessagingService? messagingService,
  })  : _identitiesBloc = identitiesBloc,
        _service = messagingService ?? AppBootstrap.messagingService,
        super(const ConversationsState()) {
    on<ConversationsLoadRequested>(_onLoad);
    on<ConversationsRefreshRequested>(_onRefresh);
    on<ConversationsCreateRequested>(_onCreate);
    on<ConversationsPreviewUpdated>(_onPreview);

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
  }

  final IdentitiesBloc _identitiesBloc;
  final MessagingService _service;
  StreamSubscription<String?>? _identitySub;

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
      await _service.createDirectConversation(
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
          clearError: true,
        ),
      );
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
    final updated = list[index].copyWith(
      lastMessageAt: event.at,
      lastMessagePreview: event.preview,
      updatedAt: event.at,
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

  @override
  Future<void> close() {
    _identitySub?.cancel();
    return super.close();
  }
}
