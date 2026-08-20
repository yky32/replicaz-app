import 'package:flutter/material.dart';

/// Motion tokens — short, purposeful (snappy shell).
abstract final class AppMotion {
  static const Duration instant = Duration(milliseconds: 80);
  static const Duration fast = Duration(milliseconds: 140);
  static const Duration base = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 300);
  static const Duration lifeSwitch = Duration(milliseconds: 180);
  static const Duration nav = Duration(milliseconds: 160);

  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;
  static const Curve emphasized = Curves.easeOutCubic;

  static Animation<double> fade(AnimationController c) =>
      CurvedAnimation(parent: c, curve: easeOut);

  /// Life-switch list transition: fade only (slide was expensive / laggy).
  static Widget lifeSwitchTransition(
    Widget child,
    Animation<double> animation,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: easeOut);
    return FadeTransition(opacity: curved, child: child);
  }
}

/// Wraps tab body so content crossfades when [lifeKey] (active identity) changes.
class LifeSwitchScope extends StatelessWidget {
  const LifeSwitchScope({
    super.key,
    required this.lifeKey,
    required this.child,
  });

  final String? lifeKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.lifeSwitch,
      switchInCurve: AppMotion.easeOut,
      switchOutCurve: Curves.easeOut,
      // Avoid stacking previous+next frames (double paint cost).
      layoutBuilder: (currentChild, previousChildren) {
        return currentChild ?? const SizedBox.shrink();
      },
      transitionBuilder: AppMotion.lifeSwitchTransition,
      child: KeyedSubtree(
        key: ValueKey<String>(lifeKey ?? 'no-life'),
        child: child,
      ),
    );
  }
}
