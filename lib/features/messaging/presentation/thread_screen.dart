import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:replicaz/app/theme/app_colors.dart';
import 'package:replicaz/core/config/app_config.dart';
import 'package:replicaz/core/widgets/skeletons/replicaz_skeletons.dart';
import 'package:replicaz/core/widgets/ambient_background.dart';
import 'package:replicaz/core/widgets/initials_avatar.dart';
import 'package:replicaz/core/widgets/message_bubble.dart';
import 'package:replicaz/features/auth/bloc/auth_bloc.dart';
import 'package:replicaz/features/identities/bloc/identities_bloc.dart';
import 'package:replicaz/features/messaging/bloc/conversations_bloc.dart';
import 'package:replicaz/features/messaging/bloc/thread_bloc.dart';
import 'package:replicaz/features/messaging/domain/chat_message.dart';

class ThreadScreen extends StatelessWidget {
  const ThreadScreen({
    super.key,
    required this.conversationId,
    this.title,
  });

  final String conversationId;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final identityId =
            context.read<IdentitiesBloc>().state.activeIdentityId ?? '';
        return ThreadBloc(conversationId: conversationId)
          ..add(ThreadLoadRequested(identityId: identityId));
      },
      child: _ThreadView(
        conversationId: conversationId,
        initialTitle: title,
      ),
    );
  }
}

class _ThreadView extends StatefulWidget {
  const _ThreadView({
    required this.conversationId,
    this.initialTitle,
  });

  final String conversationId;
  final String? initialTitle;

  @override
  State<_ThreadView> createState() => _ThreadViewState();
}

class _ThreadViewState extends State<_ThreadView> with WidgetsBindingObserver {
  final _composer = TextEditingController();
  final _scroll = ScrollController();

