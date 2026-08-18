import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:replicaz/app/theme/app_colors.dart';
import 'package:replicaz/app/theme/app_spacing.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.chat_bubble_outline_rounded,
    this.accent,
    this.hint,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;
  final Color? accent;

  /// Optional tip under the CTA (e.g. how to switch life).
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppColors.accentDeep;

    return Center(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          36,
          36,
          36,
          AppSpacing.listBottomInset(context) + 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.08),
                  ),
                ),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.16),
                    border: Border.all(color: color.withValues(alpha: 0.25)),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 30, color: color),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.syne(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: AppColors.ink,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.inkMuted,
                height: 1.5,
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(180, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
            if (hint != null) ...[
              const SizedBox(height: 16),
              Text(
                hint!,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  height: 1.4,
                  color: AppColors.inkMuted.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
