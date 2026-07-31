enum MessageDeliveryStatus { pending, accepted, sent, delivered, failed }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.clientMessageId,
    required this.senderUserId,
    required this.senderIdentityId,
    required this.body,
    required this.sequence,
    required this.deliveryStatus,
    required this.createdAt,
    this.serverReceivedAt,
  });

  final String id;
  final String conversationId;

  /// Idempotency key — retries must reuse the same value.
  final String clientMessageId;
  final String senderUserId;
  final String senderIdentityId;
  final String body;

  /// Monotonic per conversation; use string to preserve bigint precision.
  final String sequence;
  final MessageDeliveryStatus deliveryStatus;
  final DateTime createdAt;
  final DateTime? serverReceivedAt;

  ChatMessage copyWith({
    String? id,
    MessageDeliveryStatus? deliveryStatus,
    String? sequence,
    DateTime? serverReceivedAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId,
      clientMessageId: clientMessageId,
      senderUserId: senderUserId,
      senderIdentityId: senderIdentityId,
      body: body,
      sequence: sequence ?? this.sequence,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      createdAt: createdAt,
      serverReceivedAt: serverReceivedAt ?? this.serverReceivedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversationId': conversationId,
        'clientMessageId': clientMessageId,
        'senderUserId': senderUserId,
        'senderIdentityId': senderIdentityId,
        'body': body,
        'sequence': sequence,
        'deliveryStatus': deliveryStatus.name,
        'createdAt': createdAt.toIso8601String(),
        'serverReceivedAt': serverReceivedAt?.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final statusRaw =
        (json['deliveryStatus'] ?? json['delivery_status'] ?? 'pending') as String;
    return ChatMessage(
      id: json['id'] as String,
      conversationId:
          json['conversationId'] as String? ?? json['conversation_id'] as String,
      clientMessageId: json['clientMessageId'] as String? ??
          json['client_message_id'] as String,
      senderUserId:
          json['senderUserId'] as String? ?? json['sender_user_id'] as String,
      senderIdentityId: json['senderIdentityId'] as String? ??
          json['sender_identity_id'] as String,
      body: json['body'] as String,
      sequence: '${json['sequence']}',
      deliveryStatus: MessageDeliveryStatus.values.firstWhere(
        (e) => e.name == statusRaw,
        orElse: () => MessageDeliveryStatus.pending,
      ),
      createdAt: DateTime.parse(
        json['createdAt'] as String? ?? json['created_at'] as String,
      ),
      serverReceivedAt:
          (json['serverReceivedAt'] ?? json['server_received_at']) != null
              ? DateTime.parse(
                  (json['serverReceivedAt'] ?? json['server_received_at'])
                      as String,
                )
              : null,
    );
  }
}
