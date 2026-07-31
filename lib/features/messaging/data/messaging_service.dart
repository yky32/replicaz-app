import 'package:replicaz/core/config/app_config.dart';
import 'package:replicaz/core/constants/storage_keys.dart';
import 'package:replicaz/core/storage/local_store.dart';
import 'package:replicaz/features/messaging/data/remote_messaging_api.dart';
import 'package:replicaz/features/messaging/domain/chat_message.dart';
import 'package:replicaz/features/messaging/domain/conversation.dart';
import 'package:uuid/uuid.dart';

class MessagingService {
  MessagingService({
    required this.store,
    this.remote,
  });

  final LocalStore store;
  final RemoteMessagingApi? remote;
  final _uuid = const Uuid();

  bool get _remote => AppConfig.useRemoteBackend && remote != null;

  List<Conversation> _readConversations() => store
      .getJsonList(StorageKeys.conversations)
      .map(Conversation.fromJson)
      .toList();

  Future<void> _writeConversations(List<Conversation> items) => store.setJson(
        StorageKeys.conversations,
        items.map((e) => e.toJson()).toList(),
      );

  List<ChatMessage> _readMessages() =>
      store.getJsonList(StorageKeys.messages).map(ChatMessage.fromJson).toList();

  Future<void> _writeMessages(List<ChatMessage> items) => store.setJson(
        StorageKeys.messages,
        items.map((e) => e.toJson()).toList(),
      );

  Future<List<RemoteUser>> listUsers() async {
    if (!_remote) return const [];
    return remote!.listUsers();
  }

  Future<List<Conversation>> conversationsForIdentity(String identityId) async {
    if (_remote) {
      return remote!.myRooms(identityId: identityId);
    }
    return _readConversations()
        .where((c) => c.ownerIdentityId == identityId)
        .toList()
      ..sort((a, b) {
        final aAt = a.lastMessageAt ?? a.createdAt;
        final bAt = b.lastMessageAt ?? b.createdAt;
        return bAt.compareTo(aAt);
      });
  }

  Future<Conversation> createDirectConversation({
    required String ownerIdentityId,
    required String createdByUserId,
    String? title,
    String? participantUserId,
  }) async {
    if (_remote) {
      if (participantUserId == null || participantUserId.isEmpty) {
        throw StateError('Pick a user to chat with');
      }
      return remote!.createRoom(
        identityId: ownerIdentityId,
        participantUserId: participantUserId,
        title: title,
      );
    }
    final now = DateTime.now().toUtc();
    final conversation = Conversation(
      id: _uuid.v4(),
      type: ConversationType.direct,
      ownerIdentityId: ownerIdentityId,
      createdByUserId: createdByUserId,
      title: title,
      lastSequence: '0',
      createdAt: now,
      updatedAt: now,
    );
    final items = _readConversations()..add(conversation);
    await _writeConversations(items);
    return conversation;
  }

  Future<List<ChatMessage>> messagesFor(
    String conversationId, {
    String identityId = '',
  }) async {
    if (_remote) {
      return remote!.roomMessages(
        roomId: conversationId,
        identityId: identityId,
      );
    }
    return _readMessages()
        .where((m) => m.conversationId == conversationId)
        .toList()
      ..sort(
        (a, b) => BigInt.parse(a.sequence).compareTo(BigInt.parse(b.sequence)),
      );
  }

  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String senderUserId,
    required String senderIdentityId,
    required String body,
  }) async {
    if (_remote) {
      await remote!.sendMessage(roomId: conversationId, content: body);
      final now = DateTime.now().toUtc();
      return ChatMessage(
        id: _uuid.v4(),
        conversationId: conversationId,
        clientMessageId: _uuid.v4(),
        senderUserId: senderUserId,
        senderIdentityId: senderIdentityId,
        body: body,
        sequence: '${now.millisecondsSinceEpoch}',
        deliveryStatus: MessageDeliveryStatus.sent,
        createdAt: now,
        serverReceivedAt: now,
      );
    }

    final clientMessageId = _uuid.v4();
    final conversations = _readConversations();
    final index = conversations.indexWhere((c) => c.id == conversationId);
    if (index < 0) throw StateError('Conversation not found');

    final current = conversations[index];
    final nextSequence =
        (BigInt.parse(current.lastSequence) + BigInt.one).toString();
    final now = DateTime.now().toUtc();

    final message = ChatMessage(
      id: clientMessageId,
      conversationId: conversationId,
      clientMessageId: clientMessageId,
      senderUserId: senderUserId,
      senderIdentityId: senderIdentityId,
      body: body,
      sequence: nextSequence,
      deliveryStatus: MessageDeliveryStatus.sent,
      createdAt: now,
      serverReceivedAt: now,
    );

    final messages = _readMessages()..add(message);
    await _writeMessages(messages);

    conversations[index] = Conversation(
      id: current.id,
      type: current.type,
      ownerIdentityId: current.ownerIdentityId,
      createdByUserId: current.createdByUserId,
      title: current.title,
      lastSequence: nextSequence,
      lastMessageAt: now,
      lastReadSequence: current.lastReadSequence,
      createdAt: current.createdAt,
      updatedAt: now,
    );
    await _writeConversations(conversations);
    return message;
  }
}
