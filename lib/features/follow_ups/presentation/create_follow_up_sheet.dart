import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:replicaz/app/theme/app_type.dart';
import 'package:replicaz/core/widgets/replicaz_bottom_sheet.dart';
import 'package:replicaz/features/follow_ups/bloc/follow_ups_bloc.dart';

/// Shared create-follow-up sheet (Desk + Thread).
Future<void> showCreateFollowUpSheet(
  BuildContext context, {
  String initialTitle = '',
  String contactName = '',
  String initialDetails = '',
}) async {
  final title = TextEditingController(text: initialTitle);
  final details = TextEditingController(text: initialDetails);
  DateTime? dueAt = DateTime.now().add(const Duration(days: 1));
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
                if (contactName.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'With $contactName',
                    style: AppType.caption(),
                  ),
                ],
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
                  decoration:
                      const InputDecoration(hintText: 'Details (optional)'),
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
                        contactName: contactName,
                        dueAt: dueAt,
                      ),
                    );
                    Navigator.pop(sheetContext);
                    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                      SnackBar(
                        content: Text(
                          contactName.isEmpty
                              ? 'Follow-up added'
                              : 'Follow-up for $contactName',
                        ),
                      ),
                    );
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
