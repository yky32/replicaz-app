import 'package:flutter_test/flutter_test.dart';
import 'package:replicaz/core/errors/app_exception.dart';
import 'package:replicaz/core/storage/local_store.dart';
import 'package:replicaz/features/messaging/bloc/thread_bloc.dart';
import 'package:replicaz/features/messaging/data/messaging_service.dart';
import 'package:replicaz/features/messaging/domain/chat_message.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeMessagingService extends MessagingService {
  FakeMessagingService({
    required super.store,
    this.sendHandler,
    this.loadHandler,
  });

  Future<ChatMessage> Function(ChatMessage draft)? sendHandler;
  Future<List<ChatMessage>> Function()? loadHandler;
  int sendCalls = 0;

  @override
  Future<List<ChatMessage>> messagesFor(
    String conversationId, {
    String identityId = '',
  }) async {
    if (loadHandler != null) return loadHandler!();
    return const [];
  }

  @override
  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String senderUserId,
    required String senderIdentityId,
    required String body,
    String? clientMessageId,
  }) async {
    sendCalls += 1;
    final draft = ChatMessage(
      id: clientMessageId ?? 'id',
      conversationId: conversationId,
      clientMessageId: clientMessageId ?? 'id',
      senderUserId: senderUserId,
      senderIdentityId: senderIdentityId,
      body: body,
      sequence: '1',
      deliveryStatus: MessageDeliveryStatus.sent,
      createdAt: DateTime.now().toUtc(),
    );
    if (sendHandler != null) return sendHandler!(draft);
    return draft;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStore store;
  late FakeMessagingService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    store = LocalStore(prefs);
    service = FakeMessagingService(store: store);
  });

  ThreadBloc buildBloc() => ThreadBloc(
        conversationId: 'room1',
        messagingService: service,
        enableRealtime: false,
      );

  test('load success emits messages', () async {
    service.loadHandler = () async => [
          ChatMessage(
            id: 'm1',
            conversationId: 'room1',
            clientMessageId: 'm1',
            senderUserId: 'alice',
            senderIdentityId: 'id1',
            body: 'hi',
            sequence: '1',
            deliveryStatus: MessageDeliveryStatus.delivered,
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        ];

    final bloc = buildBloc();
    bloc.add(const ThreadLoadRequested(identityId: 'id1'));

    await expectLater(
      bloc.stream,
      emitsThrough(
        predicate<ThreadState>(
          (s) =>
              s.status == ThreadStatus.loaded &&
              s.messages.length == 1 &&
              s.messages.first.body == 'hi',
        ),
      ),
    );
    await bloc.close();
  });

  test('send failure marks message failed', () async {
    service.sendHandler = (_) async {
      throw AppException('Cannot reach messenger');
    };

    final bloc = buildBloc();
    bloc.add(const ThreadLoadRequested(identityId: 'id1'));
    await bloc.stream.firstWhere((s) => s.status == ThreadStatus.loaded);

    bloc.add(
      const ThreadSendRequested(
        senderUserId: 'alice',
        senderIdentityId: 'id1',
        body: 'boom',
      ),
    );

    await expectLater(
      bloc.stream,
      emitsThrough(
        predicate<ThreadState>(
          (s) =>
              !s.sending &&
              s.sendError != null &&
              s.messages.any(
                (m) =>
                    m.body == 'boom' &&
                    m.deliveryStatus == MessageDeliveryStatus.failed,
              ),
        ),
      ),
    );
    await bloc.close();
  });

  test('send success marks message sent', () async {
    final bloc = buildBloc();
    bloc.add(const ThreadLoadRequested(identityId: 'id1'));
    await bloc.stream.firstWhere((s) => s.status == ThreadStatus.loaded);

    bloc.add(
      const ThreadSendRequested(
        senderUserId: 'alice',
        senderIdentityId: 'id1',
        body: 'ok',
      ),
    );

    await expectLater(
      bloc.stream,
      emitsThrough(
        predicate<ThreadState>(
          (s) =>
              !s.sending &&
              s.sendError == null &&
              s.messages.any(
                (m) =>
                    m.body == 'ok' &&
                    m.deliveryStatus == MessageDeliveryStatus.sent,
              ),
        ),
      ),
    );
    expect(service.sendCalls, 1);
    await bloc.close();
  });

  test('remote dedupe replaces optimistic with inbound', () async {
    final bloc = buildBloc();
    bloc.add(const ThreadLoadRequested(identityId: 'id1'));
    await bloc.stream.firstWhere((s) => s.status == ThreadStatus.loaded);

    bloc.add(
      const ThreadSendRequested(
        senderUserId: 'alice',
        senderIdentityId: 'id1',
        body: 'dup',
      ),
    );
    await bloc.stream.firstWhere(
      (s) => s.messages.any((m) => m.body == 'dup') && !s.sending,
    );

    final now = DateTime.now().toUtc();
    bloc.add(
      ThreadRemoteMessageReceived(
        ChatMessage(
          id: 'server-99',
          conversationId: 'room1',
          clientMessageId: 'server-99',
          senderUserId: 'alice',
          senderIdentityId: 'id1',
          body: 'dup',
          sequence: '${now.millisecondsSinceEpoch}',
          deliveryStatus: MessageDeliveryStatus.delivered,
          createdAt: now,
          serverReceivedAt: now,
        ),
      ),
    );

    await expectLater(
      bloc.stream,
      emitsThrough(
        predicate<ThreadState>((s) {
          final dups = s.messages.where((m) => m.body == 'dup').toList();
          return dups.length == 1 &&
              dups.first.id == 'server-99' &&
              dups.first.deliveryStatus == MessageDeliveryStatus.delivered;
        }),
      ),
    );
    await bloc.close();
  });
}
