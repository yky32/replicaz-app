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

  // ── room ↔ identity bindings (client-side; messenger has no identity) ──

  Map<String, String> _readBindings() {
    final map = store.getJsonMap(StorageKeys.roomIdentityBindings);
    if (map == null) return {};
    return map.map((k, v) => MapEntry(k, v.toString()));
  }

  Future<void> _writeBindings(Map<String, String> bindings) =>
      store.setJson(StorageKeys.roomIdentityBindings, bindings);

  Future<void> bindRoomToIdentity({
    required String roomId,
    required String identityId,
  }) async {
    final bindings = _readBindings();
    bindings[roomId] = identityId;
    await _writeBindings(bindings);
  }

  String? identityIdForRoom(String roomId) => _readBindings()[roomId];

  Set<String> roomIdsForIdentity(String identityId) {
    return _readBindings().entries
        .where((e) => e.value == identityId)
        .map((e) => e.key)
        .toSet();
  }

  // ── local conversation store ──

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

  /// Conversations owned by [identityId] only — never leaks across lives.
  Future<List<Conversation>> conversationsForIdentity(String identityId) async {
    if (_remote) {
      final rooms = await remote!.myRooms(identityId: identityId);
      final owned = roomIdsForIdentity(identityId);
      // Filter to rooms bound to this identity. Stamp ownerIdentityId.
      final filtered = rooms
          .where((r) => owned.contains(r.id))
          .map(
            (r) => Conversation(
              id: r.id,
              type: r.type,
              ownerIdentityId: identityId,
              createdByUserId: r.createdByUserId,
              title: r.title,
              lastSequence: r.lastSequence,
              lastMessageAt: r.lastMessageAt,
              lastMessagePreview: r.lastMessagePreview,
              lastReadSequence: r.lastReadSequence,
              createdAt: r.createdAt,
              updatedAt: r.updatedAt,
            ),
          )
          .toList()
        ..sort((a, b) {
          final aAt = a.lastMessageAt ?? a.createdAt;
          final bAt = b.lastMessageAt ?? b.createdAt;
          return bAt.compareTo(aAt);
        });
      return filtered;
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
      final room = await remote!.createRoom(
        identityId: ownerIdentityId,
        participantUserId: participantUserId,
        title: title,
      );
      await bindRoomToIdentity(
        roomId: room.id,
        identityId: ownerIdentityId,
      );
      return Conversation(
        id: room.id,
        type: room.type,
        ownerIdentityId: ownerIdentityId,
        createdByUserId: createdByUserId,
        title: room.title ?? title,
        lastSequence: room.lastSequence,
        lastMessageAt: room.lastMessageAt,
        lastMessagePreview: room.lastMessagePreview,
        lastReadSequence: room.lastReadSequence,
        createdAt: room.createdAt,
        updatedAt: room.updatedAt,
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
    String? clientMessageId,
  }) async {
    final clientId = clientMessageId ?? _uuid.v4();

    if (_remote) {
      // Ensure room stays bound to the identity that sent from it.
      final existing = identityIdForRoom(conversationId);
      if (existing == null) {
        await bindRoomToIdentity(
          roomId: conversationId,
          identityId: senderIdentityId,
        );
      }
      return remote!.sendMessage(
        roomId: conversationId,
        content: body,
        senderUserId: senderUserId,
        senderIdentityId: senderIdentityId,
        clientMessageId: clientId,
      );
    }

    final conversations = _readConversations();
    final index = conversations.indexWhere((c) => c.id == conversationId);
    if (index < 0) throw StateError('Conversation not found');

    final current = conversations[index];
    if (current.ownerIdentityId != senderIdentityId) {
      throw StateError('Conversation belongs to another identity');
    }

    final nextSequence =
        (BigInt.parse(current.lastSequence) + BigInt.one).toString();
    final now = DateTime.now().toUtc();

    final message = ChatMessage(
      id: clientId,
      conversationId: conversationId,
      clientMessageId: clientId,
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

    conversations[index] = current.copyWith(
      lastSequence: nextSequence,
      lastMessageAt: now,
      lastMessagePreview: body,
      updatedAt: now,
    );
    await _writeConversations(conversations);
    return message;
  }
}
