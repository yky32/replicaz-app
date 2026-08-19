import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:replicaz/app/theme/app_colors.dart';
import 'package:replicaz/app/theme/app_motion.dart';
import 'package:replicaz/app/theme/app_type.dart';

/// Compact status strip (Uber-style context banner).
class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline_rounded,
    this.tone = StatusBannerTone.warning,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final IconData icon;
  final StatusBannerTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = switch (tone) {
      StatusBannerTone.warning => (
          bg: const Color(0xFFFFF4E5),
          fg: const Color(0xFF8A4B00),
          icon: const Color(0xFFC27803),
          border: const Color(0xFFE8C48A),
        ),
      StatusBannerTone.danger => (
          bg: AppColors.danger.withValues(alpha: 0.1),
          fg: AppColors.danger,
          icon: AppColors.danger,
          border: AppColors.danger.withValues(alpha: 0.28),
        ),
      StatusBannerTone.info => (
          bg: AppColors.accentSoft.withValues(alpha: 0.65),
          fg: AppColors.accentDeep,
          icon: AppColors.accentDeep,
          border: AppColors.accent.withValues(alpha: 0.25),
        ),
      StatusBannerTone.life => (
          bg: AppColors.ink.withValues(alpha: 0.04),
          fg: AppColors.ink,
          icon: AppColors.inkSoft,
          border: AppColors.hairline,
        ),
    };

    return Material(
      color: scheme.bg,
      child: InkWell(
        onTap: onAction == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onAction!();
              },
        child: AnimatedContainer(
          duration: AppMotion.fast,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: scheme.border),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: scheme.icon),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: AppType.bodySm(color: scheme.fg).copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12.8,
                  ),
                ),
              ),
              if (actionLabel != null) ...[
                const SizedBox(width: 8),
                Text(
                  actionLabel!,
                  style: AppType.labelMd(color: scheme.fg).copyWith(
                    decoration: TextDecoration.underline,
                    decorationColor: scheme.fg.withValues(alpha: 0.4),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 18, color: scheme.fg),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum StatusBannerTone { warning, danger, info, life }
