import 'package:replicaz/core/network/api_client.dart';
import 'package:replicaz/features/messaging/domain/chat_message.dart';
import 'package:replicaz/features/messaging/domain/conversation.dart';

class RemoteUser {
  const RemoteUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.alias,
  });

  final String id;
  final String email;
  final String displayName;
  final String alias;

  factory RemoteUser.fromJson(Map<String, dynamic> json) => RemoteUser(
        id: json['id'] as String,
        email: json['email'] as String,
        displayName: json['displayName'] as String? ?? '',
        alias: json['alias'] as String? ?? '',
      );
}

/// Messenger REST client — mirrors tgt-rn `/msgr/chat/*`.
class RemoteMessagingApi {
  RemoteMessagingApi(this.api);

  final ApiClient api;

  Future<List<RemoteUser>> listUsers() async {
    final res = await api.dio.get('/users');
    final data = (res.data['data'] as List? ?? const []);
    return data
        .map((e) => RemoteUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Conversation>> myRooms({required String identityId}) async {
    final res = await api.dio.get('/chat/my-rooms');
    final data = (res.data['data'] as List? ?? const []);
    return data.map((raw) {
      final map = raw as Map<String, dynamic>;
      final meta = map['metadata'] as Map<String, dynamic>? ?? const {};
      final lastAt = meta['lastMessageAt'] as String?;
      final created = DateTime.parse(map['createDt'] as String);
      return Conversation(
        id: map['id'] as String,
        type: (map['type'] as String?) == 'group'
            ? ConversationType.group
            : ConversationType.direct,
        ownerIdentityId: identityId,
        createdByUserId: '',
        title: map['name'] as String?,
        lastSequence: '0',
        lastMessageAt: lastAt == null ? null : DateTime.parse(lastAt),
        createdAt: created,
        updatedAt: DateTime.parse(map['updateDt'] as String? ?? map['createDt'] as String),
      );
    }).toList();
  }

  Future<Conversation> createRoom({
    required String identityId,
    required String participantUserId,
    String? title,
  }) async {
    final res = await api.dio.post(
      '/chat/my-rooms',
      data: {
        'participantIds': [participantUserId],
        if (title != null && title.isNotEmpty) 'name': title,
      },
    );
    final map = res.data['data'] as Map<String, dynamic>;
    final created = DateTime.parse(map['createDt'] as String);
    return Conversation(
      id: map['id'] as String,
      type: (map['type'] as String?) == 'group'
          ? ConversationType.group
          : ConversationType.direct,
      ownerIdentityId: identityId,
      createdByUserId: '',
      title: map['name'] as String?,
      lastSequence: '0',
      createdAt: created,
      updatedAt: created,
    );
  }

  Future<List<ChatMessage>> roomMessages({
    required String roomId,
    required String identityId,
  }) async {
    final res = await api.dio.get('/chat/my-rooms/$roomId/messages');
    final data = (res.data['data'] as List? ?? const []);
    var seq = 0;
    return data.map((raw) {
      seq += 1;
      final map = raw as Map<String, dynamic>;
      final content = map['messageContent'] as Map<String, dynamic>? ?? {};
      final ts = content['sentTimestamp'];
      final created = ts is num
          ? DateTime.fromMillisecondsSinceEpoch(ts.toInt())
          : DateTime.parse(map['sentAt'] as String? ?? map['createDt'] as String);
      return ChatMessage(
        id: map['id'] as String,
        conversationId: roomId,
        clientMessageId: map['id'] as String,
        senderUserId: content['from'] as String? ?? '',
        senderIdentityId: identityId,
        body: content['content'] as String? ?? '',
        sequence: '$seq',
        deliveryStatus: MessageDeliveryStatus.delivered,
        createdAt: created.toUtc(),
        serverReceivedAt: created.toUtc(),
      );
    }).toList();
  }

  Future<void> sendMessage({
    required String roomId,
    required String content,
  }) async {
    await api.dio.post(
      '/chat/rooms/$roomId/messages',
      data: {'content': content},
    );
  }
}
