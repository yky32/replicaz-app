import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Min paint time for **cold** skeletons only.
///
/// Artificial 700ms+ delays made tab/life switches feel broken. Warm loads
/// (cache hit / instant fixtures) skip the delay entirely.
Duration get replicazMinSkeletonDuration {
  if (!kIsWeb) {
    try {
      if (Platform.environment.containsKey('FLUTTER_TEST')) {
        return Duration.zero;
      }
    } catch (_) {}
  }
  // Short beat only when we truly need a first paint shimmer.
  return const Duration(milliseconds: 180);
}

bool _coldSkeletonUsed = false;

/// Call only on true cold empty→first data paint (not every identity switch).
Future<void> awaitReplicazMinSkeleton(Stopwatch sw, {bool coldOnly = true}) async {
  if (coldOnly && _coldSkeletonUsed) return;
  final remaining = replicazMinSkeletonDuration - sw.elapsed;
  if (remaining > Duration.zero) {
    await Future<void>.delayed(remaining);
  }
  if (coldOnly) _coldSkeletonUsed = true;
}

Future<void> awaitReplicazPullRefreshSkeleton(Stopwatch sw) async {
  const min = Duration(milliseconds: 420);
  final remaining = min - sw.elapsed;
  if (remaining > Duration.zero) {
    await Future<void>.delayed(remaining);
  }
}

