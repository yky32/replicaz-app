import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:replicaz/app/theme/app_colors.dart';
import 'package:replicaz/app/theme/app_spacing.dart';
import 'package:replicaz/core/widgets/ambient_background.dart';
import 'package:replicaz/core/widgets/empty_state.dart';
import 'package:replicaz/core/widgets/replicaz_bottom_sheet.dart';
import 'package:replicaz/core/widgets/screen_header.dart';
import 'package:replicaz/features/follow_ups/bloc/follow_ups_bloc.dart';
import 'package:replicaz/features/follow_ups/domain/follow_up.dart';
import 'package:replicaz/features/identities/bloc/identities_bloc.dart';

class FollowUpsScreen extends StatelessWidget {
  const FollowUpsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat.MMMd();
    final active = context.watch<IdentitiesBloc>().state.activeIdentity;

    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            children: [
              ScreenHeader(
                title: 'Follow-ups',
                subtitle: active == null ? null : 'In ${active.name}',
                subtitleColor: active?.color,
                leading: IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                ),
                actions: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _showCreateSheet(context),
                    icon: const Icon(Icons.add_task_rounded),
                    tooltip: 'Add follow-up',
                  ),
                ],
              ),
              Expanded(
                child: BlocBuilder<FollowUpsBloc, FollowUpsState>(
                  builder: (context, state) {
                    if (state.status == FollowUpsStatus.loading &&
                        state.items.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state.items.isEmpty) {
                      return EmptyState(
                        title: 'Nothing to follow up',
                        message:
                            'Track next steps that belong to this identity only.',
                        actionLabel: 'Add follow-up',
                        onAction: () => _showCreateSheet(context),
                      );
                    }
                    return ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        8,
                        16,
                        AppSpacing.listBottomInset(context),
                      ),
                      itemCount: state.items.length,
                      separatorBuilder: (_, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = state.items[index];
                        final done = item.status == FollowUpStatus.done;
                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: AppColors.hairline),
                          ),
                          tileColor: AppColors.surfaceRaised,
                          leading: Checkbox(
                            value: done,
                            activeColor: AppColors.accent,
                            onChanged: (_) => context
                                .read<FollowUpsBloc>()
                                .add(FollowUpsToggleRequested(item)),
                          ),
                          title: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                              decoration:
                                  done ? TextDecoration.lineThrough : null,
                              color: done
                                  ? AppColors.inkMuted
                                  : AppColors.ink,
                            ),
                          ),
                          subtitle: Text(
                            [
                              if (item.details.isNotEmpty) item.details,
                              if (item.dueAt != null)
                                'Due ${formatter.format(item.dueAt!.toLocal())}',
                            ].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: () => context
                                .read<FollowUpsBloc>()
                                .add(FollowUpsDeleteRequested(item.id)),
                            icon: const Icon(Icons.close, size: 18),
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

  Future<void> _showCreateSheet(BuildContext context) async {
    final title = TextEditingController();
    final details = TextEditingController();
    DateTime? dueAt;
    final bloc = context.read<FollowUpsBloc>();

    await ReplicazBottomSheet.show<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'New follow-up',
                    style: GoogleFonts.syne(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(hintText: 'Title'),
                    autofocus: true,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: details,
                    decoration: const InputDecoration(hintText: 'Details'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate:
                            DateTime.now().subtract(const Duration(days: 1)),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365 * 3)),
                        initialDate: dueAt ?? DateTime.now(),
                      );
                      if (picked != null) {
                        setModalState(() => dueAt = picked);
                      }
                    },
                    child: Text(
                      dueAt == null
                          ? 'Set due date'
                          : 'Due ${DateFormat.yMMMd().format(dueAt!)}',
                    ),
                  ),
                  const SizedBox(height: 16),
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
