import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:replicaz/app/theme/app_colors.dart';
import 'package:replicaz/core/bootstrap/app_bootstrap.dart';
import 'package:replicaz/features/identities/bloc/identities_bloc.dart';
import 'package:replicaz/features/notes/bloc/notes_bloc.dart';
import 'package:replicaz/features/notes/domain/note.dart';
import 'package:uuid/uuid.dart';

class NoteFormScreen extends StatefulWidget {
  const NoteFormScreen({super.key, this.noteId});

  final String? noteId;

  @override
  State<NoteFormScreen> createState() => _NoteFormScreenState();
}

class _NoteFormScreenState extends State<NoteFormScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool get _isEdit => widget.noteId != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_isEdit) return;
      final note = await AppBootstrap.noteService.getById(widget.noteId!);
      if (note == null || !mounted) return;
      _title.text = note.title;
      _body.text = note.body;
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit note' : 'New note'),
        actions: [
          if (_isEdit)
            IconButton(
              onPressed: () {
                context
                    .read<NotesBloc>()
                    .add(NotesDeleteRequested(widget.noteId!));
                context.pop();
              },
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(hintText: 'Title'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _body,
              maxLines: 10,
              decoration: const InputDecoration(hintText: 'Body'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                final activeId =
                    context.read<IdentitiesBloc>().state.activeIdentityId;
                final notesBloc = context.read<NotesBloc>();
                final now = DateTime.now().toUtc();
                final existing = _isEdit
                    ? await AppBootstrap.noteService.getById(widget.noteId!)
                    : null;
                if (!context.mounted) return;
                // Edits keep original identity; creates use active life.
                final identityId = existing?.identityId ?? activeId;
                if (identityId == null) return;
                notesBloc.add(
                  NotesSaveRequested(
                    Note(
                      id: existing?.id ?? const Uuid().v4(),
                      identityId: identityId,
                      title: _title.text.trim(),
                      body: _body.text.trim(),
                      createdAt: existing?.createdAt ?? now,
                      updatedAt: now,
                      dirty: true,
                    ),
                  ),
                );
                context.pop();
              },
              child: Text(_isEdit ? 'Save' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }
}
