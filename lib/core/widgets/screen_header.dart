import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:replicaz/app/theme/app_colors.dart';
import 'package:replicaz/features/identities/presentation/widgets/identity_switcher_bar.dart';

/// Shared tab / stack header — brand eyebrow + page title + trailing actions.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.eyebrow = 'Replicaz',
    this.subtitle,
    this.subtitleColor,
    this.showIdentitySwitcher = true,
    this.leading,
    this.actions = const [],
  });

  final String title;
  final String? eyebrow;
  final String? subtitle;
  final Color? subtitleColor;
  final bool showIdentitySwitcher;
  final Widget? leading;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(leading == null ? 20 : 8, 8, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leading != null) ?leading,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null) ...[
                  Text(
                    eyebrow!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.syne(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: AppColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.syne(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.7,
                    height: 1.05,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      color: subtitleColor ?? AppColors.inkMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (showIdentitySwitcher) ...[
            const SizedBox(width: 8),
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: IdentitySwitcherBar(),
            ),
          ],
          ...actions.map(
            (action) => Padding(
              padding: const EdgeInsets.only(top: 2),
              child: IconTheme.merge(
                data: const IconThemeData(size: 22),
                child: action,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
