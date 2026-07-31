import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:replicaz/core/bootstrap/app_bootstrap.dart';
import 'package:replicaz/features/identities/data/identity_service.dart';
import 'package:replicaz/features/identities/domain/identity.dart';

part 'identities_event.dart';
part 'identities_state.dart';

class IdentitiesBloc extends Bloc<IdentitiesEvent, IdentitiesState> {
  IdentitiesBloc({IdentityService? identityService})
      : _service = identityService ?? AppBootstrap.identityService,
        super(const IdentitiesState()) {
    on<IdentitiesLoadRequested>(_onLoad);
    on<IdentitiesSwitchRequested>(_onSwitch);
    on<IdentitiesCreateRequested>(_onCreate);
    on<IdentitiesUpdateRequested>(_onUpdate);
    on<IdentitiesDeleteRequested>(_onDelete);
  }

  final IdentityService _service;

  Future<void> _onLoad(
    IdentitiesLoadRequested event,
    Emitter<IdentitiesState> emit,
  ) async {
    emit(state.copyWith(status: IdentitiesStatus.loading));
    try {
      await _service.seedDefaultsIfEmpty();
      final identities = await _service.getAll();
      final activeId = await _service.getActiveId() ??
          (identities.isNotEmpty ? identities.first.id : null);
      emit(
        state.copyWith(
          status: IdentitiesStatus.loaded,
          identities: identities,
          activeIdentityId: activeId,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: IdentitiesStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onSwitch(
    IdentitiesSwitchRequested event,
    Emitter<IdentitiesState> emit,
  ) async {
    await _service.setActiveId(event.identityId);
    emit(state.copyWith(activeIdentityId: event.identityId));
  }

  Future<void> _onCreate(
    IdentitiesCreateRequested event,
    Emitter<IdentitiesState> emit,
  ) async {
    await _service.create(event.identity);
    add(const IdentitiesLoadRequested());
  }

  Future<void> _onUpdate(
    IdentitiesUpdateRequested event,
    Emitter<IdentitiesState> emit,
  ) async {
    await _service.update(event.identity);
    add(const IdentitiesLoadRequested());
  }

  Future<void> _onDelete(
    IdentitiesDeleteRequested event,
    Emitter<IdentitiesState> emit,
  ) async {
    await _service.delete(event.identityId);
    add(const IdentitiesLoadRequested());
  }
}
