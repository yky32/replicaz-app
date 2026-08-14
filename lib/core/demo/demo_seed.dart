import 'package:replicaz/core/bootstrap/app_bootstrap.dart';
import 'package:replicaz/core/constants/storage_keys.dart';
import 'package:replicaz/features/contacts/domain/contact.dart';
import 'package:replicaz/features/identities/domain/identity.dart';
import 'package:replicaz/features/messaging/domain/chat_message.dart';
import 'package:replicaz/features/messaging/domain/conversation.dart';
import 'package:replicaz/features/notes/domain/note.dart';
import 'package:uuid/uuid.dart';

/// Offline / TestFlight shell data so navigation is clickable without backend.
abstract final class DemoSeed {
  static const _uuid = Uuid();

  /// Idempotent: only fills empty stores so re-entry keeps user edits.
  static Future<void> ensureShellData({required String userId}) async {
    await AppBootstrap.identityService.ensureOnboarded();
    final identities = await AppBootstrap.identityService.getAll();
    if (identities.isEmpty) return;

    final personal = identities.firstWhere(
      (e) => e.type == IdentityType.personal,
      orElse: () => identities.first,
    );
    Identity? job;
    Identity? freelance;
    for (final e in identities) {
      if (e.type == IdentityType.job) job = e;
      if (e.type == IdentityType.freelance) freelance = e;
    }

    await _seedContactsIfEmpty(personal: personal, job: job, freelance: freelance);
    await _seedNotesIfEmpty(personal: personal, job: job);
    await _seedChatsIfEmpty(
      userId: userId,
      personal: personal,
      job: job,
      freelance: freelance,
    );
  }

  static Future<void> _seedContactsIfEmpty({
    required Identity personal,
    Identity? job,
    Identity? freelance,
  }) async {
    final existing = AppBootstrap.store.getJsonList(StorageKeys.contacts);
    if (existing.isNotEmpty) return;

    final now = DateTime.now().toUtc();
    final items = <Contact>[
      Contact(
        id: _uuid.v4(),
        identityId: personal.id,
        name: 'Alex Chen',
        email: 'alex@example.com',
        phone: '+852 9000 1111',
        notes: 'Weekend hiking buddy',
        createdAt: now,
        updatedAt: now,
      ),
      if (job != null)
        Contact(
          id: _uuid.v4(),
          identityId: job.id,
          name: 'Jordan Lee',
          email: 'jordan@acme.co',
          company: 'Acme',
          notes: 'PM — standup Mon/Wed',
          createdAt: now,
          updatedAt: now,
        ),
      if (freelance != null)
        Contact(
          id: _uuid.v4(),
          identityId: freelance.id,
          name: 'Sam Rivera',
          email: 'sam@client.io',
          company: 'Client Co',
          notes: 'Invoice Q3 design pack',
          createdAt: now,
          updatedAt: now,
        ),
    ];
    for (final c in items) {
      await AppBootstrap.contactService.save(c);
    }
  }

