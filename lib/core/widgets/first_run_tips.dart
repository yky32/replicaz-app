import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:replicaz/app/theme/app_colors.dart';
import 'package:replicaz/app/theme/app_type.dart';
import 'package:replicaz/core/bootstrap/app_bootstrap.dart';
import 'package:replicaz/core/widgets/replicaz_bottom_sheet.dart';

/// One-time soft-launch coach after first demo entry.
abstract final class FirstRunTips {
  static const _key = 'first_run_tips_seen';

  static bool get seen =>
      AppBootstrap.store.getString(_key) == '1';

  static Future<void> markSeen() =>
      AppBootstrap.store.setString(_key, '1');

  static Future<void> showIfNeeded(BuildContext context) async {
    if (seen || !context.mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!context.mounted || seen) return;

    await ReplicazBottomSheet.show<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              22,
              8,
              22,
              18 + MediaQuery.paddingOf(sheetContext).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Three places. One self at a time.', style: AppType.titleLg()),
                const SizedBox(height: 10),
                Text(
                  'Replicaz keeps Job, Personal, and Freelance from mixing.',
                  style: AppType.bodySm(color: AppColors.inkSoft),
                ),
                const SizedBox(height: 18),
                _tip(Icons.chat_bubble_rounded, 'Chats', 'Talk as the life you’re in.'),
                _tip(Icons.people_rounded, 'Circle', 'People for this life only.'),
                _tip(Icons.grid_view_rounded, 'Desk', 'Notes + follow-ups for this life.'),
                const SizedBox(height: 8),
                _tip(
                  Icons.touch_app_rounded,
                  'Life pill',
                  'Tap to switch · long-press to Focus.',
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () async {
                    await markSeen();
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                  child: const Text('Got it — start demo'),
                ),
                TextButton(
                  onPressed: () async {
                    await markSeen();
                    if (sheetContext.mounted) {
                      Navigator.pop(sheetContext);
                      context.push('/identities');
                    }
                  },
                  child: const Text('Manage lives first'),
                ),
              ],
            ),
          ),
        );
      },
    );
    await markSeen();
  }

  static Widget _tip(IconData icon, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.accentSoft,
            child: Icon(icon, size: 18, color: AppColors.accentDeep),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppType.labelLg()),
                Text(body, style: AppType.bodySm()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
