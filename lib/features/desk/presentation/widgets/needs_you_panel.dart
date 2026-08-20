import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:replicaz/app/theme/app_colors.dart';
import 'package:replicaz/app/theme/app_type.dart';
import 'package:replicaz/core/bootstrap/app_bootstrap.dart';
import 'package:replicaz/core/constants/storage_keys.dart';
import 'package:replicaz/features/follow_ups/bloc/follow_ups_bloc.dart';
import 'package:replicaz/features/follow_ups/domain/follow_up.dart';
import 'package:replicaz/features/messaging/bloc/conversations_bloc.dart';
import 'package:replicaz/features/messaging/domain/conversation.dart';

/// Full panel (Desk).
class NeedsYouPanel extends StatelessWidget {
  const NeedsYouPanel({
    super.key,
    required this.lifeName,
    required this.accent,
    required this.onOpenFollowUps,
    this.compact = false,
  });

  final String lifeName;
  final Color accent;
  final VoidCallback onOpenFollowUps;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final chats = context.watch<ConversationsBloc>().state.conversations;
    final fus = context.watch<FollowUpsBloc>().state.items;
    final summary = NeedsYouSummary.from(chats: chats, followUps: fus);

    if (compact) {
      return _NeedsYouMini(
        lifeName: lifeName,
        accent: accent,
        summary: summary,
        onOpenFollowUps: onOpenFollowUps,
      );
    }

    if (!summary.hasAnything) {
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
                  Text(lifeName, style: AppType.overline(color: accent)),
                ],
              ),
            ),
            if (summary.unreadTotal > 0)
              _row(
                icon: Icons.mark_chat_unread_outlined,
                color: accent,
                title: summary.unreadTotal == 1
                    ? '1 unread message'
                    : '${summary.unreadTotal} unread across ${summary.unreadChats.length} chats',
                subtitle: summary.unreadChats.first.title,
                onTap: () {
                  final c = summary.unreadChats.first;
                  context.push(
                    '/messages/${c.id}',
                    extra: <String, String?>{'title': c.title},
                  );
                },
              ),
            if (summary.overdue.isNotEmpty)
              _row(
                icon: Icons.priority_high_rounded,
                color: AppColors.danger,
                title: summary.overdue.length == 1
                    ? '1 overdue follow-up'
                    : '${summary.overdue.length} overdue follow-ups',
                subtitle: summary.overdue.first.title,
                onTap: onOpenFollowUps,
              ),
            if (summary.dueToday.isNotEmpty)
              _row(
                icon: Icons.event_available_rounded,
                color: AppColors.identityPersonal,
                title: summary.dueToday.length == 1
                    ? 'Due today'
                    : '${summary.dueToday.length} due today',
                subtitle: summary.dueToday.first.title,
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
              const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _NeedsYouMini extends StatelessWidget {
  const _NeedsYouMini({
    required this.lifeName,
    required this.accent,
    required this.summary,
    required this.onOpenFollowUps,
  });

  final String lifeName;
  final Color accent;
  final NeedsYouSummary summary;
  final VoidCallback onOpenFollowUps;

  @override
  Widget build(BuildContext context) {
    if (!summary.hasAnything) return const SizedBox.shrink();

    final parts = <String>[];
    if (summary.unreadTotal > 0) {
      parts.add('${summary.unreadTotal} unread');
    }
    if (summary.overdue.isNotEmpty) {
      parts.add('${summary.overdue.length} overdue');
    } else if (summary.dueToday.isNotEmpty) {
      parts.add('${summary.dueToday.length} due today');
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            if (summary.unreadTotal > 0) {
              final c = summary.unreadChats.first;
              context.push(
                '/messages/${c.id}',
                extra: <String, String?>{'title': c.title},
              );
            } else {
              onOpenFollowUps();
            }
          },
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [
                  accent.withValues(alpha: 0.14),
                  accent.withValues(alpha: 0.05),
                ],
              ),
              border: Border.all(color: accent.withValues(alpha: 0.28)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.bolt_rounded, size: 18, color: accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Needs you · ${parts.join(' · ')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.labelMd(color: AppColors.ink),
                    ),
                  ),
                  Text(
                    lifeName,
                    style: AppType.overline(color: accent),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NeedsYouSummary {
  NeedsYouSummary({
    required this.unreadChats,
    required this.overdue,
    required this.dueToday,
  });

  final List<Conversation> unreadChats;
  final List<FollowUp> overdue;
  final List<FollowUp> dueToday;

  int get unreadTotal =>
      unreadChats.fold<int>(0, (n, c) => n + c.unreadCount);

  bool get hasAnything =>
      unreadTotal > 0 || overdue.isNotEmpty || dueToday.isNotEmpty;

  factory NeedsYouSummary.from({
    required List<Conversation> chats,
    required List<FollowUp> followUps,
  }) {
    final unreadChats = chats.where((c) => c.unreadCount > 0).toList()
      ..sort((a, b) {
        final at = a.lastMessageAt ?? a.updatedAt;
        final bt = b.lastMessageAt ?? b.updatedAt;
        return bt.compareTo(at);
      });

    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final open = followUps.where((e) => e.status == FollowUpStatus.open);
    final overdue = open.where((e) {
      final d = e.dueAt;
      return d != null && d.toLocal().isBefore(dayStart);
    }).toList();
    final dueToday = open.where((e) {
      final d = e.dueAt?.toLocal();
      if (d == null) return false;
      return !d.isBefore(dayStart) && d.isBefore(dayEnd);
    }).toList();

    return NeedsYouSummary(
      unreadChats: unreadChats,
      overdue: overdue,
      dueToday: dueToday,
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

// --- Life Focus (local) ----------------------------------------------------

abstract final class LifeFocusStore {
  static String? get identityId =>
      AppBootstrap.store.getString(StorageKeys.lifeFocusIdentityId);

  static DateTime? get until {
    final raw = AppBootstrap.store.getString(StorageKeys.lifeFocusUntil);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  static bool get isActive {
    final id = identityId;
    final end = until;
    if (id == null || id.isEmpty || end == null) return false;
    return end.isAfter(DateTime.now());
  }

  static Future<void> start({
    required String identityId,
    required Duration duration,
  }) async {
    final end = DateTime.now().add(duration);
    await AppBootstrap.store.setString(StorageKeys.lifeFocusIdentityId, identityId);
    await AppBootstrap.store.setString(
      StorageKeys.lifeFocusUntil,
      end.toIso8601String(),
    );
  }

  static Future<void> clear() async {
    await AppBootstrap.store.remove(StorageKeys.lifeFocusIdentityId);
    await AppBootstrap.store.remove(StorageKeys.lifeFocusUntil);
  }
}
