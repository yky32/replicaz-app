import 'package:flutter/material.dart';
import 'package:replicaz/app/theme/app_colors.dart';

/// Soft messenger canvas — mist gradient + life-tinted glow + faint dots.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({
    super.key,
    required this.child,
    this.intense = false,
    this.lifeColor,
  });

  final Widget child;
  final bool intense;

  /// Active life tint — subtle radial so multi-life context is always felt.
  final Color? lifeColor;

  @override
  Widget build(BuildContext context) {
    final life = lifeColor ?? AppColors.accent;

    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFF5F7FA),
                AppColors.background,
                Color(0xFFE6EDF3),
              ],
            ),
          ),
        ),
        // Life-aware wash (always on when color provided).
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.75, -0.9),
              radius: 1.15,
              colors: [
                life.withValues(alpha: intense ? 0.22 : 0.14),
                life.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.95, 0.15),
              radius: 0.95,
              colors: [
                life.withValues(alpha: intense ? 0.12 : 0.06),
                const Color(0x00EEF2F6),
              ],
            ),
          ),
        ),
        CustomPaint(painter: _DotFieldPainter(), child: const SizedBox.expand()),
        child,
      ],
    );
  }
}

class _DotFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x1412181F);
    const step = 22.0;
    for (var y = 0.0; y < size.height; y += step) {
      for (var x = 0.0; x < size.width; x += step) {
        canvas.drawCircle(Offset(x + (y / step % 2) * 6, y), 0.9, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
