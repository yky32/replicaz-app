import 'package:flutter/material.dart';
import 'package:replicaz/app/theme/app_colors.dart';

/// Modal sheets must use the root navigator so they sit above the floating
/// nav island (shell Stack overlays branch navigators).
abstract final class ReplicazBottomSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isScrollControlled = false,
    bool showDragHandle = true,
    Color? backgroundColor,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: isScrollControlled,
      showDragHandle: showDragHandle,
      backgroundColor: backgroundColor ?? AppColors.surfaceRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: builder,
    );
  }
}
