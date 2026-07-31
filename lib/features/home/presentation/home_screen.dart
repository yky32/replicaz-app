import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:replicaz/app/theme/app_colors.dart';
import 'package:replicaz/app/theme/app_spacing.dart';
import 'package:replicaz/core/widgets/ambient_background.dart';
import 'package:replicaz/core/widgets/initials_avatar.dart';
import 'package:replicaz/features/auth/bloc/auth_bloc.dart';
import 'package:replicaz/features/contacts/bloc/contacts_bloc.dart';
import 'package:replicaz/features/follow_ups/bloc/follow_ups_bloc.dart';
import 'package:replicaz/features/identities/bloc/identities_bloc.dart';
import 'package:replicaz/features/identities/presentation/widgets/identity_switcher_bar.dart';
import 'package:replicaz/features/messaging/bloc/conversations_bloc.dart';
import 'package:replicaz/features/notes/bloc/notes_bloc.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.user;
    final identities = context.watch<IdentitiesBloc>().state;
    final active = identities.activeIdentity;
    final contacts = context.watch<ContactsBloc>().state.contacts;
    final notes = context.watch<NotesBloc>().state.notes;
    final followUps = context.watch<FollowUpsBloc>().state;
    final chats = context.watch<ConversationsBloc>().state.conversations;
    final firstName = user?.displayName.split(' ').first ?? 'there';

    return Scaffold(
      body: AmbientBackground(
        intense: true,
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              22,
              12,
              22,
              AppSpacing.listBottomInset(context),
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Replicaz',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.syne(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            color: AppColors.inkMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Hey $firstName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.inkMuted,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const IdentitySwitcherBar(),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => context.push('/identities'),
                    icon: const Icon(Icons.layers_outlined),
                    tooltip: 'Identities',
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => context
                        .read<AuthBloc>()
                        .add(const AuthLogoutRequested()),
                    icon: const Icon(Icons.logout_rounded),
                    tooltip: 'Log out',
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                active == null ? 'Pick a life' : active.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.syne(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.9,
                  height: 1.05,
                ),
              ),
              if (active?.tagline.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(
                  active!.tagline,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.inkSoft,
                    fontSize: 15,
                    height: 1.35,
                  ),
                ),
              ],
              if (active != null) ...[
                const SizedBox(height: 22),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => context.go('/messages'),
                    borderRadius: BorderRadius.circular(22),
                    child: Ink(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            active.color.withValues(alpha: 0.16),
                            AppColors.surfaceRaised,
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          InitialsAvatar(
                            label: active.name,
                            color: active.color,
                            size: 48,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Active identity',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.inkMuted,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${chats.length} chats · ${contacts.length} people',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: active.color,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              Text(
                'In this life',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 0.4,
                  color: AppColors.inkMuted,
                ),
              ),
              const SizedBox(height: 8),
              _SpaceLink(
                title: 'Chats',
                detail: '${chats.length} threads',
                onTap: () => context.go('/messages'),
              ),
              _SpaceLink(
                title: 'People',
                detail: '${contacts.length} contacts',
                onTap: () => context.go('/contacts'),
              ),
              _SpaceLink(
                title: 'Notes',
                detail: '${notes.length} saved',
                onTap: () => context.go('/notes'),
              ),
              _SpaceLink(
                title: 'Follow-ups',
                detail: '${followUps.openCount} open',
                onTap: () => context.push('/follow-ups'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpaceLink extends StatelessWidget {
  const _SpaceLink({
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            Text(
              detail,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.inkMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
          ],
        ),
      ),
    );
  }
}
