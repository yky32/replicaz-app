import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:replicaz/app/theme/app_colors.dart';
import 'package:replicaz/app/theme/app_spacing.dart';
import 'package:replicaz/core/widgets/ambient_background.dart';
import 'package:replicaz/core/widgets/empty_state.dart';
import 'package:replicaz/core/widgets/screen_header.dart';
import 'package:replicaz/features/identities/bloc/identities_bloc.dart';
import 'package:replicaz/features/notes/bloc/notes_bloc.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat.MMMd();
    final active = context.watch<IdentitiesBloc>().state.activeIdentity;

    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              ScreenHeader(
                title: 'Notes',
                subtitle: active == null ? null : 'In ${active.name}',
                subtitleColor: active?.color,
                actions: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => context.push('/notes/new'),
                    icon: const Icon(Icons.add_rounded),
                    tooltip: 'New note',
                  ),
                ],
              ),
              Expanded(
                child: BlocBuilder<NotesBloc, NotesState>(
                  builder: (context, state) {
                    if (state.status == NotesStatus.loading &&
                        state.notes.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state.notes.isEmpty) {
                      final life = active?.name ?? 'this identity';
                      return EmptyState(
                        title: 'No notes in $life',
                        message:
                            'Jot things that only make sense while you are $life.',
                        actionLabel: 'New note',
                        icon: Icons.edit_note_rounded,
                        onAction: () => context.push('/notes/new'),
                      );
                    }
                    return ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        4,
                        20,
                        AppSpacing.listBottomInset(context),
                      ),
                      itemCount: state.notes.length,
                      separatorBuilder: (_, index) =>
                          const Divider(height: 1, color: AppColors.hairline),
                      itemBuilder: (context, index) {
                        final note = state.notes[index];
                        return InkWell(
                          onTap: () => context.push('/notes/${note.id}/edit'),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  note.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16.5,
                                  ),
                                ),
                                if (note.body.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    note.body,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.inkMuted,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Text(
                                  formatter.format(note.updatedAt.toLocal()),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: AppColors.inkMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
