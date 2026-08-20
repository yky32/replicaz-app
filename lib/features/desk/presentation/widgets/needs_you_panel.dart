import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:replicaz/app/theme/app_colors.dart';
import 'package:replicaz/app/theme/app_type.dart';
import 'package:replicaz/features/follow_ups/bloc/follow_ups_bloc.dart';
import 'package:replicaz/features/follow_ups/domain/follow_up.dart';
import 'package:replicaz/features/messaging/bloc/conversations_bloc.dart';
import 'package:replicaz/features/messaging/domain/conversation.dart';

/// Slasher "今日要回" — open loops for the active life only.
class NeedsYouPanel extends StatelessWidget {
  const NeedsYouPanel({
    super.key,
    required this.lifeName,
    required this.accent,
    required this.onOpenFollowUps,
  });

  final String lifeName;
  final Color accent;
  final VoidCallback onOpenFollowUps;

  @override
  Widget build(BuildContext context) {
    final chats = context.watch<ConversationsBloc>().state.conversations;
    final fus = context.watch<FollowUpsBloc>().state.items;

    final unreadChats = chats.where((c) => c.unreadCount > 0).toList()
      ..sort((a, b) {
        final at = a.lastMessageAt ?? a.updatedAt;
        final bt = b.lastMessageAt ?? b.updatedAt;
        return bt.compareTo(at);
      });
    final unreadTotal =
        unreadChats.fold<int>(0, (n, c) => n + c.unreadCount);

    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final openFus = fus.where((e) => e.status == FollowUpStatus.open).toList();
    final overdue = openFus.where((e) {
      final d = e.dueAt;
      if (d == null) return false;
      return d.toLocal().isBefore(now);
    }).toList();
    final dueToday = openFus.where((e) {
      final d = e.dueAt;
      if (d == null) return false;
      final local = d.toLocal();
      return !local.isBefore(DateTime(now.year, now.month, now.day)) &&
          !local.isAfter(todayEnd);
    }).toList();

    final hasAnything =
        unreadTotal > 0 || overdue.isNotEmpty || dueToday.isNotEmpty;
    if (!hasAnything) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, color: accent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Clear in $lifeName — no unread chats or due follow-ups.',
                  style: AppType.bodySm(color: AppColors.inkSoft),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.hairline),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
              child: Row(
                children: [
                  Text('Needs you', style: AppType.titleSm()),
                  const SizedBox(width: 8),
                  Text(
                    lifeName,
                    style: AppType.overline(color: accent),
                  ),
                ],
              ),
            ),
            if (unreadTotal > 0)
              _row(
                icon: Icons.mark_chat_unread_outlined,
                color: accent,
                title: unreadTotal == 1
                    ? '1 unread message'
                    : '$unreadTotal unread across ${unreadChats.length} chats',
                subtitle: unreadChats.first.title?.isNotEmpty == true
                    ? unreadChats.first.title
                    : 'Open chats',
                onTap: () {
                  final c = unreadChats.first;
                  context.push(
                    '/messages/${c.id}',
                    extra: <String, String?>{'title': c.title},
                  );
                },
              ),
            if (overdue.isNotEmpty)
              _row(
                icon: Icons.priority_high_rounded,
                color: AppColors.danger,
                title: overdue.length == 1
                    ? '1 overdue follow-up'
                    : '${overdue.length} overdue follow-ups',
                subtitle: overdue.first.title,
                onTap: onOpenFollowUps,
              ),
            if (dueToday.isNotEmpty)
              _row(
                icon: Icons.event_available_rounded,
                color: AppColors.identityPersonal,
                title: dueToday.length == 1
                    ? 'Due today'
                    : '${dueToday.length} due today',
                subtitle: dueToday.first.title,
                onTap: onOpenFollowUps,
              ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Widget _row({
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppType.labelMd()),
                    if (subtitle != null && subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.caption(),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Conversation titles not yet in Circle for this life.
List<Conversation> circleSuggestionsFromChats({
  required List<Conversation> chats,
  required List<String> existingContactNamesLower,
}) {
  final seen = <String>{};
  final out = <Conversation>[];
  for (final c in chats) {
    final title = c.title?.trim() ?? '';
    if (title.isEmpty) continue;
    final key = title.toLowerCase();
    if (existingContactNamesLower.contains(key)) continue;
    if (seen.contains(key)) continue;
    seen.add(key);
    out.add(c);
    if (out.length >= 5) break;
  }
  return out;
}
