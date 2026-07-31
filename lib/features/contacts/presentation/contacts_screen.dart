import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:replicaz/app/theme/app_colors.dart';
import 'package:replicaz/app/theme/app_spacing.dart';
import 'package:replicaz/core/widgets/ambient_background.dart';
import 'package:replicaz/core/widgets/empty_state.dart';
import 'package:replicaz/core/widgets/initials_avatar.dart';
import 'package:replicaz/core/widgets/screen_header.dart';
import 'package:replicaz/features/contacts/bloc/contacts_bloc.dart';
import 'package:replicaz/features/identities/bloc/identities_bloc.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final active = context.watch<IdentitiesBloc>().state.activeIdentity;

    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ScreenHeader(
                title: 'People',
                subtitle: active == null ? null : 'In ${active.name}',
                subtitleColor: active?.color,
                actions: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => context.push('/contacts/new'),
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    tooltip: 'Add person',
                  ),
                ],
              ),
              Expanded(
                child: BlocBuilder<ContactsBloc, ContactsState>(
                  builder: (context, state) {
                    if (state.status == ContactsStatus.loading &&
                        state.contacts.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state.contacts.isEmpty) {
                      return EmptyState(
                        title: 'No one here yet',
                        message:
                            'Add people who belong to this identity only.',
                        actionLabel: 'Add person',
                        icon: Icons.person_outline_rounded,
                        onAction: () => context.push('/contacts/new'),
                      );
                    }
                    return ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                        8,
                        0,
                        8,
                        AppSpacing.listBottomInset(context),
                      ),
                      itemCount: state.contacts.length,
                      itemBuilder: (context, index) {
                        final contact = state.contacts[index];
                        return ListTile(
                          onTap: () =>
                              context.push('/contacts/${contact.id}/edit'),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          leading: InitialsAvatar(
                            label: contact.name,
                            color: active?.color ?? AppColors.accent,
                            size: 48,
                          ),
                          title: Text(
                            contact.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            [
                              if (contact.company.isNotEmpty) contact.company,
                              if (contact.email.isNotEmpty) contact.email,
                            ].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.inkMuted),
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
