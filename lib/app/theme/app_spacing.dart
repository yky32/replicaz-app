import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;

  /// Gap above the home-indicator safe area to the nav island bottom edge.
  static const double navIslandBottomInset = 4;

  /// Liquid nav island height (glass padding + 48pt slots).
  static const double navIslandBarHeight = 58;

  /// Distance from the screen bottom to the nav island's bottom edge.
  static double navIslandBottomOffset(BuildContext context) {
    final homeIndicator = MediaQuery.paddingOf(context).bottom;
    return (homeIndicator > 0 ? homeIndicator : xs) + navIslandBottomInset;
  }

  /// Total vertical space reserved for the floating nav island.
  static double navIslandOccupiedHeight(BuildContext context) {
    return navIslandBottomOffset(context) + navIslandBarHeight;
  }

  /// List bottom inset when the floating nav island is visible.
  static double listBottomInset(BuildContext context) {
    return navIslandOccupiedHeight(context) + sm;
  }
}

abstract final class AppRadii {
  static const double navIsland = 24.65;
  static const double navIslandSlot = 18.7;
  static const double pill = 999;

  static BorderRadius get navIslandRadius => BorderRadius.circular(navIsland);
  static BorderRadius get navIslandSlotRadius =>
      BorderRadius.circular(navIslandSlot);
}

abstract final class AppShadows {
  static List<BoxShadow> navBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.12),
        blurRadius: 40,
        spreadRadius: -6,
        offset: const Offset(0, 16),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
        blurRadius: 1,
        offset: const Offset(0, 0.5),
      ),
    ];
  }
}
