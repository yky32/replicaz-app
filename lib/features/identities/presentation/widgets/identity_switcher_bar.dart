import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:replicaz/app/theme/app_colors.dart';
import 'package:replicaz/core/widgets/initials_avatar.dart';
import 'package:replicaz/core/widgets/replicaz_bottom_sheet.dart';
import 'package:replicaz/features/identities/bloc/identities_bloc.dart';
import 'package:replicaz/core/widgets/life_context_bar.dart';
import 'package:replicaz/features/desk/presentation/widgets/needs_you_panel.dart';
import 'package:replicaz/app/theme/app_type.dart';
import 'package:replicaz/core/bootstrap/app_bootstrap.dart';
import 'package:replicaz/features/identities/domain/identity.dart';

/// Compact pill in headers — opens the life switcher sheet.
class IdentitySwitcherBar extends StatelessWidget {
  const IdentitySwitcherBar({super.key, this.compact = false});

  /// Smaller chip for dense headers.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IdentitiesBloc, IdentitiesState>(
      builder: (context, state) {
        final active = state.activeIdentity;
        if (state.identities.isEmpty || active == null) {
          return const SizedBox.shrink();
        }

        final pad = compact
            ? const EdgeInsets.fromLTRB(5, 5, 8, 5)
            : const EdgeInsets.fromLTRB(6, 6, 10, 6);
        final avatar = compact ? 24.0 : 26.0;
        final maxName = compact ? 72.0 : 96.0;

        final focused = LifeFocusStore.isActive &&
            LifeFocusStore.identityId == active.id;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => openIdentitySwitcher(context),
            onLongPress: () => IdentitySwitcherBar.openFocusSheet(context, active),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: pad,
              decoration: BoxDecoration(
                color: active.color.withValues(alpha: focused ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active.color.withValues(alpha: focused ? 0.85 : 0.45),
                  width: focused ? 2 : 1.2,
                ),
                boxShadow: focused
                    ? [
                        BoxShadow(
                          color: active.color.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InitialsAvatar(
                    label: active.name,
                    color: active.color,
                    size: avatar,
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxName),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          focused ? 'Focus' : 'Life',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                            color: focused ? active.color : AppColors.inkMuted,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          active.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: compact ? 12.5 : 13,
                            height: 1.1,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    focused
                        ? Icons.center_focus_strong
                        : Icons.unfold_more_rounded,
                    size: 18,
                    color: active.color.withValues(alpha: 0.9),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Public entry so other screens can open the same sheet.
  static Future<void> openIdentitySwitcher(BuildContext context) async {
    final identitiesBloc = context.read<IdentitiesBloc>();
    final identities = identitiesBloc.state.identities;
    final activeId = identitiesBloc.state.activeIdentityId;
    if (identities.isEmpty) return;

    await ReplicazBottomSheet.show<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              16 + MediaQuery.paddingOf(sheetContext).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Switch life',
                  maxLines: 1,
                  style: GoogleFonts.syne(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Chats, people, and notes stay inside the life you pick. '
                  'Reply as the self that belongs.',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.inkMuted,
                    height: 1.4,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 18),
                Builder(
                  builder: (context) {
                    final unread =
                        AppBootstrap.messagingService.unreadTotalsByIdentity();
                    return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: identities.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final identity = identities[index];
                    final selected = identity.id == activeId;
                    return _LifeTile(
                      identity: identity,
                      selected: selected,
                      unreadCount: unread[identity.id] ?? 0,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        if (!selected) {
                          final focusId = LifeFocusStore.identityId;
                          final leftFocus = LifeFocusStore.isActive &&
                              focusId != null &&
                              focusId != identity.id;
                          String? focusName;
                          if (leftFocus) {
                            for (final e in identities) {
                              if (e.id == focusId) {
                                focusName = e.name;
                                break;
                              }
                            }
                          }
                          identitiesBloc
                              .add(IdentitiesSwitchRequested(identity.id));
                          Navigator.pop(sheetContext);
                          showLifeSwitchedToast(context, identity);
                          if (leftFocus && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  focusName == null
                                      ? 'Focus still active on another life. Long-press pill to end it.'
                                      : 'Focus still on $focusName. Long-press pill to end.',
                                ),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        } else {
                          Navigator.pop(sheetContext);
                        }
                      },
                    );
                  },
                );
                  },
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    context.push('/identities');
                  },
                  icon: const Icon(Icons.layers_outlined, size: 18),
                  label: const Text('Manage lives'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<void> openFocusSheet(
    BuildContext context,
    Identity identity,
  ) async {
    HapticFeedback.mediumImpact();
    await ReplicazBottomSheet.show<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              16 + MediaQuery.paddingOf(sheetContext).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Focus · ${identity.name}', style: AppType.titleLg()),
                const SizedBox(height: 8),
                Text(
                  'Stay in this life for a while. Switch anytime — local reminder only.',
                  style: AppType.bodySm(),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    await LifeFocusStore.start(
                      identityId: identity.id,
                      duration: const Duration(hours: 1),
                    );
                    if (context.mounted) {
                      Navigator.pop(sheetContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Focus on ${identity.name} · 1 hour'),
                        ),
                      );
                    }
                  },
                  child: const Text('Focus 1 hour'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () async {
                    final now = DateTime.now();
                    final end = DateTime(now.year, now.month, now.day, 23, 59);
                    var dur = end.difference(now);
                    if (dur.isNegative || dur.inMinutes < 15) {
                      dur = const Duration(hours: 4);
                    }
                    await LifeFocusStore.start(
                      identityId: identity.id,
                      duration: dur,
                    );
                    if (context.mounted) {
                      Navigator.pop(sheetContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('Focus on ${identity.name} · rest of day'),
                        ),
                      );
                    }
                  },
                  child: const Text('Focus rest of day'),
                ),
                if (LifeFocusStore.isActive) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () async {
                      await LifeFocusStore.clear();
                      if (context.mounted) {
                        Navigator.pop(sheetContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Focus cleared')),
                        );
                      }
                    },
                    child: const Text('End focus'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LifeTile extends StatelessWidget {
  const _LifeTile({
    required this.identity,
    required this.selected,
    required this.onTap,
    this.unreadCount = 0,
  });

  final Identity identity;
  final bool selected;
  final VoidCallback onTap;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? identity.color.withValues(alpha: 0.12)
          : AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? identity.color.withValues(alpha: 0.55)
                  : AppColors.hairline,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              InitialsAvatar(
                label: identity.name,
                color: identity.color,
                size: 46,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            identity.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (selected) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: identity.color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Active',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: identity.color,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      identity.tagline.isEmpty
                          ? identity.type.label
                          : identity.tagline,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.inkMuted,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (unreadCount > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: identity.color,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                color: selected ? identity.color : AppColors.inkMuted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
