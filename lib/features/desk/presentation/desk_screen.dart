import 'dart:io';
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
import 'package:replicaz/core/widgets/other_lives_pulse.dart';
import 'package:replicaz/core/widgets/screen_header.dart';
import 'package:replicaz/core/widgets/skeletons/replicaz_skeletons.dart';
import 'package:replicaz/features/desk/presentation/widgets/needs_you_panel.dart';
import 'package:replicaz/features/follow_ups/bloc/follow_ups_bloc.dart';
import 'package:replicaz/features/follow_ups/presentation/create_follow_up_sheet.dart';
import 'package:replicaz/features/follow_ups/domain/follow_up.dart';
import 'package:replicaz/features/identities/bloc/identities_bloc.dart';
import 'package:replicaz/features/notes/bloc/notes_bloc.dart';
import 'package:replicaz/features/receipts/bloc/receipts_bloc.dart';
import 'package:replicaz/features/receipts/domain/receipt.dart';

/// Slasher "Desk" — notes + follow-ups + slips for the active life.
class DeskScreen extends StatefulWidget {
  const DeskScreen({super.key});

  @override
  State<DeskScreen> createState() => _DeskScreenState();
}

class _DeskScreenState extends State<DeskScreen> {
  /// 0 = notes, 1 = follow-ups, 2 = slips
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
                    tooltip: switch (_mode) {
                      0 => 'New note',
                      1 => 'Add follow-up',
                      _ => 'Scan slip',
                    },
                    onPressed: () {
                      if (_mode == 0) {
                        context.push('/desk/notes/new');
                      } else if (_mode == 1) {
                        _showCreateFollowUp(context);
                      } else {
                        context.push('/desk/slips/scan');
                      }
                    },
                    icon: Icon(
                      switch (_mode) {
                        0 => Icons.note_add_rounded,
                        1 => Icons.add_task_rounded,
                        _ => Icons.qr_code_scanner_rounded,
                      },
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
                      const OtherLivesPulse(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: _DeskSegment(
                          index: _mode,
                          accent: accent,
                          openFollowUps: open,
                          notesCount:
                              context.watch<NotesBloc>().state.notes.length,
                          slipsCount:
                              context.watch<ReceiptsBloc>().state.items.length,
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
                  child: switch (_mode) {
                    0 => _NotesPane(life: life, accent: accent),
                    1 => _FollowUpsPane(
                        life: life,
                        accent: accent,
                        onAdd: () => _showCreateFollowUp(context),
                      ),
                    _ => _SlipsPane(life: life, accent: accent),
                  },
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
    this.slipsCount = 0,
  });

  final int index;
  final Color accent;
  final ValueChanged<int> onChanged;
  final int openFollowUps;
  final int notesCount;
  final int slipsCount;

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
          _seg(
            context,
            2,
            'Slips',
            Icons.receipt_long_rounded,
            badge: slipsCount > 0 ? '$slipsCount' : null,
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
                Icon(icon, size: 15, color: on ? accent : AppColors.inkMuted),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.labelSm(
                    color: on ? AppColors.ink : AppColors.inkMuted,
                  ),
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

class _NotesPane extends StatefulWidget {
  const _NotesPane({required this.life, required this.accent});

  final String life;
  final Color accent;

  @override
  State<_NotesPane> createState() => _NotesPaneState();
}

class _NotesPaneState extends State<_NotesPane> {
  bool _pullRefreshing = false;

  @override
  Widget build(BuildContext context) {
    final life = widget.life;
    final accent = widget.accent;
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
        return RefreshIndicator(
          color: accent,
          onRefresh: () async {
            final id = state.identityId ??
                context.read<IdentitiesBloc>().state.activeIdentityId;
            if (id == null) return;
            setState(() => _pullRefreshing = true);
            context.read<NotesBloc>().add(NotesLoadRequested(identityId: id, force: true));
            await Future<void>.delayed(const Duration(milliseconds: 450));
            if (mounted) setState(() => _pullRefreshing = false);
          },
          child: SkeletonOverlay(
            enabled: _pullRefreshing,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                8,
                0,
                8,
                AppSpacing.listBottomInset(context),
              ),
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
                    child: Icon(
                      Icons.sticky_note_2_outlined,
                      color: accent,
                      size: 22,
                    ),
                  ),
                  onTap: () => context.push('/desk/notes/${note.id}/edit'),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _FollowUpsPane extends StatefulWidget {
  const _FollowUpsPane({
    required this.life,
    required this.accent,
    required this.onAdd,
  });

  final String life;
  final Color accent;
  final VoidCallback onAdd;

  @override
  State<_FollowUpsPane> createState() => _FollowUpsPaneState();
}

class _FollowUpsPaneState extends State<_FollowUpsPane> {
  bool _pullRefreshing = false;

  @override
  Widget build(BuildContext context) {
    final life = widget.life;
    final accent = widget.accent;
    final onAdd = widget.onAdd;
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
        return RefreshIndicator(
          color: accent,
          onRefresh: () async {
            final id = state.identityId ??
                context.read<IdentitiesBloc>().state.activeIdentityId;
            if (id == null) return;
            setState(() => _pullRefreshing = true);
            context
                .read<FollowUpsBloc>()
                .add(FollowUpsLoadRequested(identityId: id, force: true));
            await Future<void>.delayed(const Duration(milliseconds: 450));
            if (mounted) setState(() => _pullRefreshing = false);
          },
          child: SkeletonOverlay(
            enabled: _pullRefreshing,
            child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(8, 0, 8, AppSpacing.listBottomInset(context)),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final done = item.status == FollowUpStatus.done;
            final due = item.dueAt == null
                ? null
                : 'Due ${formatter.format(item.dueAt!.toLocal())}';
            return Dismissible(
              key: ValueKey(item.id),
              direction: done
                  ? DismissDirection.none
                  : DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(Icons.check_rounded, color: accent),
              ),
              confirmDismiss: (_) async {
                context
                    .read<FollowUpsBloc>()
                    .add(FollowUpsToggleRequested(item));
                return false;
              },
              child: LifeListCell(
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
            ),
            );
          },
        ),
          ),
        );
      },
    );
  }
}

