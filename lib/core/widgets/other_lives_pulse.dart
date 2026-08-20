import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:replicaz/app/theme/app_colors.dart';
import 'package:replicaz/app/theme/app_type.dart';
import 'package:replicaz/core/bootstrap/app_bootstrap.dart';
import 'package:replicaz/core/constants/storage_keys.dart';
import 'package:replicaz/features/follow_ups/domain/follow_up.dart';
import 'package:replicaz/features/identities/bloc/identities_bloc.dart';
import 'package:replicaz/features/identities/domain/identity.dart';
import 'package:replicaz/features/identities/presentation/widgets/identity_switcher_bar.dart';

/// Numbers-only pulse for **other** lives — never shows message/FU content.
class OtherLivesPulse extends StatelessWidget {
  const OtherLivesPulse({super.key});

  static List<_LifeCount> _counts(List<Identity> all, String? activeId) {
    final unread = AppBootstrap.messagingService.unreadTotalsByIdentity();
    final fus = AppBootstrap.store
        .getJsonList(StorageKeys.followUps)
        .map(FollowUp.fromJson)
        .where((e) => e.status == FollowUpStatus.open)
        .toList();
    final openByLife = <String, int>{};
    for (final f in fus) {
      openByLife.update(f.identityId, (v) => v + 1, ifAbsent: () => 1);
    }

    final out = <_LifeCount>[];
    for (final id in all) {
      if (id.id == activeId) continue;
      final u = unread[id.id] ?? 0;
      final o = openByLife[id.id] ?? 0;
      if (u <= 0 && o <= 0) continue;
      out.add(_LifeCount(identity: id, unread: u, openFollowUps: o));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<IdentitiesBloc>().state;
    final rows = _counts(state.identities, state.activeIdentityId);
    if (rows.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            HapticFeedback.selectionClick();
            IdentitySwitcherBar.openIdentitySwitcher(context);
          },
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppColors.surfaceRaised.withValues(alpha: 0.75),
              border: Border.all(color: AppColors.hairline),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              child: Row(
                children: [
                  Icon(
                    Icons.layers_outlined,
                    size: 18,
                    color: AppColors.inkMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Other lives',
                          style: AppType.labelSm(color: AppColors.inkMuted),
                        ),
                        ...rows.map((r) {
                          final parts = <String>[];
                          if (r.unread > 0) parts.add('${r.unread} unread');
                          if (r.openFollowUps > 0) {
                            parts.add('${r.openFollowUps} open');
                          }
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: r.identity.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: r.identity.color.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Text(
                              '${r.identity.name} · ${parts.join(' · ')}',
                              style: AppType.labelSm(color: r.identity.color)
                                  .copyWith(fontWeight: FontWeight.w800),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.swap_horiz_rounded,
                    size: 18,
                    color: AppColors.inkMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LifeCount {
  _LifeCount({
    required this.identity,
    required this.unread,
    required this.openFollowUps,
  });

  final Identity identity;
  final int unread;
  final int openFollowUps;
}
