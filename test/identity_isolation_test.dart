import 'package:flutter_test/flutter_test.dart';
import 'package:replicaz/core/constants/storage_keys.dart';
import 'package:replicaz/core/storage/local_store.dart';
import 'package:replicaz/features/contacts/data/contact_service.dart';
import 'package:replicaz/features/identities/bloc/identities_bloc.dart';
import 'package:replicaz/features/identities/data/identity_service.dart';
import 'package:replicaz/features/identities/domain/identity.dart';
import 'package:replicaz/features/messaging/data/messaging_service.dart';
import 'package:replicaz/features/notes/data/note_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:replicaz/features/contacts/domain/contact.dart';
import 'package:replicaz/features/notes/domain/note.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStore store;
  late IdentityService identityService;
  late ContactService contactService;
  late NoteService noteService;
  late MessagingService messagingService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    store = LocalStore(prefs);
    identityService = IdentityService(store: store);
    contactService = ContactService(store: store);
    noteService = NoteService(store: store);
    // Local mode: remote is null → uses local conversations store.
    messagingService = MessagingService(store: store, remote: null);
  });

  test('ensureOnboarded seeds Personal as active', () async {
    await identityService.ensureOnboarded();
    final all = await identityService.getAll();
    expect(all.length, 3);
    expect(all.any((e) => e.type == IdentityType.personal), isTrue);
    final activeId = await identityService.getActiveId();
    final personal = all.firstWhere((e) => e.type == IdentityType.personal);
    expect(activeId, personal.id);
  });

  test('ensureOnboarded is idempotent', () async {
    await identityService.ensureOnboarded();
    final first = await identityService.getAll();
    await identityService.ensureOnboarded();
    final second = await identityService.getAll();
    expect(second.map((e) => e.id).toSet(), first.map((e) => e.id).toSet());
  });

  test('contacts and notes never cross identities', () async {
    await identityService.ensureOnboarded();
    final all = await identityService.getAll();
    final personal = all.firstWhere((e) => e.type == IdentityType.personal);
    final job = all.firstWhere((e) => e.type == IdentityType.job);
    final now = DateTime.now().toUtc();

    await contactService.save(
      Contact(
        id: 'c-personal',
        identityId: personal.id,
        name: 'Pat',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await contactService.save(
      Contact(
        id: 'c-job',
        identityId: job.id,
        name: 'Boss',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await noteService.save(
      Note(
        id: 'n-personal',
        identityId: personal.id,
        title: 'gym',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await noteService.save(
      Note(
        id: 'n-job',
        identityId: job.id,
        title: 'standup',
        createdAt: now,
        updatedAt: now,
      ),
    );

    final personalContacts = await contactService.byIdentity(personal.id);
    final jobContacts = await contactService.byIdentity(job.id);
    expect(personalContacts.map((e) => e.name), ['Pat']);
    expect(jobContacts.map((e) => e.name), ['Boss']);

    final personalNotes = await noteService.byIdentity(personal.id);
    final jobNotes = await noteService.byIdentity(job.id);
    expect(personalNotes.map((e) => e.title), ['gym']);
    expect(jobNotes.map((e) => e.title), ['standup']);
  });

  test('local conversations filter by ownerIdentityId', () async {
    await identityService.ensureOnboarded();
    final all = await identityService.getAll();
    final personal = all.firstWhere((e) => e.type == IdentityType.personal);
    final job = all.firstWhere((e) => e.type == IdentityType.job);

    await messagingService.createDirectConversation(
      ownerIdentityId: personal.id,
      createdByUserId: 'u1',
      title: 'Personal chat',
    );
    await messagingService.createDirectConversation(
      ownerIdentityId: job.id,
      createdByUserId: 'u1',
      title: 'Job chat',
    );

    final pChats =
        await messagingService.conversationsForIdentity(personal.id);
    final jChats = await messagingService.conversationsForIdentity(job.id);
    expect(pChats.map((e) => e.title), ['Personal chat']);
    expect(jChats.map((e) => e.title), ['Job chat']);
  });

  test('remote-style room bindings isolate identities', () async {
    // Simulate remote bindings without a real API.
    await messagingService.bindRoomToIdentity(
      roomId: 'room-a',
      identityId: 'id-personal',
    );
    await messagingService.bindRoomToIdentity(
      roomId: 'room-b',
      identityId: 'id-job',
    );
    expect(messagingService.roomIdsForIdentity('id-personal'), {'room-a'});
    expect(messagingService.roomIdsForIdentity('id-job'), {'room-b'});
    expect(messagingService.identityIdForRoom('room-a'), 'id-personal');
  });

  test('IdentitiesBloc switch updates active id', () async {
    final bloc = IdentitiesBloc(identityService: identityService);
    bloc.add(const IdentitiesLoadRequested());
    await bloc.stream.firstWhere((s) => s.status == IdentitiesStatus.loaded);

    final job = bloc.state.identities
        .firstWhere((e) => e.type == IdentityType.job);
    expect(bloc.state.activeIdentity?.type, IdentityType.personal);

    bloc.add(IdentitiesSwitchRequested(job.id));
    await bloc.stream.firstWhere((s) => s.activeIdentityId == job.id);
    expect(bloc.state.activeIdentity?.type, IdentityType.job);
    expect(await identityService.getActiveId(), job.id);
    await bloc.close();
  });

  test('cannot delete last identity', () async {
    final bloc = IdentitiesBloc(identityService: identityService);
    bloc.add(const IdentitiesLoadRequested());
    await bloc.stream.firstWhere((s) => s.status == IdentitiesStatus.loaded);

    // Delete down to one.
    final ids = bloc.state.identities.map((e) => e.id).toList();
    for (var i = 0; i < ids.length - 1; i++) {
      bloc.add(IdentitiesDeleteRequested(ids[i]));
      await bloc.stream.firstWhere(
        (s) => s.identities.length == ids.length - 1 - i,
      );
    }
    expect(bloc.state.identities.length, 1);
    final lastId = bloc.state.identities.single.id;
    bloc.add(IdentitiesDeleteRequested(lastId));
    await bloc.stream.firstWhere(
      (s) => s.errorMessage != null && s.identities.length == 1,
    );
    await bloc.close();
  });

  test('bindings persist in LocalStore', () async {
    await store.setJson(StorageKeys.roomIdentityBindings, {
      'r1': 'i1',
    });
    final map = store.getJsonMap(StorageKeys.roomIdentityBindings);
    expect(map?['r1'], 'i1');
  });
}