  static Future<void> _seedNotesIfEmpty({
    required Identity personal,
    Identity? job,
  }) async {
    final existing = AppBootstrap.store.getJsonList(StorageKeys.notes);
    if (existing.isNotEmpty) return;

    final now = DateTime.now().toUtc();
    await AppBootstrap.noteService.save(
      Note(
        id: _uuid.v4(),
        identityId: personal.id,
        title: 'Packing list',
        body: 'Charger · passport · book',
        createdAt: now,
        updatedAt: now,
      ),
    );
    if (job != null) {
      await AppBootstrap.noteService.save(
        Note(
          id: _uuid.v4(),
          identityId: job.id,
          title: '1:1 talking points',
          body: 'Q3 goals · headcount · blockers',
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
  }

  static Future<void> _seedChatsIfEmpty({
    required String userId,
    required Identity personal,
    Identity? job,
    Identity? freelance,
  }) async {
    final store = AppBootstrap.store;
    final existing = store.getJsonList(StorageKeys.conversations);
    if (existing.isNotEmpty) return;

    final now = DateTime.now().toUtc();
    final personalRoom = _uuid.v4();
    final jobRoom = _uuid.v4();
    final freeRoom = _uuid.v4();

    final conversations = <Conversation>[
      Conversation(
        id: personalRoom,
        type: ConversationType.direct,
        ownerIdentityId: personal.id,
        createdByUserId: userId,
        title: 'Alex Chen',
        lastSequence: '2',
        lastMessageAt: now.subtract(const Duration(minutes: 12)),
        lastMessagePreview: 'Coffee this Saturday?',
        lastReadSequence: '1',
        unreadCount: 1,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(minutes: 12)),
      ),
      if (job != null)
        Conversation(
          id: jobRoom,
          type: ConversationType.direct,
          ownerIdentityId: job.id,
          createdByUserId: userId,
          title: 'Jordan Lee',
          lastSequence: '1',
          lastMessageAt: now.subtract(const Duration(hours: 3)),
          lastMessagePreview: 'Deck looks good — ship Friday?',
          lastReadSequence: '1',
          unreadCount: 0,
          createdAt: now.subtract(const Duration(days: 1)),
          updatedAt: now.subtract(const Duration(hours: 3)),
        ),
      if (freelance != null)
        Conversation(
          id: freeRoom,
          type: ConversationType.direct,
          ownerIdentityId: freelance.id,
          createdByUserId: userId,
          title: 'Sam Rivera',
          lastSequence: '1',
          lastMessageAt: now.subtract(const Duration(hours: 8)),
          lastMessagePreview: 'Invoice received, thanks!',
          lastReadSequence: '0',
          unreadCount: 1,
          createdAt: now.subtract(const Duration(days: 3)),
          updatedAt: now.subtract(const Duration(hours: 8)),
        ),
    ];

    await store.setJson(
      StorageKeys.conversations,
      conversations.map((e) => e.toJson()).toList(),
    );

    final messages = <ChatMessage>[
      ChatMessage(
        id: _uuid.v4(),
        conversationId: personalRoom,
        clientMessageId: _uuid.v4(),
        senderUserId: 'peer-alex',
        senderIdentityId: personal.id,
        body: 'Hey — free this weekend?',
        sequence: '1',
        deliveryStatus: MessageDeliveryStatus.delivered,
        createdAt: now.subtract(const Duration(minutes: 30)),
        serverReceivedAt: now.subtract(const Duration(minutes: 30)),
      ),
      ChatMessage(
        id: _uuid.v4(),
        conversationId: personalRoom,
        clientMessageId: _uuid.v4(),
        senderUserId: 'peer-alex',
        senderIdentityId: personal.id,
        body: 'Coffee this Saturday?',
        sequence: '2',
        deliveryStatus: MessageDeliveryStatus.delivered,
        createdAt: now.subtract(const Duration(minutes: 12)),
        serverReceivedAt: now.subtract(const Duration(minutes: 12)),
      ),
      if (job != null)
        ChatMessage(
          id: _uuid.v4(),
          conversationId: jobRoom,
          clientMessageId: _uuid.v4(),
          senderUserId: userId,
          senderIdentityId: job.id,
          body: 'Deck looks good — ship Friday?',
          sequence: '1',
          deliveryStatus: MessageDeliveryStatus.sent,
          createdAt: now.subtract(const Duration(hours: 3)),
          serverReceivedAt: now.subtract(const Duration(hours: 3)),
        ),
      if (freelance != null)
        ChatMessage(
          id: _uuid.v4(),
          conversationId: freeRoom,
          clientMessageId: _uuid.v4(),
          senderUserId: 'peer-sam',
          senderIdentityId: freelance.id,
          body: 'Invoice received, thanks!',
          sequence: '1',
          deliveryStatus: MessageDeliveryStatus.delivered,
          createdAt: now.subtract(const Duration(hours: 8)),
          serverReceivedAt: now.subtract(const Duration(hours: 8)),
        ),
    ];

    await store.setJson(
      StorageKeys.messages,
      messages.map((e) => e.toJson()).toList(),
    );

    final bindings = <String, String>{
      personalRoom: personal.id,
      if (job != null) jobRoom: job.id,
      if (freelance != null) freeRoom: freelance.id,
    };
    await store.setJson(StorageKeys.roomIdentityBindings, bindings);

    // Personal room partially read → one unread.
    await store.setJson(StorageKeys.roomReadCursors, {
      personalRoom: now
          .subtract(const Duration(minutes: 20))
          .toIso8601String(),
      if (job != null) jobRoom: now.toIso8601String(),
    });
  }
}
