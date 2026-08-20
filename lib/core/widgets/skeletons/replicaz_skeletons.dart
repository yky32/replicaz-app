import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:replicaz/app/theme/app_colors.dart';
import 'package:replicaz/app/theme/app_spacing.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// ClipVal-style loading chrome.
///
/// Rules:
/// - Cold open / empty+loading → skeleton (this file)
/// - Ready + empty → EmptyState (not here)
/// - Loading + has data → [SkeletonOverlay] bones on real list
///
/// Shimmer tuned for light “sea glass” surfaces so bones are obvious on device.

ShimmerEffect get _replicazShimmer => ShimmerEffect(
      baseColor: const Color(0xFFCDD8E4),
      highlightColor: const Color(0xFFF8FBFD),
      duration: const Duration(milliseconds: 950),
    );

/// Minimum time lists stay in loading so skeleton can paint (ClipVal ~280–320ms;
/// we use longer on first paint so TF dogfood can actually see it).
const kReplicazMinSkeleton = Duration(milliseconds: 720);

class InboxSkeleton extends StatelessWidget {
  const InboxSkeleton({super.key, this.rowCount = 8});

  final int rowCount;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      ignoreContainers: false,
      effect: _replicazShimmer,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          8,
          8,
          8,
          AppSpacing.listBottomInset(context),
        ),
        itemCount: rowCount,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              leading: Bone.circle(size: 48),
              title: Bone.text(
                words: index.isEven ? 3 : 2,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Bone.text(
                  words: index % 3 == 0 ? 6 : 4,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              trailing: Bone.text(
                words: 1,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          );
        },
      ),
    );
  }
}

class PeopleSkeleton extends StatelessWidget {
  const PeopleSkeleton({super.key, this.rowCount = 7});

  final int rowCount;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      effect: _replicazShimmer,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          8,
          8,
          8,
          AppSpacing.listBottomInset(context),
        ),
        itemCount: rowCount,
        itemBuilder: (context, index) {
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            leading: Bone.circle(size: 48),
            title: Bone.text(words: 2, style: const TextStyle(fontSize: 16)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Bone.text(words: 4, style: const TextStyle(fontSize: 13)),
            ),
          );
        },
      ),
    );
  }
}

class NotesSkeleton extends StatelessWidget {
  const NotesSkeleton({super.key, this.rowCount = 5});

  final int rowCount;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      effect: _replicazShimmer,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          AppSpacing.listBottomInset(context),
        ),
        itemCount: rowCount,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.hairline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Bone.text(words: 3, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 12),
                  Bone.multiText(lines: 2, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class FollowUpsSkeleton extends StatelessWidget {
  const FollowUpsSkeleton({super.key, this.rowCount = 5});

  final int rowCount;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      effect: _replicazShimmer,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          AppSpacing.listBottomInset(context),
        ),
        itemCount: rowCount,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.hairline),
              ),
              child: Row(
                children: [
                  Bone.circle(size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Bone.text(words: 4, style: const TextStyle(fontSize: 15)),
                        const SizedBox(height: 8),
                        Bone.text(words: 3, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class IdentitiesSkeleton extends StatelessWidget {
  const IdentitiesSkeleton({super.key, this.rowCount = 3});

  final int rowCount;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      effect: _replicazShimmer,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: rowCount,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Bone.circle(size: 48),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Bone.text(words: 1, style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 8),
                        Bone.text(words: 4, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class ThreadMessagesSkeleton extends StatelessWidget {
  const ThreadMessagesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      effect: _replicazShimmer,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
        children: [
          _bubble(mine: false, w: 0.72),
          const SizedBox(height: 12),
          _bubble(mine: true, w: 0.48),
          const SizedBox(height: 12),
          _bubble(mine: false, w: 0.58),
          const SizedBox(height: 12),
          _bubble(mine: true, w: 0.66),
          const SizedBox(height: 12),
          _bubble(mine: false, w: 0.40),
          const SizedBox(height: 12),
          _bubble(mine: true, w: 0.55),
          const SizedBox(height: 12),
          _bubble(mine: false, w: 0.70),
        ],
      ),
    );
  }

  Widget _bubble({required bool mine, required double w}) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: w,
        child: Bone(
          height: 48,
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}

/// In-place bone overlay while refreshing non-empty lists (ClipVal).
class SkeletonOverlay extends StatelessWidget {
  const SkeletonOverlay({
    super.key,
    required this.enabled,
    required this.child,
  });

  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: enabled,
      ignoreContainers: false,
      effect: _replicazShimmer,
      child: child,
    );
  }
}
