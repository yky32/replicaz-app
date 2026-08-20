import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:replicaz/app/theme/app_colors.dart';
import 'package:replicaz/app/theme/app_type.dart';
import 'package:replicaz/core/widgets/initials_avatar.dart';
import 'package:replicaz/core/widgets/replicaz_bottom_sheet.dart';
import 'package:replicaz/features/contacts/domain/contact.dart';
import 'package:replicaz/features/follow_ups/bloc/follow_ups_bloc.dart';
import 'package:replicaz/features/follow_ups/domain/follow_up.dart';
import 'package:replicaz/features/follow_ups/presentation/create_follow_up_sheet.dart';
import 'package:replicaz/features/messaging/bloc/conversations_bloc.dart';
import 'package:replicaz/features/messaging/domain/conversation.dart';
import 'package:replicaz/features/notes/bloc/notes_bloc.dart';

/// Person hub: chat · follow-ups · related notes · edit.
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

  final relatedFu = context
      .read<FollowUpsBloc>()
      .state
      .items
      .where(
        (e) =>
            e.contactName.trim().toLowerCase() == key ||
            e.title.toLowerCase().contains(key),
      )
      .take(5)
      .toList();

  final relatedNotes = context
      .read<NotesBloc>()
      .state
      .notes
      .where(
        (e) =>
            e.title.toLowerCase().contains(key) ||
            e.body.toLowerCase().contains(key),
      )
      .take(5)
      .toList();

  await ReplicazBottomSheet.show<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      return SafeArea(
        child: SingleChildScrollView(
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
                  _line(Icons.sticky_note_2_outlined, contact.notes),
              ],
              if (relatedFu.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Follow-ups', style: AppType.labelLg()),
                const SizedBox(height: 8),
                ...relatedFu.map(
                  (fu) => _RelatedTile(
                    icon: fu.status == FollowUpStatus.open
                        ? Icons.circle_outlined
                        : Icons.check_circle_rounded,
                    color: accent,
                    title: fu.title,
                    subtitle: fu.status == FollowUpStatus.open ? 'Open' : 'Done',
                    onTap: () {
                      Navigator.pop(sheetContext);
                      context.go('/desk');
                    },
                  ),
                ),
              ],
              if (relatedNotes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Notes', style: AppType.labelLg()),
                const SizedBox(height: 8),
                ...relatedNotes.map(
                  (n) => _RelatedTile(
                    icon: Icons.sticky_note_2_outlined,
                    color: accent,
                    title: n.title,
                    subtitle: n.body.trim().isEmpty
                        ? 'No body'
                        : n.body.trim().replaceAll('\n', ' '),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      context.push('/desk/notes/${n.id}/edit');
                    },
                  ),
                ),
              ],
              if (relatedFu.isEmpty && relatedNotes.isEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  'No linked follow-ups or notes yet — add one below.',
                  style: AppType.caption(),
                ),
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
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  context.push(
                    '/desk/notes/new',
                    // title prefill via query if note form supports later
                  );
                },
                icon: const Icon(Icons.note_add_rounded, size: 18),
                label: const Text('New note'),
              ),
              const SizedBox(height: 4),
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

class _RelatedTile extends StatelessWidget {
  const _RelatedTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.labelMd(),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.caption(),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
