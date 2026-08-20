import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:replicaz/app/theme/app_colors.dart';
import 'package:replicaz/app/theme/app_motion.dart';
import 'package:replicaz/app/theme/app_spacing.dart';
import 'package:replicaz/app/theme/app_type.dart';
import 'package:replicaz/core/widgets/ambient_background.dart';
import 'package:replicaz/core/widgets/empty_state.dart';
import 'package:replicaz/core/widgets/life_list_cell.dart';
import 'package:replicaz/core/widgets/screen_header.dart';
import 'package:replicaz/core/widgets/skeletons/replicaz_skeletons.dart';
import 'package:replicaz/features/desk/presentation/widgets/needs_you_panel.dart';
import 'package:replicaz/features/follow_ups/bloc/follow_ups_bloc.dart';
import 'package:replicaz/features/follow_ups/presentation/create_follow_up_sheet.dart';
import 'package:replicaz/features/follow_ups/domain/follow_up.dart';
import 'package:replicaz/features/identities/bloc/identities_bloc.dart';
import 'package:replicaz/features/notes/bloc/notes_bloc.dart';

/// Slasher "Desk" — notes + follow-ups for the active life (one tab, two modes).
class DeskScreen extends StatefulWidget {
  const DeskScreen({super.key});

  @override
  State<DeskScreen> createState() => _DeskScreenState();
}

class _DeskScreenState extends State<DeskScreen> {
  /// 0 = notes, 1 = follow-ups
  int _mode = 0;

