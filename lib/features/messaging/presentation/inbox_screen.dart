import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:replicaz/app/theme/app_colors.dart';
import 'package:replicaz/app/theme/app_spacing.dart';
import 'package:replicaz/core/bootstrap/app_bootstrap.dart';
import 'package:replicaz/core/config/app_config.dart';
import 'package:replicaz/core/widgets/ambient_background.dart';
import 'package:replicaz/core/widgets/empty_state.dart';
import 'package:replicaz/core/widgets/initials_avatar.dart';
import 'package:replicaz/core/widgets/replicaz_bottom_sheet.dart';
import 'package:replicaz/core/widgets/screen_header.dart';
import 'package:replicaz/features/auth/bloc/auth_bloc.dart';
import 'package:replicaz/features/identities/bloc/identities_bloc.dart';
import 'package:replicaz/features/messaging/bloc/conversations_bloc.dart';
import 'package:replicaz/features/messaging/data/remote_messaging_api.dart';
import 'package:replicaz/features/messaging/domain/conversation.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final time = DateFormat.jm();
    final day = DateFormat.MMMd();
    final active = context.watch<IdentitiesBloc>().state.activeIdentity;

    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ScreenHeader(
                title: 'Chats',
                subtitle: active == null ? null : 'Speaking as ${active.name}',
                subtitleColor: active?.color,
                actions: [
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, auth) {
                      return IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: !auth.isAuthenticated
                            ? null
                            : () => _startChat(context, auth.user!.id),
                        icon: const Icon(Icons.edit_square),
                        tooltip: 'New chat',
                      );
                    },
                  ),
                ],
              ),
              Expanded(
                child: BlocBuilder<ConversationsBloc, ConversationsState>(
                  builder: (context, state) {
                    if (state.status == ConversationsStatus.loading &&
                        state.conversations.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state.conversations.isEmpty) {
                      return BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, auth) {
                          return EmptyState(
                            title: 'No chats yet',
                            message: AppConfig.useRemoteBackend
                                ? 'Create a room with another local user (Alice ↔ Bob).'
                                : 'Start a thread in this identity. Your other lives stay out of the way.',
                            actionLabel: 'New chat',
                            icon: Icons.forum_outlined,
                            onAction: !auth.isAuthenticated
                                ? null
                                : () => _startChat(context, auth.user!.id),
                          );
                        },
                      );
                    }
                    return ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                        8,
                        0,
                        8,
                        AppSpacing.listBottomInset(context),
                      ),
                      itemCount: state.conversations.length,
                      itemBuilder: (context, index) {
                        final c = state.conversations[index];
                        return _ChatRow(
                          conversation: c,
                          accent: active?.color ?? AppColors.accent,
                          timeLabel: c.lastMessageAt == null
                              ? ''
                              : _formatStamp(c.lastMessageAt!, time, day),
                          onTap: () => context.push('/messages/${c.id}'),
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

  String _formatStamp(DateTime at, DateFormat time, DateFormat day) {
    final local = at.toLocal();
    final now = DateTime.now();
    final sameDay = local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    return sameDay ? time.format(local) : day.format(local);
  }

  Future<void> _startChat(BuildContext context, String userId) async {
    if (!AppConfig.useRemoteBackend) {
      context.read<ConversationsBloc>().add(
            ConversationsCreateRequested(userId: userId),
          );
      return;
    }

    List<RemoteUser> users = const [];
    try {
      users = await AppBootstrap.messagingService.listUsers();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load users: $e')),
        );
      }
      return;
    }

    if (!context.mounted) return;
    if (users.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No other users yet — log in Alice on one sim, Bob on the other.'),
        ),
      );
      return;
    }

    await ReplicazBottomSheet.show<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'New chat',
                  style: GoogleFonts.syne(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pick who to message on this local stack.',
                  style: GoogleFonts.plusJakartaSans(color: AppColors.inkMuted),
                ),
                const SizedBox(height: 12),
                ...users.map(
                  (u) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: InitialsAvatar(
                      label: u.displayName,
                      color: AppColors.accent,
                      size: 42,
                    ),
                    title: Text(
                      u.displayName,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(u.email),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      context.read<ConversationsBloc>().add(
                            ConversationsCreateRequested(
                              userId: userId,
                              participantUserId: u.id,
                              title: u.displayName,
                            ),
                          );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ChatRow extends StatelessWidget {
  const _ChatRow({
    required this.conversation,
    required this.accent,
    required this.timeLabel,
    required this.onTap,
  });

  final Conversation conversation;
  final Color accent;
  final String timeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = conversation.title?.isNotEmpty == true
        ? conversation.title!
        : 'Chat';
    final preview = conversation.lastMessageAt == null
        ? 'No messages yet'
        : 'Open thread';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              InitialsAvatar(label: title, color: accent, size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (timeLabel.isNotEmpty)
                          Text(
                            timeLabel,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.inkMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.inkMuted,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
