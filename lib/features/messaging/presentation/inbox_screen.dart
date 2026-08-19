import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:replicaz/app/theme/app_colors.dart';
import 'package:replicaz/core/widgets/life_list_cell.dart';
import 'package:replicaz/app/theme/app_motion.dart';
import 'package:replicaz/app/theme/app_spacing.dart';
import 'package:replicaz/core/bootstrap/app_bootstrap.dart';
import 'package:replicaz/core/config/app_config.dart';
import 'package:replicaz/core/widgets/ambient_background.dart';
import 'package:replicaz/core/widgets/empty_state.dart';
import 'package:replicaz/core/widgets/skeletons/replicaz_skeletons.dart';
import 'package:replicaz/core/widgets/initials_avatar.dart';
import 'package:replicaz/core/widgets/replicaz_bottom_sheet.dart';
import 'package:replicaz/core/widgets/screen_header.dart';
import 'package:replicaz/core/widgets/search_field.dart';
import 'package:replicaz/core/widgets/life_context_bar.dart';
import 'package:replicaz/features/auth/bloc/auth_bloc.dart';
import 'package:replicaz/features/identities/bloc/identities_bloc.dart';
import 'package:replicaz/features/identities/presentation/widgets/identity_switcher_bar.dart';
import 'package:replicaz/features/messaging/bloc/conversations_bloc.dart';
import 'package:replicaz/features/messaging/data/remote_messaging_api.dart';
import 'package:replicaz/features/messaging/domain/conversation.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> with WidgetsBindingObserver {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _search.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<ConversationsBloc>().add(
            const ConversationsInboxResumeRequested(),
          );
    }
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
    if (!AppConfig.effectiveRemoteBackend) {
      context.read<ConversationsBloc>().add(
            ConversationsCreateRequested(userId: userId),
          );
      return;
    }

    List<RemoteUser> users = const [];
    try {
      users = await AppBootstrap.messagingService.listUsers();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load users: $e')),
      );
      return;
    }

    if (!context.mounted) return;
    if (users.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No other users yet — log in Alice on one sim, Bob on the other.',
          ),
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

  @override
  Widget build(BuildContext context) {
    final time = DateFormat.jm();
    final day = DateFormat.MMMd();
    final active = context.watch<IdentitiesBloc>().state.activeIdentity;

    return Scaffold(
      body: AmbientBackground(
        lifeColor: active?.color,
        intense: true,
        child: SafeArea(
          bottom: false,
          child: BlocListener<ConversationsBloc, ConversationsState>(
            listenWhen: (p, c) =>
                (c.errorMessage != null &&
                    c.errorMessage != p.errorMessage) ||
                (c.lastCreatedConversationId != null &&
                    c.lastCreatedConversationId !=
                        p.lastCreatedConversationId),
            listener: (context, state) {
              final createdId = state.lastCreatedConversationId;
              if (createdId != null &&
                  createdId.isNotEmpty &&
                  state.errorMessage == null) {
                Conversation? match;
                for (final c in state.conversations) {
                  if (c.id == createdId) {
                    match = c;
                    break;
                  }
                }
                context.push(
                  '/messages/$createdId',
                  extra: <String, String?>{'title': match?.title},
                );
                context.read<ConversationsBloc>().add(
                      const ConversationsLastCreatedConsumed(),
                    );
              }
              final msg = state.errorMessage;
              if (msg == null) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(msg)),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ScreenHeader(
                  title: 'Chats',
                  subtitle: active == null
                      ? 'One phone · many lives'
                      : null,
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
                if (active != null)
                  LifeContextBar(
                    identity: active,
                    onTap: () => IdentitySwitcherBar.openIdentitySwitcher(context),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: SearchField(
                    controller: _search,
                    hintText: active == null
                        ? 'Search chats'
                        : 'Search in ${active.name}',
                  ),
                ),
                Expanded(
                  child: LifeSwitchScope(
                    lifeKey: active?.id,
                    child: BlocBuilder<ConversationsBloc, ConversationsState>(
                    builder: (context, state) {
                      final q = _search.text.trim().toLowerCase();
                      final chats = q.isEmpty
                          ? state.conversations
                          : state.conversations.where((c) {
                              final t = (c.title ?? '').toLowerCase();
                              final p =
                                  (c.lastMessagePreview ?? '').toLowerCase();
                              return t.contains(q) || p.contains(q);
                            }).toList();

                      if (state.conversations.isEmpty &&
                          (state.status == ConversationsStatus.loading ||
                              state.status == ConversationsStatus.initial)) {
                        return const InboxSkeleton();
                      }
                      if (state.status == ConversationsStatus.failure &&
                          state.conversations.isEmpty) {
                        return EmptyState(
                          title: 'Could not load chats',
                          message: state.errorMessage ??
                              'Is the messenger API running on :9010?',
                          actionLabel: 'Retry',
                          icon: Icons.cloud_off_outlined,
                          onAction: () {
                            final id = state.identityId ??
                                context
                                    .read<IdentitiesBloc>()
                                    .state
                                    .activeIdentityId;
                            if (id != null) {
                              context.read<ConversationsBloc>().add(
                                    ConversationsLoadRequested(identityId: id),
                                  );
                            }
                          },
                        );
                      }
                      if (state.conversations.isEmpty) {
                        return BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, auth) {
                            final life = active?.name ?? 'this identity';
                            return EmptyState(
                            title: 'No chats in $life',
                            message:
                                'Start a thread as $life. Other lives stay out of the way.',
                            actionLabel: 'New chat',
                            icon: Icons.forum_outlined,
                            accent: active?.color,
                            hint: 'Tap the life pill (top right) to switch who you are.',
                            onAction: !auth.isAuthenticated
                                ? null
                                : () => _startChat(context, auth.user!.id),
                          );
                          },
                        );
                      }
                      if (chats.isEmpty) {
                        return EmptyState(
                          title: 'No matches',
                          message:
                              'Nothing matches “${_search.text.trim()}”.',
                          icon: Icons.search_off_rounded,
                        );
                      }
                      final refreshing = state.status ==
                              ConversationsStatus.loading &&
                          state.conversations.isNotEmpty;
                      return RefreshIndicator(
                        onRefresh: () async {
                          context.read<ConversationsBloc>().add(
                                const ConversationsRefreshRequested(),
                              );
                          await Future<void>.delayed(
                            const Duration(milliseconds: 400),
                          );
                        },
                        child: SkeletonOverlay(
                          enabled: refreshing,
                          child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            8,
                            0,
                            8,
                            AppSpacing.listBottomInset(context),
                          ),
                          itemCount: chats.length,
                          itemBuilder: (context, index) {
                            final c = chats[index];
                            return Dismissible(
                              key: ValueKey('chat-${c.id}'),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.redAccent.shade200,
                                ),
                              ),
                              confirmDismiss: (_) async {
                                return await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Hide chat?'),
                                        content: const Text(
                                          'Removes it from this device inbox. You can start a new chat later to reopen.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: const Text('Hide'),
                                          ),
                                        ],
                                      ),
                                    ) ??
                                    false;
                              },
                              onDismissed: (_) {
                                context.read<ConversationsBloc>().add(
                                      ConversationsLeaveRequested(c.id),
                                    );
                              },
                              child: LifeListCell(
                                title: c.title?.isNotEmpty == true
                                    ? c.title!
                                    : 'Chat',
                                subtitle: (c.lastMessagePreview?.trim().isNotEmpty ==
                                        true)
                                    ? c.lastMessagePreview!
                                    : (c.lastMessageAt == null
                                        ? 'No messages yet — say hi'
                                        : 'Open thread'),
                                meta: c.lastMessageAt == null
                                    ? null
                                    : _formatStamp(c.lastMessageAt!, time, day),
                                accent: active?.color ?? AppColors.accent,
                                emphasized: c.unreadCount > 0,
                                trailing: c.unreadCount > 0
                                    ? LifeMetaBadge(
                                        label: c.unreadCount > 99
                                            ? '99+'
                                            : '${c.unreadCount}',
                                        color:
                                            active?.color ?? AppColors.accent,
                                      )
                                    : null,
                                onTap: () async {
                                  context.read<ConversationsBloc>().add(
                                        ConversationsMarkReadRequested(c.id),
                                      );
                                  await context.push(
                                    '/messages/${c.id}',
                                    extra: <String, String?>{
                                      'title': c.title,
                                    },
                                  );
                                  if (context.mounted) {
                                    context.read<ConversationsBloc>().add(
                                          const ConversationsRefreshRequested(),
                                        );
                                  }
                                },
                              ),
                            );
                          },
                        ),
                        ),
                      );
                    },
                  ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
