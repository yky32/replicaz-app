import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:replicaz/app/theme/app_type.dart';
import 'package:replicaz/core/widgets/replicaz_bottom_sheet.dart';
import 'package:replicaz/features/follow_ups/presentation/create_follow_up_sheet.dart';
import 'package:replicaz/features/messaging/bloc/conversations_bloc.dart';
import 'package:replicaz/features/messaging/domain/conversation.dart';

/// Long-press actions on a chat row (slasher shortcuts).
Future<void> showChatActionsSheet(
  BuildContext context, {
  required Conversation conversation,
}) async {
  final title = conversation.title?.trim().isNotEmpty == true
      ? conversation.title!.trim()
      : 'Chat';

  await ReplicazBottomSheet.show<void>(
    context: context,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            4,
            20,
            12 + MediaQuery.paddingOf(sheetContext).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: AppType.titleMd()),
              const SizedBox(height: 4),
              Text(
                'Quick actions · stays in this life',
                style: AppType.caption(),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.chat_bubble_outline_rounded),
                title: const Text('Open chat'),
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.pop(sheetContext);
                  context.read<ConversationsBloc>().add(
                        ConversationsMarkReadRequested(conversation.id),
                      );
                  context.push(
                    '/messages/${conversation.id}',
                    extra: <String, String?>{'title': conversation.title},
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.add_task_rounded),
                title: const Text('Add follow-up'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  showCreateFollowUpSheet(
                    context,
                    initialTitle: 'Reply $title',
                    contactName: title == 'Chat' ? '' : title,
                    initialDetails: 'From chat list',
                  );
                },
              ),
              if (title != 'Chat')
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_add_alt_1_rounded),
                  title: const Text('Add to Circle'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.push(
                      '/contacts/new?name=${Uri.encodeComponent(title)}',
                    );
                  },
                ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.visibility_off_outlined),
                title: const Text('Hide chat'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Hide chat?'),
                          content: const Text(
                            'Removes it from this device inbox.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Hide'),
                            ),
                          ],
                        ),
                      ) ??
                      false;
                  if (ok && context.mounted) {
                    context.read<ConversationsBloc>().add(
                          ConversationsLeaveRequested(conversation.id),
                        );
                  }
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
