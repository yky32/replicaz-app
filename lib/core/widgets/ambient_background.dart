import 'package:flutter/material.dart';
import 'package:replicaz/app/theme/app_colors.dart';

/// Soft messenger canvas — mist gradient + faint dots.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({
    super.key,
    required this.child,
    this.intense = false,
  });

  final Widget child;
  final bool intense;

  @override
  Widget build(BuildContext context) {
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
        if (intense)
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.7, -0.85),
                radius: 1.1,
                colors: [Color(0x66D3EBE8), Color(0x00EEF2F6)],
              ),
            ),
          ),
        if (intense)
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.9, 0.2),
                radius: 0.95,
                colors: [Color(0x33A8BDD0), Color(0x00EEF2F6)],
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
