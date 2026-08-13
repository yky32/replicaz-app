enum ConversationType { direct, group }

class Conversation {
  const Conversation({
    required this.id,
    required this.type,
    required this.ownerIdentityId,
    required this.createdByUserId,
    this.title,
    required this.lastSequence,
    this.lastMessageAt,
    this.lastMessagePreview,
    this.lastReadSequence = '0',
    this.unreadCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final ConversationType type;
  final String ownerIdentityId;
  final String createdByUserId;
  final String? title;
  final String lastSequence;
  final DateTime? lastMessageAt;
  final String? lastMessagePreview;
  final String lastReadSequence;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get hasUnread => unreadCount > 0;

  Conversation copyWith({
    String? title,
    String? lastSequence,
    DateTime? lastMessageAt,
    String? lastMessagePreview,
    String? lastReadSequence,
    int? unreadCount,
    DateTime? updatedAt,
  }) {
    return Conversation(
      id: id,
      type: type,
      ownerIdentityId: ownerIdentityId,
      createdByUserId: createdByUserId,
      title: title ?? this.title,
      lastSequence: lastSequence ?? this.lastSequence,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      lastReadSequence: lastReadSequence ?? this.lastReadSequence,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'ownerIdentityId': ownerIdentityId,
        'createdByUserId': createdByUserId,
        'title': title,
        'lastSequence': lastSequence,
        'lastMessageAt': lastMessageAt?.toIso8601String(),
        'lastMessagePreview': lastMessagePreview,
        'lastReadSequence': lastReadSequence,
        'unreadCount': unreadCount,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      type: ConversationType.values.byName(json['type'] as String),
      ownerIdentityId:
          json['ownerIdentityId'] as String? ?? json['owner_identity_id'] as String,
      createdByUserId: json['createdByUserId'] as String? ??
          json['created_by_user_id'] as String,
      title: json['title'] as String?,
      lastSequence:
          '${json['lastSequence'] ?? json['last_sequence'] ?? '0'}',
      lastMessageAt: (json['lastMessageAt'] ?? json['last_message_at']) != null
          ? DateTime.parse(
              (json['lastMessageAt'] ?? json['last_message_at']) as String,
            )
          : null,
      lastMessagePreview: json['lastMessagePreview'] as String? ??
          json['last_message_preview'] as String?,
      lastReadSequence:
          '${json['lastReadSequence'] ?? json['last_read_sequence'] ?? '0'}',
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(
        json['createdAt'] as String? ?? json['created_at'] as String,
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] as String? ?? json['updated_at'] as String,
      ),
    );
  }
}