class _SlipsPane extends StatefulWidget {
  const _SlipsPane({required this.life, required this.accent});

  final String life;
  final Color accent;

  @override
  State<_SlipsPane> createState() => _SlipsPaneState();
}

class _SlipsPaneState extends State<_SlipsPane> {
  bool _pullRefreshing = false;

  IconData _iconFor(ReceiptKind k) => switch (k) {
        ReceiptKind.handwritten => Icons.draw_outlined,
        ReceiptKind.pos => Icons.point_of_sale_rounded,
        ReceiptKind.delivery => Icons.local_shipping_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final life = widget.life;
    final accent = widget.accent;
    return BlocBuilder<ReceiptsBloc, ReceiptsState>(
      builder: (context, state) {
        if (state.items.isEmpty &&
            (state.status == ReceiptsStatus.loading ||
                state.status == ReceiptsStatus.initial)) {
          return const NotesSkeleton();
        }
        if (state.items.isEmpty) {
          return EmptyState(
            accent: accent,
            title: "No slips in $life",
            message:
                'Scan QR on POS / delivery slips, or photo a handwritten one. Stays in this life only.',
            actionLabel: 'Scan slip',
            icon: Icons.qr_code_scanner_rounded,
            onAction: () => context.push('/desk/slips/scan'),
          );
        }
        return RefreshIndicator(
          color: accent,
          onRefresh: () async {
            final id = state.identityId ??
                context.read<IdentitiesBloc>().state.activeIdentityId;
            if (id == null) return;
            setState(() => _pullRefreshing = true);
            context
                .read<ReceiptsBloc>()
                .add(ReceiptsLoadRequested(identityId: id, force: true));
            await Future<void>.delayed(const Duration(milliseconds: 450));
            if (mounted) setState(() => _pullRefreshing = false);
          },
          child: SkeletonOverlay(
            enabled: _pullRefreshing,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                8,
                0,
                8,
                AppSpacing.listBottomInset(context),
              ),
              itemCount: state.items.length,
              itemBuilder: (context, index) {
                final r = state.items[index];
                final hasImg =
                    r.imagePath.isNotEmpty && File(r.imagePath).existsSync();
                return Dismissible(
                  key: ValueKey(r.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                  ),
                  confirmDismiss: (_) async {
                    return await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete slip?'),
                            content: Text(r.title),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        ) ??
                        false;
                  },
                  onDismissed: (_) {
                    context
                        .read<ReceiptsBloc>()
                        .add(ReceiptsDeleteRequested(r.id));
                  },
                  child: LifeListCell(
                    title: r.title,
                    subtitle: [
                      r.kind.labelZh,
                      if (r.merchant.isNotEmpty) r.merchant,
                      if (r.amountText.isNotEmpty) 'HK\$ ${r.amountText}',
                      if (r.qrPayload.isNotEmpty) 'QR',
                    ].join(' · '),
                    accent: accent,
                    leading: hasImg
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.file(
                              File(r.imagePath),
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              cacheWidth: 96,
                              filterQuality: FilterQuality.low,
                              errorBuilder: (context, error, stackTrace) => CircleAvatar(
                                radius: 24,
                                backgroundColor:
                                    accent.withValues(alpha: 0.12),
                                child: Icon(
                                  _iconFor(r.kind),
                                  color: accent,
                                  size: 22,
                                ),
                              ),
                            ),
                          )
                        : CircleAvatar(
                            radius: 24,
                            backgroundColor: accent.withValues(alpha: 0.12),
                            child: Icon(
                              _iconFor(r.kind),
                              color: accent,
                              size: 22,
                            ),
                          ),
                    onTap: () => _showDetail(context, r, accent),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _showDetail(
    BuildContext context,
    Receipt r,
    Color accent,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final hasImg =
            r.imagePath.isNotEmpty && File(r.imagePath).existsSync();
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            20 + MediaQuery.paddingOf(ctx).bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(r.title, style: AppType.titleMd()),
                const SizedBox(height: 6),
                Text(r.kind.labelZh, style: AppType.overline(color: accent)),
                if (r.merchant.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(r.merchant, style: AppType.bodySm()),
                ],
                if (r.amountText.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text('HK\$ ${r.amountText}', style: AppType.labelLg()),
                ],
                if (r.note.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(r.note, style: AppType.bodySm()),
                ],
                if (r.qrPayload.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('QR', style: AppType.overline()),
                  SelectableText(r.qrPayload, style: AppType.caption()),
                ],
                if (hasImg) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(File(r.imagePath), fit: BoxFit.cover, cacheWidth: 1200),
                  ),
                ],
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/desk/slips/scan');
                  },
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                  label: const Text('Scan another'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
