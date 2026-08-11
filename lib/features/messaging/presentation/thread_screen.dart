import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:replicaz/app/theme/app_colors.dart';
import 'package:replicaz/core/config/app_config.dart';
import 'package:replicaz/core/widgets/ambient_background.dart';
import 'package:replicaz/core/widgets/initials_avatar.dart';
import 'package:replicaz/core/widgets/message_bubble.dart';
import 'package:replicaz/features/auth/bloc/auth_bloc.dart';
import 'package:replicaz/features/identities/bloc/identities_bloc.dart';
import 'package:replicaz/features/messaging/bloc/conversations_bloc.dart';
import 'package:replicaz/features/messaging/bloc/thread_bloc.dart';
import 'package:replicaz/features/messaging/domain/chat_message.dart';
import 'package:replicaz/features/messaging/domain/conversation.dart';

class ThreadScreen extends StatelessWidget {
  const ThreadScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final identityId =
            context.read<IdentitiesBloc>().state.activeIdentityId ?? '';
        return ThreadBloc(conversationId: conversationId)
          ..add(ThreadLoadRequested(identityId: identityId));
      },
      child: _ThreadView(conversationId: conversationId),
    );
  }
}

class _ThreadView extends StatefulWidget {
  const _ThreadView({required this.conversationId});

  final String conversationId;

  @override
  State<_ThreadView> createState() => _ThreadViewState();
}

class _ThreadViewState extends State<_ThreadView> with WidgetsBindingObserver {
  final _composer = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<ThreadBloc>().add(const ThreadReconnectRequested());
    }
  }

  void _bumpInbox({String? preview}) {
    final at = DateTime.now().toUtc();
    if (preview != null && preview.isNotEmpty) {
      context.read<ConversationsBloc>().add(
            ConversationsPreviewUpdated(
              conversationId: widget.conversationId,
              preview: preview,
              at: at,
            ),
          );
    } else {
      context.read<ConversationsBloc>().add(
            const ConversationsRefreshRequested(),
          );
    }
  }

  void _leave() {
    context.read<ConversationsBloc>().add(
          const ConversationsRefreshRequested(),
        );
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.user;
    final active = context.watch<IdentitiesBloc>().state.activeIdentity;
    final conversations =
        context.watch<ConversationsBloc>().state.conversations;
    Conversation? conversation;
    for (final c in conversations) {
      if (c.id == widget.conversationId) {
        conversation = c;
        break;
      }
    }
    final title =
        conversation?.title?.isNotEmpty == true ? conversation!.title! : 'Chat';
    final formatter = DateFormat.jm();

    return Scaffold(
      body: AmbientBackground(
        intense: true,
        child: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _leave,
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    ),
                    InitialsAvatar(
                      label: title,
                      color: active?.color ?? AppColors.accent,
                      size: 40,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 16.5,
                            ),
                          ),
                          if (active != null)
                            Text(
                              active.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: active.color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            BlocBuilder<ThreadBloc, ThreadState>(
              buildWhen: (p, c) => p.connection != c.connection,
              builder: (context, state) {
                if (!AppConfig.useRemoteBackend || !state.showConnectionBanner) {
                  return const SizedBox.shrink();
                }
                return _ConnectionBanner(
                  connection: state.connection,
                  onRetry: () => context
                      .read<ThreadBloc>()
                      .add(const ThreadReconnectRequested()),
                );
              },
            ),
            Expanded(
              child: BlocConsumer<ThreadBloc, ThreadState>(
                listenWhen: (p, c) =>
                    p.messages.length != c.messages.length ||
                    p.lastInboundAt != c.lastInboundAt ||
                    (p.sending && !c.sending && c.sendError == null),
                listener: (context, state) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!_scroll.hasClients) return;
                    _scroll.animateTo(
                      _scroll.position.maxScrollExtent + 80,
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOut,
                    );
                  });
                  // Inbox: preview on successful send / inbound WS.
                  if (state.messages.isNotEmpty) {
                    final last = state.messages.last;
                    if (last.deliveryStatus != MessageDeliveryStatus.failed &&
                        last.deliveryStatus != MessageDeliveryStatus.pending) {
                      _bumpInbox(preview: last.body);
                    } else if (state.lastInboundAt != null) {
                      _bumpInbox(preview: last.body);
                    }
                  }
                },
                builder: (context, state) {
                  if (state.status == ThreadStatus.loading &&
                      state.messages.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.status == ThreadStatus.failure &&
                      state.messages.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              state.errorMessage ?? 'Could not load messages',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.inkMuted,
                                height: 1.45,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () {
                                final identityId = context
                                        .read<IdentitiesBloc>()
                                        .state
                                        .activeIdentityId ??
                                    '';
                                context.read<ThreadBloc>().add(
                                      ThreadLoadRequested(
                                        identityId: identityId,
                                      ),
                                    );
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  if (state.messages.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'Write the first message.\nIt stays in this identity.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.inkMuted,
                            height: 1.45,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      final msg = state.messages[index];
                      final mine = msg.senderUserId == user?.id ||
                          msg.senderUserId == user?.alias ||
                          msg.senderUserId == user?.displayName;
                      final showTail = index == state.messages.length - 1 ||
                          state.messages[index + 1].senderUserId !=
                              msg.senderUserId;
                      return MessageBubble(
                        body: msg.body,
                        mine: mine,
                        showTail: showTail,
                        timeLabel: formatter.format(msg.createdAt.toLocal()),
                        deliveryStatus: msg.deliveryStatus,
                        onRetry: () => context.read<ThreadBloc>().add(
                              ThreadRetrySendRequested(msg.clientMessageId),
                            ),
                      );
                    },
                  );
                },
              ),
            ),
            BlocBuilder<ThreadBloc, ThreadState>(
              buildWhen: (p, c) =>
                  p.sending != c.sending || p.sendError != c.sendError,
              builder: (context, state) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (state.sendError != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                        child: Text(
                          state.sendError!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.redAccent.shade200,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    _ComposerBar(
                      controller: _composer,
                      sending: state.sending,
                      onSend: () {
                        final body = _composer.text.trim();
                        if (body.isEmpty || user == null || active == null) {
                          return;
                        }
                        context.read<ThreadBloc>().add(
                              ThreadSendRequested(
                                senderUserId: user.alias.isNotEmpty
                                    ? user.alias
                                    : user.id,
                                senderIdentityId: active.id,
                                body: body,
                              ),
                            );
                        _composer.clear();
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({
    required this.connection,
    required this.onRetry,
  });

  final ThreadConnectionStatus connection;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final failed = connection == ThreadConnectionStatus.failed;
    final label = switch (connection) {
      ThreadConnectionStatus.connecting => 'Connecting…',
      ThreadConnectionStatus.reconnecting => 'Reconnecting…',
      ThreadConnectionStatus.failed => 'Realtime offline',
      _ => '',
    };
    if (label.isEmpty) return const SizedBox.shrink();

    return Material(
      color: failed
          ? Colors.redAccent.withValues(alpha: 0.12)
          : AppColors.accent.withValues(alpha: 0.12),
      child: InkWell(
        onTap: failed ? onRetry : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              if (!failed)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  Icons.wifi_off_rounded,
                  size: 16,
                  color: Colors.redAccent.shade200,
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  failed ? '$label · Tap to retry' : label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: failed ? Colors.redAccent.shade200 : AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComposerBar extends StatelessWidget {
  const _ComposerBar({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ink.withValues(alpha: 0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Message',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: AppColors.inkMuted,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: AppColors.ink,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: sending ? null : onSend,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: sending
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.arrow_upward_rounded,
                          color: Colors.white,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
