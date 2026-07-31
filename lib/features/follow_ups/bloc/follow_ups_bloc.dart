import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:replicaz/core/bootstrap/app_bootstrap.dart';
import 'package:replicaz/features/follow_ups/data/follow_up_service.dart';
import 'package:replicaz/features/follow_ups/domain/follow_up.dart';
import 'package:replicaz/features/identities/bloc/identities_bloc.dart';
import 'package:uuid/uuid.dart';

part 'follow_ups_event.dart';
part 'follow_ups_state.dart';

class FollowUpsBloc extends Bloc<FollowUpsEvent, FollowUpsState> {
  FollowUpsBloc({
    required IdentitiesBloc identitiesBloc,
    FollowUpService? followUpService,
  })  : _identitiesBloc = identitiesBloc,
        _service = followUpService ?? AppBootstrap.followUpService,
        super(const FollowUpsState()) {
    on<FollowUpsLoadRequested>(_onLoad);
    on<FollowUpsAddRequested>(_onAdd);
    on<FollowUpsToggleRequested>(_onToggle);
    on<FollowUpsDeleteRequested>(_onDelete);

    _identitySub = _identitiesBloc.stream.listen((identityState) {
      final id = identityState.activeIdentityId;
      if (id != null) add(FollowUpsLoadRequested(identityId: id));
    });

    final initialId = _identitiesBloc.state.activeIdentityId;
    if (initialId != null) add(FollowUpsLoadRequested(identityId: initialId));
  }

  final IdentitiesBloc _identitiesBloc;
  final FollowUpService _service;
  final _uuid = const Uuid();
  StreamSubscription<IdentitiesState>? _identitySub;

  Future<void> _onLoad(
    FollowUpsLoadRequested event,
    Emitter<FollowUpsState> emit,
  ) async {
    emit(state.copyWith(status: FollowUpsStatus.loading, identityId: event.identityId));
    final items = await _service.byIdentity(event.identityId);
    emit(
      state.copyWith(
        status: FollowUpsStatus.loaded,
        items: items,
        identityId: event.identityId,
      ),
    );
  }

  Future<void> _onAdd(
    FollowUpsAddRequested event,
    Emitter<FollowUpsState> emit,
  ) async {
    final identityId = state.identityId ?? _identitiesBloc.state.activeIdentityId;
    if (identityId == null) return;
    final now = DateTime.now().toUtc();
    await _service.save(
      FollowUp(
        id: _uuid.v4(),
        identityId: identityId,
        title: event.title,
        details: event.details,
        dueAt: event.dueAt,
        createdAt: now,
        updatedAt: now,
      ),
    );
    add(FollowUpsLoadRequested(identityId: identityId));
  }

  Future<void> _onToggle(
    FollowUpsToggleRequested event,
    Emitter<FollowUpsState> emit,
  ) async {
    final next = event.item.copyWith(
      status: event.item.status == FollowUpStatus.open
          ? FollowUpStatus.done
          : FollowUpStatus.open,
      updatedAt: DateTime.now().toUtc(),
    );
    await _service.save(next);
    final identityId = state.identityId;
    if (identityId != null) add(FollowUpsLoadRequested(identityId: identityId));
  }

  Future<void> _onDelete(
    FollowUpsDeleteRequested event,
    Emitter<FollowUpsState> emit,
  ) async {
    await _service.delete(event.followUpId);
    final identityId = state.identityId;
    if (identityId != null) add(FollowUpsLoadRequested(identityId: identityId));
  }

  @override
  Future<void> close() {
    _identitySub?.cancel();
    return super.close();
  }
}
