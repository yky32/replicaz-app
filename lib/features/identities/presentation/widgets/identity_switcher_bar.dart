import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:replicaz/app/theme/app_colors.dart';
import 'package:replicaz/core/widgets/initials_avatar.dart';
import 'package:replicaz/core/widgets/replicaz_bottom_sheet.dart';
import 'package:replicaz/features/identities/bloc/identities_bloc.dart';
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

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => openIdentitySwitcher(context),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: pad,
              decoration: BoxDecoration(
                color: active.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active.color.withValues(alpha: 0.45),
                  width: 1.2,
                ),
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
                          'Life',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                            color: AppColors.inkMuted,
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
                    Icons.unfold_more_rounded,
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
                ListView.separated(
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
                      onTap: () {
                        HapticFeedback.selectionClick();
                        if (!selected) {
                          identitiesBloc
                              .add(IdentitiesSwitchRequested(identity.id));
                          Navigator.pop(sheetContext);
                          final messenger = ScaffoldMessenger.maybeOf(context);
                          messenger
                            ?..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: AppColors.ink,
                                content: Text(
                                  'Now in ${identity.name}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                duration: const Duration(milliseconds: 1600),
                              ),
                            );
                        } else {
                          Navigator.pop(sheetContext);
                        }
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
}

class _LifeTile extends StatelessWidget {
  const _LifeTile({
    required this.identity,
    required this.selected,
    required this.onTap,
  });

  final Identity identity;
  final bool selected;
  final VoidCallback onTap;

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
              const SizedBox(width: 8),
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
