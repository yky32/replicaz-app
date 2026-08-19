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
import 'package:replicaz/core/widgets/replicaz_bottom_sheet.dart';
import 'package:replicaz/core/widgets/screen_header.dart';
import 'package:replicaz/core/widgets/skeletons/replicaz_skeletons.dart';
import 'package:replicaz/features/follow_ups/bloc/follow_ups_bloc.dart';
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: _DeskSegment(
                  index: _mode,
                  accent: accent,
                  onChanged: (i) {
                    HapticFeedback.selectionClick();
                    setState(() => _mode = i);
                  },
                ),
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
    final title = TextEditingController();
    final details = TextEditingController();
    DateTime? dueAt;
    final bloc = context.read<FollowUpsBloc>();

    await ReplicazBottomSheet.show<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModal) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                16 + MediaQuery.viewInsetsOf(sheetContext).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('New follow-up', style: AppType.titleLg()),
                  const SizedBox(height: 14),
                  TextField(
                    controller: title,
                    autofocus: true,
                    decoration: const InputDecoration(hintText: 'What next?'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: details,
                    maxLines: 2,
                    decoration: const InputDecoration(hintText: 'Details (optional)'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: dueAt ?? now,
                        firstDate: now.subtract(const Duration(days: 1)),
                        lastDate: now.add(const Duration(days: 365 * 2)),
                      );
                      if (picked != null) setModal(() => dueAt = picked);
                    },
                    icon: const Icon(Icons.event_outlined, size: 18),
                    label: Text(
                      dueAt == null
                          ? 'Add due date'
                          : 'Due ${DateFormat.MMMd().format(dueAt!)}',
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: () {
                      if (title.text.trim().isEmpty) return;
                      bloc.add(
                        FollowUpsAddRequested(
                          title: title.text.trim(),
                          details: details.text.trim(),
                          dueAt: dueAt,
                        ),
                      );
                      Navigator.pop(sheetContext);
                    },
                    child: const Text('Add'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    title.dispose();
    details.dispose();
  }
}

class _DeskSegment extends StatelessWidget {
  const _DeskSegment({
    required this.index,
    required this.accent,
    required this.onChanged,
  });

  final int index;
  final Color accent;
  final ValueChanged<int> onChanged;

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
          _seg(context, 0, 'Notes', Icons.sticky_note_2_outlined),
          _seg(context, 1, 'Follow-ups', Icons.checklist_rounded),
        ],
      ),
    );
  }

  Widget _seg(
    BuildContext context,
    int i,
    String label,
    IconData icon,
  ) {
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
        return ListView.builder(
          padding: EdgeInsets.fromLTRB(8, 0, 8, AppSpacing.listBottomInset(context)),
          itemCount: state.items.length,
          itemBuilder: (context, index) {
            final item = state.items[index];
            final done = item.status == FollowUpStatus.done;
            final due = item.dueAt == null
                ? null
                : 'Due ${formatter.format(item.dueAt!.toLocal())}';
            return LifeListCell(
              title: item.title,
              subtitle: [
                if (item.details.isNotEmpty) item.details,
                if (due != null) due,
              ].join(' · '),
              accent: accent,
              emphasized: !done && item.dueAt != null,
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
