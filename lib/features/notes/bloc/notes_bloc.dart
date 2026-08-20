import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:replicaz/core/bootstrap/app_bootstrap.dart';
import 'package:replicaz/core/widgets/skeletons/skeleton_timing.dart';
import 'package:replicaz/features/identities/bloc/identities_bloc.dart';
import 'package:replicaz/features/notes/data/note_service.dart';
import 'package:replicaz/features/notes/domain/note.dart';

part 'notes_event.dart';
part 'notes_state.dart';

class NotesBloc extends Bloc<NotesEvent, NotesState> {
  NotesBloc({
    required IdentitiesBloc identitiesBloc,
    NoteService? noteService,
  })  : _identitiesBloc = identitiesBloc,
        _service = noteService ?? AppBootstrap.noteService,
        super(const NotesState()) {
    on<NotesLoadRequested>(_onLoad);
    on<NotesSaveRequested>(_onSave);
    on<NotesDeleteRequested>(_onDelete);

    _identitySub = _identitiesBloc.stream
        .map((s) => s.activeIdentityId)
        .distinct()
        .listen((id) {
      if (id != null) add(NotesLoadRequested(identityId: id));
    });

    final initialId = _identitiesBloc.state.activeIdentityId;
    if (initialId != null) add(NotesLoadRequested(identityId: initialId));
  }

  final IdentitiesBloc _identitiesBloc;
  final NoteService _service;
  StreamSubscription<String?>? _identitySub;
  final Map<String, List<Note>> _cache = {};

  Future<void> _onLoad(
    NotesLoadRequested event,
    Emitter<NotesState> emit,
  ) async {
    final cached = _cache[event.identityId];
    if (cached != null) {
      emit(
        state.copyWith(
          status: NotesStatus.loaded,
          identityId: event.identityId,
          notes: cached,
        ),
      );
      final fresh = await _service.byIdentity(event.identityId);
      if (state.identityId != event.identityId) return;
      _cache[event.identityId] = fresh;
      emit(
        state.copyWith(
          status: NotesStatus.loaded,
          notes: fresh,
          identityId: event.identityId,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        status: NotesStatus.loading,
        identityId: event.identityId,
        notes: const [],
      ),
    );
    final sw = Stopwatch()..start();
    final notes = await _service.byIdentity(event.identityId);
    await awaitReplicazMinSkeleton(sw);
    if (state.identityId != null && state.identityId != event.identityId) {
      return;
    }
    _cache[event.identityId] = notes;
    emit(
      state.copyWith(
        status: NotesStatus.loaded,
        notes: notes,
        identityId: event.identityId,
      ),
    );
  }

  Future<void> _onSave(
    NotesSaveRequested event,
    Emitter<NotesState> emit,
  ) async {
    await _service.save(event.note);
    _cache.remove(event.note.identityId);
    add(NotesLoadRequested(identityId: event.note.identityId));
  }

  Future<void> _onDelete(
    NotesDeleteRequested event,
    Emitter<NotesState> emit,
  ) async {
    await _service.delete(event.noteId);
    final identityId = state.identityId;
    if (identityId != null) {
      _cache.remove(identityId);
      add(NotesLoadRequested(identityId: identityId));
    }
  }

  @override
  Future<void> close() {
    _identitySub?.cancel();
    return super.close();
  }
}
