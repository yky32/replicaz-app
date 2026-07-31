import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:replicaz/app/theme/app_colors.dart';
import 'package:replicaz/core/widgets/ambient_background.dart';
import 'package:replicaz/core/widgets/initials_avatar.dart';
import 'package:replicaz/core/widgets/message_bubble.dart';
import 'package:replicaz/features/auth/bloc/auth_bloc.dart';
import 'package:replicaz/features/identities/bloc/identities_bloc.dart';
import 'package:replicaz/features/messaging/bloc/conversations_bloc.dart';
import 'package:replicaz/features/messaging/bloc/thread_bloc.dart';
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

class _ThreadViewState extends State<_ThreadView> {
  final _composer = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
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
                      onPressed: () => Navigator.of(context).maybePop(),
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
            Expanded(
              child: BlocConsumer<ThreadBloc, ThreadState>(
                listenWhen: (p, c) => p.messages.length != c.messages.length,
                listener: (context, state) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!_scroll.hasClients) return;
                    _scroll.animateTo(
                      _scroll.position.maxScrollExtent + 80,
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOut,
                    );
                  });
                },
                builder: (context, state) {
                  if (state.status == ThreadStatus.loading &&
                      state.messages.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
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
                      );
                    },
                  );
                },
              ),
            ),
            BlocBuilder<ThreadBloc, ThreadState>(
              buildWhen: (p, c) => p.sending != c.sending,
              builder: (context, state) {
                return _ComposerBar(
                  controller: _composer,
                  sending: state.sending,
                  onSend: () {
                    final body = _composer.text.trim();
                    if (body.isEmpty || user == null || active == null) return;
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
                    final identityId =
                        context.read<IdentitiesBloc>().state.activeIdentityId;
                    if (identityId != null) {
                      context.read<ConversationsBloc>().add(
                            ConversationsLoadRequested(identityId: identityId),
                          );
                    }
                  },
                );
              },
            ),
          ],
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
                child: const SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(Icons.arrow_upward_rounded, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
