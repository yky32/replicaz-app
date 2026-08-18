import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:replicaz/app/theme/app_colors.dart';
import 'package:replicaz/core/widgets/ambient_background.dart';
import 'package:replicaz/core/widgets/empty_state.dart';
import 'package:replicaz/core/widgets/skeletons/replicaz_skeletons.dart';
import 'package:replicaz/core/widgets/initials_avatar.dart';
import 'package:replicaz/core/widgets/screen_header.dart';
import 'package:replicaz/features/identities/bloc/identities_bloc.dart';
import 'package:replicaz/features/identities/domain/identity.dart';

class IdentitiesScreen extends StatelessWidget {
  const IdentitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmbientBackground(
        intense: true,
        child: SafeArea(
          child: Column(
            children: [
              ScreenHeader(
                title: 'Your lives',
                eyebrow: 'Identities',
                subtitle: 'Tap a life to switch · long-press to edit',
                showIdentitySwitcher: false,
                leading: IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                ),
                actions: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => context.push('/identities/new'),
                    icon: const Icon(Icons.add_rounded),
                    tooltip: 'Add identity',
                  ),
                ],
              ),
              Expanded(
                child: BlocBuilder<IdentitiesBloc, IdentitiesState>(
                  builder: (context, state) {
                    if (state.identities.isEmpty &&
                        (state.status == IdentitiesStatus.loading ||
                            state.status == IdentitiesStatus.initial)) {
                      return const IdentitiesSkeleton();
                    }
                    if (state.identities.isEmpty) {
                      return EmptyState(
                        title: 'No lives yet',
                        message:
                            'Add Job, Personal, Freelance… each keeps its own chats and people.',
                        actionLabel: 'Add a life',
                        icon: Icons.layers_outlined,
                        onAction: () => context.push('/identities/new'),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                      itemCount: state.identities.length +
                          (state.errorMessage != null ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (state.errorMessage != null && index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              state.errorMessage!,
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.danger,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          );
                        }
                        final identity = state.identities[
                            state.errorMessage != null ? index - 1 : index];
                        final isActive = identity.id == state.activeIdentityId;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Material(
                            color: AppColors.surfaceRaised,
                            borderRadius: BorderRadius.circular(22),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(22),
                              onTap: () => context.read<IdentitiesBloc>().add(
                                    IdentitiesSwitchRequested(identity.id),
                                  ),
                              onLongPress: () => context
                                  .push('/identities/${identity.id}/edit'),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    InitialsAvatar(
                                      label: identity.name,
                                      color: identity.color,
                                      size: 48,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            identity.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            identity.tagline.isEmpty
                                                ? identity.type.label
                                                : identity.tagline,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: AppColors.inkMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isActive)
                                      Padding(
                                        padding: const EdgeInsets.only(right: 4),
                                        child: Text(
                                          'Active',
                                          style: GoogleFonts.plusJakartaSans(
                                            color: identity.color,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => context.push(
                                        '/identities/${identity.id}/edit',
                                      ),
                                      icon: const Icon(
                                        Icons.more_horiz_rounded,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
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
}
