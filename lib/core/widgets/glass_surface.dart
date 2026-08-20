import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:replicaz/app/theme/app_spacing.dart';

/// Frosted capsule surface — Triftly liquid-glass shell.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    required this.child,
    this.borderRadius,
    this.padding,
    this.blur = 14,
    this.tint,
    this.bordered = true,
    super.key,
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final double blur;
  final Color? tint;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? BorderRadius.circular(AppRadii.pill);

    final fill = tint ??
        (isDark
            ? const Color(0xFF1C1C1E).withValues(alpha: 0.72)
            : const Color(0xFFFEFEFE).withValues(alpha: 0.62));

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: AppShadows.navBar(context),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: bordered
                  ? Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.white.withValues(alpha: 0.75),
                      width: 0.8,
                    )
                  : null,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  fill,
                  fill.withValues(alpha: isDark ? 0.55 : 0.45),
                ],
              ),
            ),
            child: padding != null
                ? Padding(padding: padding!, child: child)
                : child,
          ),
        ),
      ),
    );
  }
}