  /// First messages paint: jumpTo (no animate) — avoids open-room shake.
  bool _didInitialScroll = false;
  bool _seededIdentity = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ConversationsBloc>().add(
            ConversationsMarkReadRequested(widget.conversationId),
          );
    });
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

  void _scrollToBottom({required bool animated}) {
    if (!_scroll.hasClients) return;
    final target = _scroll.position.maxScrollExtent;
    if (target <= 0) {
      _didInitialScroll = true;
      return;
    }
    if (!animated || !_didInitialScroll) {
      _scroll.jumpTo(target);
      _didInitialScroll = true;
      return;
    }
    _scroll.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  void _bumpInbox({String? preview, bool fromSelf = false}) {
    final at = DateTime.now().toUtc();
    if (preview != null && preview.isNotEmpty) {
      context.read<ConversationsBloc>().add(
            ConversationsPreviewUpdated(
              conversationId: widget.conversationId,
              preview: preview,
              at: at,
              fromSelf: fromSelf,
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
          ConversationsMarkReadRequested(widget.conversationId),
        );
    Navigator.of(context).maybePop();
  }

  void _onComposerChanged(String value) {
    context.read<ThreadBloc>().add(
          ThreadTypingLocalChanged(value.trim().isNotEmpty),
        );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.user;
    final active = context.watch<IdentitiesBloc>().state.activeIdentity;
    final activeId = active?.id ?? '';

    // Keep ThreadBloc in sync when user switches life while open.
    return BlocListener<IdentitiesBloc, IdentitiesState>(
      listenWhen: (p, c) => p.activeIdentityId != c.activeIdentityId,
      listener: (context, state) {
        final id = state.activeIdentityId ?? '';
        context.read<ThreadBloc>().add(ThreadActiveIdentityChanged(id));
      },
      child: Builder(
        builder: (context) {
          // Seed identity once — not every rebuild (was thrashing open).
          if (!_seededIdentity &&
              activeId.isNotEmpty &&
              context.read<ThreadBloc>().state.activeIdentityId != activeId) {
            _seededIdentity = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                context
                    .read<ThreadBloc>()
                    .add(ThreadActiveIdentityChanged(activeId));
              }
            });
          }

          // Route title only — watching ConversationsBloc shook the shell
          // when mark-read rebuilt the inbox behind this route.
          final title = (widget.initialTitle?.isNotEmpty == true)
              ? widget.initialTitle!
              : 'Chat';
          final formatter = DateFormat.jm();

          return Scaffold(
            resizeToAvoidBottomInset: true,
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
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18,
                            ),
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
                                BlocBuilder<ThreadBloc, ThreadState>(
                                  buildWhen: (p, c) =>
                                      p.peerTyping != c.peerTyping ||
                                      p.activeIdentityId !=
                                          c.activeIdentityId,
                                  builder: (context, tState) {
                                    if (tState.peerTyping) {
                                      return Text(
                                        'typing…',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color: AppColors.accent,
                                          fontWeight: FontWeight.w600,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      );
                                    }
                                    if (active != null) {
                                      return Text(
                                        active.name,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color: active.color,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  BlocBuilder<ThreadBloc, ThreadState>(
                    buildWhen: (p, c) =>
                        p.connection != c.connection ||
                        p.identityMismatch != c.identityMismatch,
                    builder: (context, state) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (AppConfig.effectiveRemoteBackend &&
                              state.showConnectionBanner)
                            _ConnectionBanner(
                              connection: state.connection,
                              onRetry: () => context.read<ThreadBloc>().add(
                                    const ThreadReconnectRequested(),
                                  ),
                            ),
                          if (state.identityMismatch)
                            Material(
                              color: Colors.orange.withValues(alpha: 0.14),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.switch_account_rounded,
                                      size: 18,
                                      color: Colors.orange.shade800,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'This chat belongs to another life. Switch identity to send.',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.orange.shade900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
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
                        final isFirstPaint = !_didInitialScroll;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          _scrollToBottom(animated: !isFirstPaint);
                        });
                        // First open: mark read only — no inbox preview thrash.
                        if (isFirstPaint) {
                          context.read<ConversationsBloc>().add(
                                ConversationsMarkReadRequested(
                                  widget.conversationId,
                                ),
                              );
                          return;
                        }
                        if (state.messages.isNotEmpty) {
                          final last = state.messages.last;
                          final mine = last.senderUserId == user?.id ||
                              last.senderUserId == user?.alias ||
                              last.senderUserId == user?.displayName;
                          if (last.deliveryStatus !=
                                  MessageDeliveryStatus.failed &&
                              last.deliveryStatus !=
                                  MessageDeliveryStatus.pending) {
                            _bumpInbox(
                              preview: last.body,
                              fromSelf: mine,
                            );
                          } else if (state.lastInboundAt != null) {
                            _bumpInbox(preview: last.body, fromSelf: false);
                          }
                        }
                        context.read<ConversationsBloc>().add(
                              ConversationsMarkReadRequested(
                                widget.conversationId,
                              ),
                            );
                      },
                      builder: (context, state) {
                        if (state.status == ThreadStatus.loading &&
                            state.messages.isEmpty) {
                          return const ThreadMessagesSkeleton();
                        }
                        if (state.status == ThreadStatus.failure &&
                            state.messages.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.cloud_off_outlined,
                                    size: 40,
                                    color: AppColors.inkMuted.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    state.errorMessage ??
                                        'Could not load messages',
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
                          physics: const ClampingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          itemCount: state.messages.length,
                          itemBuilder: (context, index) {
                            final msg = state.messages[index];
                            final mine = msg.senderUserId == user?.id ||
                                msg.senderUserId == user?.alias ||
                                msg.senderUserId == user?.displayName;
                            final showTail =
                                index == state.messages.length - 1 ||
                                    state.messages[index + 1].senderUserId !=
                                        msg.senderUserId;
                            return MessageBubble(
                              body: msg.body,
                              mine: mine,
                              showTail: showTail,
                              timeLabel:
                                  formatter.format(msg.createdAt.toLocal()),
                              deliveryStatus: msg.deliveryStatus,
                              onRetry: () => context.read<ThreadBloc>().add(
                                    ThreadRetrySendRequested(
                                      msg.clientMessageId,
                                    ),
                                  ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  BlocBuilder<ThreadBloc, ThreadState>(
                    buildWhen: (p, c) =>
                        p.sending != c.sending ||
                        p.sendError != c.sendError ||
                        p.canSend != c.canSend ||
                        p.peerTyping != c.peerTyping,
                    builder: (context, state) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (state.peerTyping)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '$title is typing…',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppColors.inkMuted,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
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
                            enabled: state.canSend && !state.sending,
                            onChanged: _onComposerChanged,
                            onSend: () {
                              final body = _composer.text.trim();
                              if (body.isEmpty ||
                                  user == null ||
                                  active == null ||
                                  !state.canSend) {
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
                              context.read<ThreadBloc>().add(
                                    const ThreadTypingLocalChanged(false),
                                  );
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
        },
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
    required this.onChanged,
    this.enabled = true,
  });

  final TextEditingController controller;
  final bool sending;
  final bool enabled;
  final VoidCallback onSend;
  final ValueChanged<String> onChanged;

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
                  color: enabled
                      ? AppColors.surfaceRaised
                      : AppColors.surfaceRaised.withValues(alpha: 0.7),
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
                  enabled: enabled,
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.send,
                  onChanged: onChanged,
                  onSubmitted: (_) {
                    if (enabled) onSend();
                  },
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: enabled ? 'Message' : 'Wrong identity',
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
              color: enabled ? AppColors.ink : AppColors.inkMuted,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: (sending || !enabled) ? null : onSend,
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
