import 'package:flutter/material.dart';

/// Motion tokens — short, purposeful (Base-style atomic timings).
abstract final class AppMotion {
  static const Duration instant = Duration(milliseconds: 80);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 420);
  static const Duration lifeSwitch = Duration(milliseconds: 380);

  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;
  static const Curve emphasized = Curves.easeOutBack;

  /// Standard page / sheet enter.
  static Animation<double> fade(AnimationController c) =>
      CurvedAnimation(parent: c, curve: easeOut);

  /// Life-switch list transition: fade + slight vertical slide.
  static Widget lifeSwitchTransition(
    Widget child,
    Animation<double> animation,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: easeOut);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.018),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
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
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.topCenter,
          children: [
            ...previousChildren,
            ?currentChild,
          ],
        );
      },
      transitionBuilder: AppMotion.lifeSwitchTransition,
      child: KeyedSubtree(
        key: ValueKey<String>(lifeKey ?? 'no-life'),
        child: child,
      ),
    );
  }
}
