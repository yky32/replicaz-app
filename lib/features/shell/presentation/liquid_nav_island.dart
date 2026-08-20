import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:replicaz/app/theme/app_colors.dart';
import 'package:replicaz/app/theme/app_motion.dart';
import 'package:replicaz/app/theme/app_spacing.dart';
import 'package:replicaz/core/widgets/glass_surface.dart';
import 'package:replicaz/features/follow_ups/bloc/follow_ups_bloc.dart';
import 'package:replicaz/features/follow_ups/domain/follow_up.dart';
import 'package:replicaz/features/identities/bloc/identities_bloc.dart';
import 'package:replicaz/features/messaging/bloc/conversations_bloc.dart';

class _NavTab {
  const _NavTab({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Slasher IA — 3 tabs only.
const _tabs = [
  _NavTab(
    icon: Icons.chat_bubble_outline_rounded,
    selectedIcon: Icons.chat_bubble_rounded,
    label: 'Chats',
  ),
  _NavTab(
    icon: Icons.people_outline_rounded,
    selectedIcon: Icons.people_rounded,
    label: 'Circle',
  ),
  _NavTab(
    icon: Icons.grid_view_rounded,
    selectedIcon: Icons.grid_view_rounded,
    label: 'Desk',
  ),
];

/// Compact floating nav island — sliding pill (Triftly / Uber density).
class LiquidNavIsland extends StatefulWidget {
  const LiquidNavIsland({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  State<LiquidNavIsland> createState() => _LiquidNavIslandState();
}

class _LiquidNavIslandState extends State<LiquidNavIsland>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: AppMotion.nav,
    )..value = 1;
  }

  @override
  void didUpdateWidget(LiquidNavIsland oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _bounce.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatUnread = context.select<ConversationsBloc, int>(
      (b) => b.state.conversations.fold<int>(0, (n, c) => n + c.unreadCount),
    );
    final deskOpen = context.select<FollowUpsBloc, int>(
      (b) => b.state.items
          .where((e) => e.status == FollowUpStatus.open)
          .length,
    );
    final lifeColor = context.select<IdentitiesBloc, Color>(
      (b) => b.state.activeIdentity?.color ?? AppColors.accent,
    );

    return GlassSurface(
      blur: 14,
      bordered: false,
      borderRadius: AppRadii.navIslandRadius,
      padding: const EdgeInsets.all(5),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final slotWidth = constraints.maxWidth / _tabs.length;
          const inset = 2.0;

          return SizedBox(
            height: 48,
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: AppMotion.nav,
                  curve: AppMotion.easeOut,
                  left: widget.currentIndex * slotWidth + inset,
                  top: inset,
                  bottom: inset,
                  width: slotWidth - inset * 2,
                  child: AnimatedContainer(
                    duration: AppMotion.nav,
                    decoration: BoxDecoration(
                      borderRadius: AppRadii.navIslandSlotRadius,
                      color: Colors.white.withValues(alpha: 0.9),
                      border: Border.all(
                        color: lifeColor.withValues(alpha: 0.28),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: lifeColor.withValues(alpha: 0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < _tabs.length; i++)
                      Expanded(
                        child: _NavSlot(
                          tab: _tabs[i],
                          selected: i == widget.currentIndex,
                          bounce: i == widget.currentIndex ? _bounce : null,
                          badgeCount: i == 0
                              ? chatUnread
                              : (i == 2 ? deskOpen : 0),
                          accent: lifeColor,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            widget.onTap(i);
                          },
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NavSlot extends StatelessWidget {
  const _NavSlot({
    required this.tab,
    required this.selected,
    required this.onTap,
    this.bounce,
    this.badgeCount = 0,
    this.accent = AppColors.accent,
  });

  final _NavTab tab;
  final bool selected;
  final VoidCallback onTap;
  final Animation<double>? bounce;
  final int badgeCount;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final color = selected ? accent : AppColors.inkMuted;

    Widget icon = Icon(
      selected ? tab.selectedIcon : tab.icon,
      size: selected ? 23 : 21,
      color: color,
    );

    if (bounce != null) {
      icon = ScaleTransition(
        scale: Tween<double>(begin: 0.88, end: 1).animate(
          CurvedAnimation(parent: bounce!, curve: AppMotion.emphasized),
        ),
        child: icon,
      );
    }

    if (badgeCount > 0) {
      icon = Badge(
        label: Text(
          badgeCount > 99 ? '99+' : '$badgeCount',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
        ),
        backgroundColor: accent,
        child: icon,
      );
    }

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.navIslandSlotRadius,
        splashColor: AppColors.accent.withValues(alpha: 0.08),
        highlightColor: Colors.transparent,
        child: SizedBox(
          height: 48,
          child: Center(child: icon),
        ),
      ),
    );
  }
}
