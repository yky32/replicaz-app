part of 'notes_bloc.dart';

enum NotesStatus { initial, loading, loaded }

class NotesState extends Equatable {
  const NotesState({
    this.status = NotesStatus.initial,
    this.notes = const [],
    this.identityId,
  });

  final NotesStatus status;
  final List<Note> notes;
  final String? identityId;

  NotesState copyWith({
    NotesStatus? status,
    List<Note>? notes,
    String? identityId,
  }) {
    return NotesState(
      status: status ?? this.status,
      notes: notes ?? this.notes,
      identityId: identityId ?? this.identityId,
    );
  }

  @override
  List<Object?> get props => [status, notes, identityId];
}
