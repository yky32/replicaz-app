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
    on<ConversationsCreateRequested>(_onCreate);

    _identitySub = _identitiesBloc.stream.listen((identityState) {
      final id = identityState.activeIdentityId;
      if (id != null) add(ConversationsLoadRequested(identityId: id));
    });

    final initialId = _identitiesBloc.state.activeIdentityId;
    if (initialId != null) {
      add(ConversationsLoadRequested(identityId: initialId));
    }
  }

  final IdentitiesBloc _identitiesBloc;
  final MessagingService _service;
  StreamSubscription<IdentitiesState>? _identitySub;

  Future<void> _onLoad(
    ConversationsLoadRequested event,
    Emitter<ConversationsState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ConversationsStatus.loading,
        identityId: event.identityId,
      ),
    );
    final conversations =
        await _service.conversationsForIdentity(event.identityId);
    emit(
      state.copyWith(
        status: ConversationsStatus.loaded,
        conversations: conversations,
        identityId: event.identityId,
      ),
    );
  }

  Future<void> _onCreate(
    ConversationsCreateRequested event,
    Emitter<ConversationsState> emit,
  ) async {
    final identityId =
        state.identityId ?? _identitiesBloc.state.activeIdentityId;
    if (identityId == null) return;
    await _service.createDirectConversation(
      ownerIdentityId: identityId,
      createdByUserId: event.userId,
      title: event.title ?? 'New chat',
      participantUserId: event.participantUserId,
    );
    add(ConversationsLoadRequested(identityId: identityId));
  }

  @override
  Future<void> close() {
    _identitySub?.cancel();
    return super.close();
  }
}
