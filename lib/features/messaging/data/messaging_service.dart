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

  bool get _remote => AppConfig.effectiveRemoteBackend && remote != null;

  // ── room ↔ identity bindings ──

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
    // Creating/opening again un-hides the room.
    final hidden = _readHidden();
    if (hidden.remove(roomId)) {
      await _writeHidden(hidden);
    }
  }

  String? identityIdForRoom(String roomId) => _readBindings()[roomId];

  Set<String> roomIdsForIdentity(String identityId) {
    return _readBindings()
        .entries
        .where((e) => e.value == identityId)
        .map((e) => e.key)
        .toSet();
  }

  // ── leave / hide ──

  Set<String> _readHidden() {
    final map = store.getJsonMap(StorageKeys.hiddenRoomIds);
    if (map == null) return {};
    return map.keys.toSet();
  }

  Future<void> _writeHidden(Set<String> ids) async {
    final map = {for (final id in ids) id: true};
    await store.setJson(StorageKeys.hiddenRoomIds, map);
  }

  Future<void> hideRoom(String roomId) async {
    final hidden = _readHidden()..add(roomId);
    await _writeHidden(hidden);
  }

  bool isRoomHidden(String roomId) => _readHidden().contains(roomId);

  // ── read cursors / unread ──

  Map<String, DateTime> _readCursors() {
    final map = store.getJsonMap(StorageKeys.roomReadCursors);
    if (map == null) return {};
    final out = <String, DateTime>{};
    for (final e in map.entries) {
      final raw = e.value?.toString();
      if (raw == null || raw.isEmpty) continue;
      try {
        out[e.key] = DateTime.parse(raw).toUtc();
      } catch (_) {}
    }
    return out;
  }

  Future<void> _writeCursors(Map<String, DateTime> cursors) async {
    final map = {
      for (final e in cursors.entries) e.key: e.value.toUtc().toIso8601String(),
    };
    await store.setJson(StorageKeys.roomReadCursors, map);
  }

  Future<void> markRoomRead(String roomId, {DateTime? at}) async {
    final cursors = _readCursors();
    cursors[roomId] = (at ?? DateTime.now()).toUtc();
    await _writeCursors(cursors);
  }

  int _unreadFor(Conversation c, Map<String, DateTime> cursors) {
    final last = c.lastMessageAt;
    if (last == null) return 0;
    final readAt = cursors[c.id];
    if (readAt == null) {
      // Never opened — treat as unread if there is any preview activity.
      return (c.lastMessagePreview?.trim().isNotEmpty ?? false) ? 1 : 0;
    }
    return last.isAfter(readAt.add(const Duration(milliseconds: 50))) ? 1 : 0;
  }

  Conversation _withUnread(Conversation c, Map<String, DateTime> cursors) {
    return c.copyWith(unreadCount: _unreadFor(c, cursors));
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

  /// Unread message totals keyed by owner identity (local demo + bindings).
  /// Fast sync path for life switcher badges.
  Map<String, int> unreadTotalsByIdentity() {
    final cursors = _readCursors();
    final hidden = _readHidden();
    final totals = <String, int>{};
    for (final c in _readConversations()) {
      if (hidden.contains(c.id)) continue;
      final n = _unreadFor(c, cursors);
      if (n <= 0) continue;
      totals.update(
        c.ownerIdentityId,
        (v) => v + n,
        ifAbsent: () => n,
      );
    }
    return totals;
  }

  /// Conversations owned by [identityId] only — never leaks across lives.
  Future<List<Conversation>> conversationsForIdentity(String identityId) async {
    final cursors = _readCursors();
    final hidden = _readHidden();

    if (_remote) {
      final rooms = await remote!.myRooms(identityId: identityId);
      final bindings = _readBindings();
      var dirty = false;
      final filtered = <Conversation>[];

      for (final r in rooms) {
        if (hidden.contains(r.id)) continue;
        final bound = bindings[r.id];
        if (bound != null && bound != identityId) continue;
        if (bound == null) {
          bindings[r.id] = identityId;
          dirty = true;
        }
        final base = Conversation(
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
        );
        filtered.add(_withUnread(base, cursors));
      }

      if (dirty) await _writeBindings(bindings);

      filtered.sort((a, b) {
        final aAt = a.lastMessageAt ?? a.createdAt;
        final bAt = b.lastMessageAt ?? b.createdAt;
        return bAt.compareTo(aAt);
      });
      return filtered;
    }

    return _readConversations()
        .where((c) => c.ownerIdentityId == identityId && !hidden.contains(c.id))
        .map((c) => _withUnread(c, cursors))
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
      await markRoomRead(room.id);
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
        unreadCount: 0,
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
      unreadCount: 0,
      createdAt: now,
      updatedAt: now,
    );
    final items = _readConversations()..add(conversation);
    await _writeConversations(items);
    await markRoomRead(conversation.id, at: now);
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
    final bound = identityIdForRoom(conversationId);
    if (bound != null && bound != senderIdentityId) {
      throw StateError(
        'This chat belongs to another identity. Switch life to send.',
      );
    }

    if (_remote) {
      if (bound == null) {
        await bindRoomToIdentity(
          roomId: conversationId,
          identityId: senderIdentityId,
        );
      }
      final sent = await remote!.sendMessage(
        roomId: conversationId,
        content: body,
        senderUserId: senderUserId,
        senderIdentityId: senderIdentityId,
        clientMessageId: clientId,
      );
      await markRoomRead(conversationId, at: sent.createdAt);
      return sent;
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
      unreadCount: 0,
    );
    await _writeConversations(conversations);
    await markRoomRead(conversationId, at: now);
    return message;
  }
}
