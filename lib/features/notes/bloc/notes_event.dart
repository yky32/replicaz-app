part of 'notes_bloc.dart';

sealed class NotesEvent extends Equatable {
  const NotesEvent();

  @override
  List<Object?> get props => [];
}

final class NotesLoadRequested extends NotesEvent {
  const NotesLoadRequested({required this.identityId, this.force = false});

  final String identityId;
  final bool force;

  @override
  List<Object?> get props => [identityId, force];
}

final class NotesSaveRequested extends NotesEvent {
  const NotesSaveRequested(this.note);

  final Note note;

  @override
  List<Object?> get props => [note];
}

final class NotesDeleteRequested extends NotesEvent {
  const NotesDeleteRequested(this.noteId);

  final String noteId;

  @override
  List<Object?> get props => [noteId];
}
