import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:replicaz/app/theme/app_colors.dart';

class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.label,
    this.color = AppColors.accent,
    this.size = 48,
  });

  final String label;
  final Color color;
  final double size;

  String get _initials {
    final parts = label.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.92),
            Color.lerp(color, AppColors.ink, 0.28)!,
          ],
        ),
      ),
      child: Text(
        _initials,
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.34,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}
