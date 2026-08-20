import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:replicaz/app/theme/app_colors.dart';
import 'package:replicaz/app/theme/app_motion.dart';
import 'package:replicaz/app/theme/app_spacing.dart';
import 'package:replicaz/app/theme/app_type.dart';
import 'package:replicaz/core/widgets/ambient_background.dart';
import 'package:replicaz/core/widgets/empty_state.dart';
import 'package:replicaz/core/widgets/life_list_cell.dart';
import 'package:replicaz/core/widgets/screen_header.dart';
import 'package:replicaz/core/widgets/skeletons/replicaz_skeletons.dart';
import 'package:replicaz/features/contacts/bloc/contacts_bloc.dart';
import 'package:replicaz/features/contacts/presentation/contact_detail_sheet.dart';
import 'package:replicaz/features/desk/presentation/widgets/needs_you_panel.dart';
import 'package:replicaz/features/identities/bloc/identities_bloc.dart';
import 'package:replicaz/features/messaging/bloc/conversations_bloc.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final active = context.watch<IdentitiesBloc>().state.activeIdentity;
    final accent = active?.color ?? AppColors.accent;
    final life = active?.name ?? 'this life';

    return Scaffold(
      body: AmbientBackground(
        lifeColor: active?.color,
        intense: true,
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ScreenHeader(
                title: 'Circle',
                subtitle: active == null
                    ? 'People in each life stay separate'
                    : 'In $life only',
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
                child: LifeSwitchScope(
                  lifeKey: active?.id,
                  child: BlocBuilder<ContactsBloc, ContactsState>(
                    builder: (context, state) {
                      if (state.contacts.isEmpty &&
                          (state.status == ContactsStatus.loading ||
                              state.status == ContactsStatus.initial)) {
                        return const PeopleSkeleton();
                      }

                      final chats =
                          context.watch<ConversationsBloc>().state.conversations;
                      final names = state.contacts
                          .map((e) => e.name.trim().toLowerCase())
                          .toList();
                      final suggestions = circleSuggestionsFromChats(
                        chats: chats,
                        existingContactNamesLower: names,
                      );

                      if (state.contacts.isEmpty && suggestions.isEmpty) {
                        return EmptyState(
                          title: 'Circle is empty in $life',
                          message:
                              'Only people for $life live here. Switch life to see another circle — nothing mixes.',
                          actionLabel: 'Add person',
                          icon: Icons.person_outline_rounded,
                          accent: accent,
                          hint: 'Or start a chat — we can suggest them here.',
                          onAction: () => context.push('/contacts/new'),
                        );
                      }

                      return ListView(
                        padding: EdgeInsets.fromLTRB(
                          0,
                          0,
                          0,
                          AppSpacing.listBottomInset(context),
                        ),
                        children: [
                          if (suggestions.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
                              child: Text(
                                'From your chats in $life',
                                style: AppType.overline(color: accent),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: Text(
                                'Add to Circle so follow-ups and notes can attach to a person.',
                                style: AppType.caption(),
                              ),
                            ),
                            ...suggestions.map((c) {
                              final name = c.title!.trim();
                              return LifeListCell(
                                title: name,
                                subtitle: c.lastMessagePreview?.trim().isNotEmpty ==
                                        true
                                    ? c.lastMessagePreview
                                    : 'In chats · not in Circle yet',
                                accent: accent,
                                meta: 'Add',
                                emphasized: true,
                                onTap: () => context.push(
                                  '/contacts/new?name=${Uri.encodeComponent(name)}',
                                ),
                              );
                            }),
                            if (state.contacts.isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 8, 20, 6),
                                child: Text(
                                  'In Circle',
                                  style: AppType.overline(
                                    color: AppColors.inkMuted,
                                  ),
                                ),
                              ),
                          ],
                          if (state.contacts.isEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                              child: Text(
                                'No saved people yet — add someone from a chat above, or create new.',
                                textAlign: TextAlign.center,
                                style: AppType.bodySm(),
                              ),
                            )
                          else
                            ...state.contacts.map(
                              (contact) => LifeListCell(
                                title: contact.name,
                                subtitle: [
                                  if (contact.company.isNotEmpty)
                                    contact.company,
                                  if (contact.email.isNotEmpty) contact.email,
                                ].join(' · '),
                                accent: accent,
                                onTap: () => showContactDetailSheet(
                                  context,
                                  contact: contact,
                                  accent: accent,
                                  lifeName: life,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
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
