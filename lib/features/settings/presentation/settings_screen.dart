import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:replicaz/app/theme/app_colors.dart';
import 'package:replicaz/app/theme/app_type.dart';
import 'package:replicaz/core/bootstrap/app_bootstrap.dart';
import 'package:replicaz/core/constants/storage_keys.dart';
import 'package:replicaz/core/demo/demo_seed.dart';
import 'package:replicaz/core/widgets/ambient_background.dart';
import 'package:replicaz/core/widgets/first_run_tips.dart';
import 'package:replicaz/core/widgets/screen_header.dart';
import 'package:replicaz/features/auth/bloc/auth_bloc.dart';
import 'package:replicaz/features/contacts/bloc/contacts_bloc.dart';
import 'package:replicaz/features/desk/presentation/widgets/needs_you_panel.dart';
import 'package:replicaz/features/follow_ups/bloc/follow_ups_bloc.dart';
import 'package:replicaz/features/identities/bloc/identities_bloc.dart';
import 'package:replicaz/features/messaging/bloc/conversations_bloc.dart';
import 'package:replicaz/features/notes/bloc/notes_bloc.dart';
import 'package:replicaz/features/receipts/bloc/receipts_bloc.dart';

/// Lightweight settings for soft-launch (no backend admin).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _resetDemo(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset demo data?'),
        content: const Text(
          'Reloads fixture chats, people, notes, and follow-ups for this device. '
          'Your other local edits in demo will be replaced.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    HapticFeedback.mediumImpact();
    await DemoSeed.ensureFromFixtures(force: true);
    await LifeFocusStore.clear();
    if (!context.mounted) return;

    context.read<IdentitiesBloc>().add(const IdentitiesLoadRequested());
    final id = AppBootstrap.store.getString(StorageKeys.activeIdentityId);
    if (id != null && id.isNotEmpty) {
      context.read<ContactsBloc>().add(ContactsLoadRequested(identityId: id));
      context.read<NotesBloc>().add(NotesLoadRequested(identityId: id));
      context.read<FollowUpsBloc>().add(FollowUpsLoadRequested(identityId: id));
      context.read<ReceiptsBloc>().add(ReceiptsLoadRequested(identityId: id, force: true));
      context
          .read<ConversationsBloc>()
          .add(ConversationsLoadRequested(identityId: id));
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demo fixtures reloaded')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final focusActive = LifeFocusStore.isActive;

    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            children: [
              ScreenHeader(
                title: 'Settings',
                subtitle: 'Soft-launch controls',
                showIdentitySwitcher: false,
                leading: IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  children: [
                    _card(
                      children: [
                        _tile(
                          icon: Icons.layers_outlined,
                          title: 'Manage lives',
                          subtitle: 'Add, edit, or switch identities',
                          onTap: () => context.push('/identities'),
                        ),
                        const Divider(height: 1),
                        _tile(
                          icon: Icons.center_focus_strong,
                          title: focusActive ? 'End Focus' : 'Focus mode',
                          subtitle: focusActive
                              ? 'Clear the local focus reminder'
                              : 'Long-press the Life pill on any header',
                          onTap: focusActive
                              ? () async {
                                  await LifeFocusStore.clear();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Focus ended'),
                                      ),
                                    );
                                    Navigator.of(context).pop();
                                  }
                                }
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _card(
                      children: [
                        _tile(
                          icon: Icons.lightbulb_outline,
                          title: 'Show first-run tips again',
                          subtitle: '3 tabs · Life pill · Focus',
                          onTap: () async {
                            await AppBootstrap.store
                                .setString('first_run_tips_seen', '');
                            if (context.mounted) {
                              Navigator.pop(context);
                              await FirstRunTips.showForce(context);
                            }
                          },
                        ),
                        const Divider(height: 1),
                        _tile(
                          icon: Icons.refresh_rounded,
                          title: 'Reset demo fixtures',
                          subtitle: 'Force re-seed chats · people · desk data',
                          onTap: () => _resetDemo(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _card(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.info_outline),
                          title: Text('About', style: AppType.labelLg()),
                          subtitle: Text(
                            'Replicaz soft launch · multi-life messenger shell. '
                            'Offline demo isolates lives on device. Real multi-user chat needs your backend.',
                            style: AppType.caption(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    FilledButton.tonal(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        context
                            .read<AuthBloc>()
                            .add(const AuthLogoutRequested());
                        context.go('/login');
                      },
                      child: const Text('Log out'),
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

  Widget _card({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.inkSoft),
      title: Text(title, style: AppType.labelLg()),
      subtitle: Text(subtitle, style: AppType.caption()),
      trailing: onTap == null
          ? null
          : const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
      onTap: onTap,
      enabled: onTap != null,
    );
  }
}
