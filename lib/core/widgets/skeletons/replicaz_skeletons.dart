import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:replicaz/app/theme/app_colors.dart';
import 'package:replicaz/app/theme/app_spacing.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// ClipVal-style: cold open uses mock chrome + [Skeletonizer] bones.
/// Ready+empty → EmptyState (not skeleton).

class InboxSkeleton extends StatelessWidget {
  const InboxSkeleton({super.key, this.rowCount = 7});

  final int rowCount;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      ignoreContainers: false,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          8,
          0,
          8,
          AppSpacing.listBottomInset(context),
        ),
        itemCount: rowCount,
        itemBuilder: (context, index) {
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            leading: const CircleAvatar(radius: 24),
            title: Text(
              index.isEven ? 'Conversation title here' : 'Another chat name',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              index % 3 == 0
                  ? 'Last message preview goes here for loading'
                  : 'Short preview line…',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.inkMuted),
            ),
            trailing: Text(
              '12:34',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.inkMuted,
              ),
            ),
          );
        },
      ),
    );
  }
}

class PeopleSkeleton extends StatelessWidget {
  const PeopleSkeleton({super.key, this.rowCount = 6});

  final int rowCount;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          8,
          0,
          8,
          AppSpacing.listBottomInset(context),
        ),
        itemCount: rowCount,
        itemBuilder: (context, index) {
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            leading: const CircleAvatar(radius: 24),
            title: Text(
              index.isEven ? 'Contact full name' : 'Someone else',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
            subtitle: const Text(
              'Company · email@domain.com',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.inkMuted),
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
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          16,
          4,
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
                  Text(
                    index.isEven ? 'Note title placeholder' : 'Another note',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Body preview text for skeleton loading state content.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.inkMuted,
                      height: 1.35,
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

class FollowUpsSkeleton extends StatelessWidget {
  const FollowUpsSkeleton({super.key, this.rowCount = 5});

  final int rowCount;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          16,
          4,
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
                  const Icon(Icons.check_circle_outline, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Follow-up task title line',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Due detail placeholder',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.inkMuted,
                          ),
                        ),
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
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
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
                  const CircleAvatar(radius: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          index == 0
                              ? 'Personal'
                              : (index == 1 ? 'Job' : 'Freelance'),
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const Text(
                          'Tagline placeholder text',
                          style: TextStyle(color: AppColors.inkMuted),
                        ),
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
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
        children: const [
          _BubbleBone(mine: false, wide: true),
          SizedBox(height: 10),
          _BubbleBone(mine: true, wide: false),
          SizedBox(height: 10),
          _BubbleBone(mine: false, wide: false),
          SizedBox(height: 10),
          _BubbleBone(mine: true, wide: true),
          SizedBox(height: 10),
          _BubbleBone(mine: false, wide: true),
          SizedBox(height: 10),
          _BubbleBone(mine: true, wide: false),
        ],
      ),
    );
  }
}

class _BubbleBone extends StatelessWidget {
  const _BubbleBone({required this.mine, required this.wide});

  final bool mine;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: wide ? 220 : 140,
        height: 44,
        decoration: BoxDecoration(
          color: mine ? AppColors.bubbleMine : AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Text(
          wide ? 'Message body placeholder text' : 'Short msg',
          style: TextStyle(
            color: mine ? AppColors.bubbleMineText : AppColors.ink,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

/// Optional in-place bone overlay while refreshing non-empty lists (ClipVal).
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
      child: child,
    );
  }
}
