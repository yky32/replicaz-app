import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:replicaz/core/bootstrap/app_bootstrap.dart';
import 'package:replicaz/core/widgets/skeletons/skeleton_timing.dart';
import 'package:replicaz/features/identities/bloc/identities_bloc.dart';
import 'package:replicaz/features/receipts/data/receipt_service.dart';
import 'package:replicaz/features/receipts/domain/receipt.dart';

part 'receipts_event.dart';
part 'receipts_state.dart';

class ReceiptsBloc extends Bloc<ReceiptsEvent, ReceiptsState> {
  ReceiptsBloc({
    required IdentitiesBloc identitiesBloc,
    ReceiptService? receiptService,
  })  : _identitiesBloc = identitiesBloc,
        _service = receiptService ?? AppBootstrap.receiptService,
        super(const ReceiptsState()) {
    on<ReceiptsLoadRequested>(_onLoad);
    on<ReceiptsSaveRequested>(_onSave);
    on<ReceiptsDeleteRequested>(_onDelete);

    _identitySub = _identitiesBloc.stream
        .map((s) => s.activeIdentityId)
        .distinct()
        .listen((id) {
      if (id != null) add(ReceiptsLoadRequested(identityId: id));
    });

    final initialId = _identitiesBloc.state.activeIdentityId;
    if (initialId != null) add(ReceiptsLoadRequested(identityId: initialId));
  }

  final IdentitiesBloc _identitiesBloc;
  final ReceiptService _service;
  StreamSubscription<String?>? _identitySub;
  final Map<String, List<Receipt>> _cache = {};

  Future<void> _onLoad(
    ReceiptsLoadRequested event,
    Emitter<ReceiptsState> emit,
  ) async {
    if (event.force) _cache.remove(event.identityId);
    final cached = _cache[event.identityId];
    if (cached != null) {
      emit(
        state.copyWith(
          status: ReceiptsStatus.loaded,
          identityId: event.identityId,
          items: cached,
        ),
      );
      final fresh = await _service.byIdentity(event.identityId);
      if (state.identityId != event.identityId) return;
      _cache[event.identityId] = fresh;
      emit(
        state.copyWith(
          status: ReceiptsStatus.loaded,
          items: fresh,
          identityId: event.identityId,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: ReceiptsStatus.loading,
        identityId: event.identityId,
        items: const [],
      ),
    );
    final sw = Stopwatch()..start();
    final items = await _service.byIdentity(event.identityId);
    await awaitReplicazMinSkeleton(sw);
    if (state.identityId != null && state.identityId != event.identityId) {
      return;
    }
    _cache[event.identityId] = items;
    emit(
      state.copyWith(
        status: ReceiptsStatus.loaded,
        items: items,
        identityId: event.identityId,
      ),
    );
  }

  Future<void> _onSave(
    ReceiptsSaveRequested event,
    Emitter<ReceiptsState> emit,
  ) async {
    await _service.save(event.receipt);
    final identityId = event.receipt.identityId;
    _cache.remove(identityId);
    add(ReceiptsLoadRequested(identityId: identityId, force: true));
  }

  Future<void> _onDelete(
    ReceiptsDeleteRequested event,
    Emitter<ReceiptsState> emit,
  ) async {
    await _service.delete(event.receiptId);
    final identityId = state.identityId;
    if (identityId != null) {
      _cache.remove(identityId);
      add(ReceiptsLoadRequested(identityId: identityId, force: true));
    }
  }

  @override
  Future<void> close() {
    _identitySub?.cancel();
    return super.close();
  }
}