  @override
  Widget build(BuildContext context) {
    final active = context.watch<IdentitiesBloc>().state.activeIdentity;
    final life = active?.name ?? 'this life';
    final accent = active?.color ?? AppColors.accent;

    return Scaffold(
      body: AmbientBackground(
        lifeColor: active?.color,
        intense: true,
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ScreenHeader(
                title: 'Desk',
                subtitle: active == null
                    ? 'Notes & next steps'
                    : 'For $life only',
                subtitleColor: active?.color,
                actions: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: _mode == 0 ? 'New note' : 'Add follow-up',
                    onPressed: () {
                      if (_mode == 0) {
                        context.push('/desk/notes/new');
                      } else {
                        _showCreateFollowUp(context);
                      }
                    },
                    icon: Icon(
                      _mode == 0
                          ? Icons.note_add_rounded
                          : Icons.add_task_rounded,
                    ),
                  ),
                ],
              ),
              Builder(
                builder: (context) {
                  final fus = context.watch<FollowUpsBloc>().state.items;
                  final open = fus
                      .where((e) => e.status == FollowUpStatus.open)
                      .length;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      NeedsYouPanel(
                        lifeName: life,
                        accent: accent,
                        onOpenFollowUps: () => setState(() => _mode = 1),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: _DeskSegment(
                          index: _mode,
                          accent: accent,
                          openFollowUps: open,
                          notesCount:
                              context.watch<NotesBloc>().state.notes.length,
                          onChanged: (i) {
                            HapticFeedback.selectionClick();
                            setState(() => _mode = i);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
              Expanded(
                child: LifeSwitchScope(
                  lifeKey: '${active?.id}-$_mode',
                  child: _mode == 0
                      ? _NotesPane(life: life, accent: accent)
                      : _FollowUpsPane(
                          life: life,
                          accent: accent,
                          onAdd: () => _showCreateFollowUp(context),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateFollowUp(BuildContext context) async {
    await showCreateFollowUpSheet(context);
  }
}

class _DeskSegment extends StatelessWidget {
  const _DeskSegment({
    required this.index,
    required this.accent,
    required this.onChanged,
    this.openFollowUps = 0,
    this.notesCount = 0,
  });

  final int index;
  final Color accent;
  final ValueChanged<int> onChanged;
  final int openFollowUps;
  final int notesCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          _seg(
            context,
            0,
            'Notes',
            Icons.sticky_note_2_outlined,
            badge: notesCount > 0 ? '$notesCount' : null,
          ),
          _seg(
            context,
            1,
            'Follow-ups',
            Icons.checklist_rounded,
            badge: openFollowUps > 0 ? '$openFollowUps' : null,
          ),
        ],
      ),
    );
  }

  Widget _seg(
    BuildContext context,
    int i,
    String label,
    IconData icon, {
    String? badge,
  }) {
    final on = index == i;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(i),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: AppMotion.fast,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: on ? accent.withValues(alpha: 0.14) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: on ? accent : AppColors.inkMuted),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppType.labelMd(
                    color: on ? AppColors.ink : AppColors.inkMuted,
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: on
                          ? accent.withValues(alpha: 0.2)
                          : AppColors.ink.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge,
                      style: AppType.labelSm(
                        color: on ? accent : AppColors.inkMuted,
                      ).copyWith(fontSize: 10),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotesPane extends StatelessWidget {
  const _NotesPane({required this.life, required this.accent});

  final String life;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotesBloc, NotesState>(
      builder: (context, state) {
        if (state.notes.isEmpty &&
            (state.status == NotesStatus.loading ||
                state.status == NotesStatus.initial)) {
          return const NotesSkeleton();
        }
        if (state.notes.isEmpty) {
          return EmptyState(
            accent: accent,
            title: 'Empty desk notes',
            message: 'Scratch ideas that belong only to $life.',
            actionLabel: 'New note',
            icon: Icons.sticky_note_2_outlined,
            onAction: () => context.push('/desk/notes/new'),
          );
        }
        return ListView.builder(
          padding: EdgeInsets.fromLTRB(8, 0, 8, AppSpacing.listBottomInset(context)),
          itemCount: state.notes.length,
          itemBuilder: (context, index) {
            final note = state.notes[index];
            return LifeListCell(
              title: note.title,
              subtitle: note.body.trim().isEmpty
                  ? 'No body'
                  : note.body.trim().replaceAll('\n', ' '),
              accent: accent,
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: accent.withValues(alpha: 0.12),
                child: Icon(Icons.sticky_note_2_outlined, color: accent, size: 22),
              ),
              onTap: () => context.push('/desk/notes/${note.id}/edit'),
            );
          },
        );
      },
    );
  }
}

class _FollowUpsPane extends StatelessWidget {
  const _FollowUpsPane({
    required this.life,
    required this.accent,
    required this.onAdd,
  });

  final String life;
  final Color accent;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat.MMMd();
    return BlocBuilder<FollowUpsBloc, FollowUpsState>(
      builder: (context, state) {
        if (state.items.isEmpty &&
            (state.status == FollowUpsStatus.loading ||
                state.status == FollowUpsStatus.initial)) {
          return const FollowUpsSkeleton();
        }
        if (state.items.isEmpty) {
          return EmptyState(
            accent: accent,
            title: 'No open loops',
            message: 'Next steps for $life only — not mixed with other lives.',
            actionLabel: 'Add follow-up',
            icon: Icons.checklist_rounded,
            onAction: onAdd,
          );
        }
        final items = [...state.items]..sort((a, b) {
          final ao = a.status == FollowUpStatus.open ? 0 : 1;
          final bo = b.status == FollowUpStatus.open ? 0 : 1;
          if (ao != bo) return ao.compareTo(bo);
          final ad = a.dueAt;
          final bd = b.dueAt;
          if (ad == null && bd == null) return 0;
          if (ad == null) return 1;
          if (bd == null) return -1;
          return ad.compareTo(bd);
        });
        return ListView.builder(
          padding: EdgeInsets.fromLTRB(8, 0, 8, AppSpacing.listBottomInset(context)),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final done = item.status == FollowUpStatus.done;
            final due = item.dueAt == null
                ? null
                : 'Due ${formatter.format(item.dueAt!.toLocal())}';
            return LifeListCell(
              title: item.title,
              subtitle: [
                if (item.contactName.isNotEmpty) item.contactName,
                if (item.details.isNotEmpty) item.details,
                if (due != null) due,
              ].join(' · '),
              accent: accent,
              emphasized: !done &&
                  item.dueAt != null &&
                  item.dueAt!.toLocal().isBefore(DateTime.now()),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: (done ? AppColors.inkMuted : accent)
                    .withValues(alpha: 0.12),
                child: Icon(
                  done ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: done ? AppColors.inkMuted : accent,
                  size: 22,
                ),
              ),
              trailing: IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => context
                    .read<FollowUpsBloc>()
                    .add(FollowUpsDeleteRequested(item.id)),
              ),
              onTap: () => context
                  .read<FollowUpsBloc>()
                  .add(FollowUpsToggleRequested(item)),
            );
          },
        );
      },
    );
  }
}
