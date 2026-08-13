import 'package:dio/dio.dart';
import 'package:replicaz/core/errors/app_exception.dart';
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

/// Messenger REST client — mirrors tgt-rn `/msgr/chat/*` via Dio.
class RemoteMessagingApi {
  RemoteMessagingApi(this.api);

  final ApiClient api;

  Future<List<RemoteUser>> listUsers() async {
    try {
      final res = await api.dio.get('/users');
      final data = (res.data['data'] as List? ?? const []);
      return data
          .map((e) => RemoteUser.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.mapDio(e);
    }
  }

  Future<List<Conversation>> myRooms({required String identityId}) async {
    try {
      final res = await api.dio.get('/chat/my-rooms');
      final data = (res.data['data'] as List? ?? const []);
      return data.map((raw) {
        final map = raw as Map<String, dynamic>;
        final meta = map['metadata'] as Map<String, dynamic>? ?? const {};
        final lastAt = meta['lastMessageAt'] as String?;
        final preview = meta['lastMessagePreview'] as String?;
        final created = DateTime.parse(map['createDt'] as String);
        final title = _displayTitle(map, meta);
        return Conversation(
          id: map['id'] as String,
          type: (map['type'] as String?) == 'group'
              ? ConversationType.group
              : ConversationType.direct,
          ownerIdentityId: identityId,
          createdByUserId: '',
          title: title,
          lastSequence: '0',
          lastMessageAt: lastAt == null ? null : DateTime.parse(lastAt),
          lastMessagePreview: preview,
          createdAt: created,
          updatedAt: DateTime.parse(
            map['updateDt'] as String? ?? map['createDt'] as String,
          ),
        );
      }).toList();
    } on DioException catch (e) {
      throw ApiClient.mapDio(e);
    }
  }

  /// Prefer the other participant's name (room.name is set by creator and is often wrong for peer).
  static String? _displayTitle(
    Map<String, dynamic> map,
    Map<String, dynamic> meta,
  ) {
    final participants = meta['participants'] as List? ?? const [];
    for (final raw in participants) {
      if (raw is! Map) continue;
      final p = Map<String, dynamic>.from(raw);
      final isMe = p['isMe'] == true;
      if (!isMe) {
        final name = (p['name'] as String?)?.trim();
        final alias = (p['alias'] as String?)?.trim();
        if (name != null && name.isNotEmpty) return name;
        if (alias != null && alias.isNotEmpty) return alias;
      }
    }
    return map['name'] as String?;
  }

  Future<Conversation> createRoom({
    required String identityId,
    required String participantUserId,
    String? title,
  }) async {
    try {
      final res = await api.dio.post(
        '/chat/my-rooms',
        data: {
          'participantIds': [participantUserId],
          if (title != null && title.isNotEmpty) 'name': title,
        },
      );
      final map = res.data['data'] as Map<String, dynamic>;
      final meta = map['metadata'] as Map<String, dynamic>? ?? const {};
      final created = DateTime.parse(map['createDt'] as String);
      return Conversation(
        id: map['id'] as String,
        type: (map['type'] as String?) == 'group'
            ? ConversationType.group
            : ConversationType.direct,
        ownerIdentityId: identityId,
        createdByUserId: '',
        title: _displayTitle(map, meta) ?? title,
        lastSequence: '0',
        lastMessageAt: meta['lastMessageAt'] != null
            ? DateTime.parse(meta['lastMessageAt'] as String)
            : null,
        lastMessagePreview: meta['lastMessagePreview'] as String?,
        createdAt: created,
        updatedAt: created,
      );
    } on DioException catch (e) {
      throw ApiClient.mapDio(e);
    }
  }

  Future<List<ChatMessage>> roomMessages({
    required String roomId,
    required String identityId,
  }) async {
    try {
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
            : DateTime.parse(
                map['sentAt'] as String? ?? map['createDt'] as String,
              );
        final id = map['id'] as String;
        return ChatMessage(
          id: id,
          conversationId: roomId,
          clientMessageId: id,
          senderUserId: content['from'] as String? ?? '',
          senderIdentityId: identityId,
          body: content['content'] as String? ?? '',
          sequence: '$seq',
          deliveryStatus: MessageDeliveryStatus.delivered,
          createdAt: created.toUtc(),
          serverReceivedAt: created.toUtc(),
        );
      }).toList();
    } on DioException catch (e) {
      throw ApiClient.mapDio(e);
    }
  }

  /// Posts a message; returns server event payload as [ChatMessage].
  Future<ChatMessage> sendMessage({
    required String roomId,
    required String content,
    required String senderUserId,
    required String senderIdentityId,
    required String clientMessageId,
  }) async {
    try {
      final res = await api.dio.post(
        '/chat/rooms/$roomId/messages',
        data: {'content': content},
      );
      final data = res.data['data'] as Map<String, dynamic>? ?? {};
      final messageId =
          (data['messageId'] ?? data['id'] ?? clientMessageId).toString();
      final ts = data['sentTimestamp'];
      final created = ts is num
          ? DateTime.fromMillisecondsSinceEpoch(ts.toInt()).toUtc()
          : DateTime.now().toUtc();
      return ChatMessage(
        id: messageId,
        conversationId: roomId,
        clientMessageId: clientMessageId,
        senderUserId: (data['from'] as String?)?.isNotEmpty == true
            ? data['from'] as String
            : senderUserId,
        senderIdentityId: senderIdentityId,
        body: (data['content'] as String?) ?? content,
        sequence: '${created.millisecondsSinceEpoch}',
        deliveryStatus: MessageDeliveryStatus.sent,
        createdAt: created,
        serverReceivedAt: created,
      );
    } on DioException catch (e) {
      throw ApiClient.mapDio(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Failed to send message', cause: e);
    }
  }
}
