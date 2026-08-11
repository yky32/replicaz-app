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
      await _service.ensureOnboarded();
      final identities = await _service.getAll();
      final activeId = await _service.getActiveId() ??
          (identities.isNotEmpty ? identities.first.id : null);
      if (activeId != null) {
        await _service.setActiveId(activeId);
      }
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
    if (event.identityId == state.activeIdentityId) return;
    final exists = state.identities.any((e) => e.id == event.identityId);
    if (!exists) return;
    await _service.setActiveId(event.identityId);
    emit(
      state.copyWith(
        activeIdentityId: event.identityId,
        status: IdentitiesStatus.loaded,
      ),
    );
  }

  Future<void> _onCreate(
    IdentitiesCreateRequested event,
    Emitter<IdentitiesState> emit,
  ) async {
    try {
      await _service.create(event.identity);
      // Switch into the life you just created.
      await _service.setActiveId(event.identity.id);
      final identities = await _service.getAll();
      emit(
        state.copyWith(
          status: IdentitiesStatus.loaded,
          identities: identities,
          activeIdentityId: event.identity.id,
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

  Future<void> _onUpdate(
    IdentitiesUpdateRequested event,
    Emitter<IdentitiesState> emit,
  ) async {
    try {
      await _service.update(event.identity);
      final identities = await _service.getAll();
      emit(
        state.copyWith(
          status: IdentitiesStatus.loaded,
          identities: identities,
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

  Future<void> _onDelete(
    IdentitiesDeleteRequested event,
    Emitter<IdentitiesState> emit,
  ) async {
    try {
      // Keep at least one identity — re-seed Personal if wiped.
      final before = await _service.getAll();
      if (before.length <= 1) {
        emit(
          state.copyWith(
            errorMessage: 'Keep at least one identity.',
          ),
        );
        return;
      }
      await _service.delete(event.identityId);
      await _service.ensureOnboarded();
      final identities = await _service.getAll();
      final activeId = await _service.getActiveId();
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
}
