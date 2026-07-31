import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:replicaz/app/theme/app_colors.dart';
import 'package:replicaz/app/theme/app_spacing.dart';
import 'package:replicaz/core/widgets/glass_surface.dart';

class _NavTab {
  const _NavTab({
    required this.icon,
    required this.selectedIcon,
  });

  final IconData icon;
  final IconData selectedIcon;
}

const _tabs = [
  _NavTab(
    icon: Icons.chat_bubble_outline_rounded,
    selectedIcon: Icons.chat_bubble_rounded,
  ),
  _NavTab(
    icon: Icons.people_outline_rounded,
    selectedIcon: Icons.people_rounded,
  ),
  _NavTab(
    icon: Icons.auto_awesome_mosaic_outlined,
    selectedIcon: Icons.auto_awesome_mosaic,
  ),
  _NavTab(
    icon: Icons.notes_rounded,
    selectedIcon: Icons.sticky_note_2_rounded,
  ),
];

/// Compact floating nav island — sliding pill, icon-first (Triftly).
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
      duration: const Duration(milliseconds: 420),
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
    return GlassSurface(
      blur: 36,
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
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOutCubic,
                  left: widget.currentIndex * slotWidth + inset,
                  top: inset,
                  bottom: inset,
                  width: slotWidth - inset * 2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: AppRadii.navIslandSlotRadius,
                      color: Colors.white.withValues(alpha: 0.88),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.06),
                          blurRadius: 10,
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
  });

  final _NavTab tab;
  final bool selected;
  final VoidCallback onTap;
  final Animation<double>? bounce;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.accentDeep : AppColors.inkMuted;

    Widget icon = Icon(
      selected ? tab.selectedIcon : tab.icon,
      size: selected ? 23 : 21,
      color: color,
    );

    if (bounce != null) {
      icon = ScaleTransition(
        scale: Tween<double>(begin: 0.88, end: 1).animate(
          CurvedAnimation(parent: bounce!, curve: Curves.easeOutBack),
        ),
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
