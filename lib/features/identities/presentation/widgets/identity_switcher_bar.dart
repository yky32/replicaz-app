import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:replicaz/app/theme/app_colors.dart';
import 'package:replicaz/core/widgets/initials_avatar.dart';
import 'package:replicaz/core/widgets/replicaz_bottom_sheet.dart';
import 'package:replicaz/features/identities/bloc/identities_bloc.dart';
import 'package:replicaz/features/identities/domain/identity.dart';

class IdentitySwitcherBar extends StatelessWidget {
  const IdentitySwitcherBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IdentitiesBloc, IdentitiesState>(
      builder: (context, state) {
        final active = state.activeIdentity;
        if (state.identities.isEmpty || active == null) {
          return const SizedBox.shrink();
        }

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _openSwitcher(context),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.fromLTRB(6, 6, 10, 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.hairline),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InitialsAvatar(
                    label: active.name,
                    color: active.color,
                    size: 26,
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 88),
                    child: Text(
                      active.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openSwitcher(BuildContext context) async {
    final identitiesBloc = context.read<IdentitiesBloc>();
    final identities = identitiesBloc.state.identities;
    final activeId = identitiesBloc.state.activeIdentityId;

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
                  'Switch life',
                  maxLines: 1,
                  style: GoogleFonts.syne(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Chats and contacts follow the identity you pick.',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 16),
                ...identities.map((identity) {
                  final selected = identity.id == activeId;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: InitialsAvatar(
                      label: identity.name,
                      color: identity.color,
                      size: 42,
                    ),
                    title: Text(
                      identity.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(identity.type.label),
                    trailing: selected
                        ? Icon(Icons.check_circle_rounded, color: identity.color)
                        : null,
                    onTap: () {
                      identitiesBloc.add(IdentitiesSwitchRequested(identity.id));
                      Navigator.pop(sheetContext);
                    },
                  );
                }),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    context.push('/identities');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Manage identities'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
