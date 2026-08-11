import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:replicaz/app/theme/app_colors.dart';
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
  });

  final String body;
  final bool mine;
  final String timeLabel;
  final bool showTail;
  final MessageDeliveryStatus? deliveryStatus;
  final VoidCallback? onRetry;

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
                      : (mine ? AppColors.bubbleMine : AppColors.bubbleTheirs),
                  borderRadius: radius,
                  border: failed
                      ? Border.all(color: Colors.redAccent.withValues(alpha: 0.5))
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ink.withValues(alpha: mine ? 0.12 : 0.04),
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
                        color: mine ? AppColors.bubbleMineText : AppColors.ink,
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
