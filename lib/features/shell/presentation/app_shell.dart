import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:replicaz/app/theme/app_spacing.dart';
import 'package:replicaz/features/shell/presentation/liquid_nav_island.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTabTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final islandWidth = (screenWidth * 0.88).clamp(280.0, 360.0);

    return Scaffold(
      extendBody: true,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: navigationShell),
          Positioned(
            left: 0,
            right: 0,
            bottom: AppSpacing.navIslandBottomOffset(context),
            child: Center(
              child: SizedBox(
                width: islandWidth,
                child: LiquidNavIsland(
                  currentIndex: navigationShell.currentIndex,
                  onTap: _onTabTap,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
