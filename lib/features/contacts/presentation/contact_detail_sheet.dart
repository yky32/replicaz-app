import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:replicaz/app/theme/app_colors.dart';
import 'package:replicaz/app/theme/app_type.dart';
import 'package:replicaz/core/widgets/initials_avatar.dart';
import 'package:replicaz/core/widgets/replicaz_bottom_sheet.dart';
import 'package:replicaz/features/contacts/domain/contact.dart';
import 'package:replicaz/features/follow_ups/presentation/create_follow_up_sheet.dart';
import 'package:replicaz/features/messaging/bloc/conversations_bloc.dart';
import 'package:replicaz/features/messaging/domain/conversation.dart';

/// Lightweight person sheet (edit / follow-up / open chat).
Future<void> showContactDetailSheet(
  BuildContext context, {
  required Contact contact,
  required Color accent,
  required String lifeName,
}) async {
  final chats = context.read<ConversationsBloc>().state.conversations;
  Conversation? room;
  final key = contact.name.trim().toLowerCase();
  for (final c in chats) {
    final t = c.title?.trim().toLowerCase();
    if (t != null && t == key) {
      room = c;
      break;
    }
  }

  await ReplicazBottomSheet.show<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            4,
            20,
            16 + MediaQuery.paddingOf(sheetContext).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  InitialsAvatar(
                    label: contact.name,
                    color: accent,
                    size: 52,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(contact.name, style: AppType.titleMd()),
                        Text(
                          'In $lifeName',
                          style: AppType.overline(color: accent),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (contact.company.isNotEmpty ||
                  contact.email.isNotEmpty ||
                  contact.phone.isNotEmpty ||
                  contact.notes.isNotEmpty) ...[
                const SizedBox(height: 14),
                if (contact.company.isNotEmpty)
                  _line(Icons.apartment_rounded, contact.company),
                if (contact.email.isNotEmpty)
                  _line(Icons.mail_outline_rounded, contact.email),
                if (contact.phone.isNotEmpty)
                  _line(Icons.phone_outlined, contact.phone),
                if (contact.notes.isNotEmpty)
                  _line(Icons.notes_rounded, contact.notes),
              ],
              const SizedBox(height: 18),
              if (room != null) ...[
                FilledButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    final id = room!.id;
                    Navigator.pop(sheetContext);
                    context.push(
                      '/messages/$id',
                      extra: <String, String?>{'title': contact.name},
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: const Text('Open chat'),
                ),
                const SizedBox(height: 8),
              ],
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  showCreateFollowUpSheet(
                    context,
                    initialTitle: 'Follow up · ${contact.name}',
                    contactName: contact.name,
                  );
                },
                icon: const Icon(Icons.add_task_rounded, size: 18),
                label: const Text('Add follow-up'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  context.push('/contacts/${contact.id}/edit');
                },
                child: const Text('Edit person'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _line(IconData icon, String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.inkMuted),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: AppType.bodySm())),
      ],
    ),
  );
}
