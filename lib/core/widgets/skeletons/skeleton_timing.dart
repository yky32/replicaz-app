import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Min paint time for cold-open skeletons (ClipVal-style).
///
/// Disabled under `flutter test` so widget/bloc tests don't stall on timers.
Duration get replicazMinSkeletonDuration {
  if (!kIsWeb) {
    try {
      if (Platform.environment.containsKey('FLUTTER_TEST')) {
        return Duration.zero;
      }
    } catch (_) {}
  }
  // Visible on device / TestFlight (~0.7s shimmer).
  return const Duration(milliseconds: 720);
}

Future<void> awaitReplicazMinSkeleton(Stopwatch sw) async {
  final remaining = replicazMinSkeletonDuration - sw.elapsed;
  if (remaining > Duration.zero) {
    await Future<void>.delayed(remaining);
  }
}
