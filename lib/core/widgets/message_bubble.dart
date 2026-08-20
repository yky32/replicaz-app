import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:replicaz/app/theme/app_colors.dart';
import 'package:replicaz/core/widgets/replicaz_bottom_sheet.dart';
import 'package:replicaz/app/theme/app_type.dart';
import 'package:replicaz/features/follow_ups/presentation/create_follow_up_sheet.dart';
import 'package:replicaz/features/messaging/domain/chat_message.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.body,
    required this.mine,
    required this.timeLabel,
    this.showTail = true,
    this.deliveryStatus,
    this.onRetry,
    this.contactName = '',
    this.onFollowUp,
  });

  final String body;
  final bool mine;
  final String timeLabel;
  final bool showTail;
  final MessageDeliveryStatus? deliveryStatus;
  final VoidCallback? onRetry;
  /// Peer / thread title for follow-up prefills.
  final String contactName;
  final VoidCallback? onFollowUp;

  Future<void> _openActions(BuildContext context) async {
    HapticFeedback.mediumImpact();
    await ReplicazBottomSheet.show<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              4,
              20,
              12 + MediaQuery.paddingOf(sheetContext).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Message', style: AppType.titleMd()),
                const SizedBox(height: 6),
                Text(
                  body,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.bodySm(),
                ),
                const SizedBox(height: 14),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.add_task_rounded),
                  title: const Text('Add follow-up'),
                  subtitle: Text(
                    contactName.isEmpty
                        ? 'Save a next step from this message'
                        : 'For $contactName',
                    style: AppType.caption(),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    if (onFollowUp != null) {
                      onFollowUp!();
                    } else {
                      showCreateFollowUpSheet(
                        context,
                        initialTitle: body.length > 48
                            ? '${body.substring(0, 48)}…'
                            : body,
                        contactName: contactName,
                        initialDetails: body,
                      );
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.copy_rounded),
                  title: const Text('Copy text'),
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: body));
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final failed = deliveryStatus == MessageDeliveryStatus.failed;
    final pending = deliveryStatus == MessageDeliveryStatus.pending;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: Radius.circular(mine ? 20 : (showTail ? 6 : 20)),
      bottomRight: Radius.circular(mine ? (showTail ? 6 : 20) : 20),
    );

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Column(
          crossAxisAlignment:
              mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Opacity(
              opacity: pending ? 0.72 : 1,
              child: GestureDetector(
                onLongPress: () => _openActions(context),
                child: Container(
                  margin: EdgeInsets.only(
                    top: 2,
                    bottom: showTail && !failed ? 8 : 2,
                    left: mine ? 48 : 0,
                    right: mine ? 0 : 48,
                  ),
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                  decoration: BoxDecoration(
                    color: failed
                        ? AppColors.bubbleMine.withValues(alpha: 0.55)
                        : (mine
                            ? AppColors.bubbleMine
                            : AppColors.bubbleTheirs),
                    borderRadius: radius,
                    border: failed
                        ? Border.all(
                            color: Colors.redAccent.withValues(alpha: 0.5),
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color:
                            AppColors.ink.withValues(alpha: mine ? 0.12 : 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: mine
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        body,
                        style: GoogleFonts.plusJakartaSans(
                          color:
                              mine ? AppColors.bubbleMineText : AppColors.ink,
                          fontSize: 15.5,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: mine
                              ? AppColors.bubbleMineText.withValues(alpha: 0.55)
                              : AppColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (failed && mine)
              Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 8),
                child: GestureDetector(
                  onTap: onRetry,
                  child: Text(
                    'Not sent · Tap to retry',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent.shade200,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
