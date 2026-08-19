import 'package:flutter/material.dart';
import 'package:replicaz/app/theme/app_colors.dart';
import 'package:replicaz/app/theme/app_motion.dart';
import 'package:replicaz/app/theme/app_type.dart';
import 'package:replicaz/core/widgets/initials_avatar.dart';

/// Unified list cell (Uber Base list-row pattern) for chats / people / notes meta.
class LifeListCell extends StatelessWidget {
  const LifeListCell({
    super.key,
    required this.title,
    this.subtitle,
    this.meta,
    this.leadingLabel,
    this.leading,
    this.trailing,
    this.accent,
    this.emphasized = false,
    this.onTap,
    this.onLongPress,
    this.dense = false,
  });

  final String title;
  final String? subtitle;
  final String? meta;
  final String? leadingLabel;
  final Widget? leading;
  final Widget? trailing;
  final Color? accent;
  final bool emphasized;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppColors.accent;
    final padV = dense ? 10.0 : 12.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppColors.surfaceRaised.withValues(alpha: 0.9),
              border: Border.all(
                color: emphasized
                    ? color.withValues(alpha: 0.38)
                    : AppColors.hairline.withValues(alpha: 0.9),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.035),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: AnimatedContainer(
              duration: AppMotion.fast,
              padding: EdgeInsets.fromLTRB(12, padV, 14, padV),
              child: Row(
                children: [
                  leading ??
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: color.withValues(
                              alpha: emphasized ? 0.7 : 0.28,
                            ),
                            width: emphasized ? 2 : 1.2,
                          ),
                        ),
                        child: InitialsAvatar(
                          label: leadingLabel ?? title,
                          color: color,
                          size: dense ? 44 : 48,
                        ),
                      ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppType.titleSm(),
                              ),
                            ),
                            if (meta != null && meta!.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                meta!,
                                style: AppType.caption(
                                  color: emphasized ? color : AppColors.inkMuted,
                                ).copyWith(
                                  fontWeight: emphasized
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.bodySm(
                              color: emphasized
                                  ? AppColors.ink.withValues(alpha: 0.78)
                                  : AppColors.inkMuted,
                            ).copyWith(
                              fontWeight: emphasized
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    trailing!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small count / status pill for list cells.
class LifeMetaBadge extends StatelessWidget {
  const LifeMetaBadge({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.32),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: AppType.labelSm(color: Colors.white).copyWith(fontSize: 11),
      ),
    );
  }
}
