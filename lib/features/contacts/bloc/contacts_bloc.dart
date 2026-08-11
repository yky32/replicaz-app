import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:replicaz/core/bootstrap/app_bootstrap.dart';
import 'package:replicaz/features/contacts/data/contact_service.dart';
import 'package:replicaz/features/contacts/domain/contact.dart';
import 'package:replicaz/features/identities/bloc/identities_bloc.dart';

part 'contacts_event.dart';
part 'contacts_state.dart';

class ContactsBloc extends Bloc<ContactsEvent, ContactsState> {
  ContactsBloc({
    required IdentitiesBloc identitiesBloc,
    ContactService? contactService,
  })  : _identitiesBloc = identitiesBloc,
        _service = contactService ?? AppBootstrap.contactService,
        super(const ContactsState()) {
    on<ContactsLoadRequested>(_onLoad);
    on<ContactsSaveRequested>(_onSave);
    on<ContactsDeleteRequested>(_onDelete);

    _identitySub = _identitiesBloc.stream
        .map((s) => s.activeIdentityId)
        .distinct()
        .listen((id) {
      if (id != null) add(ContactsLoadRequested(identityId: id));
    });

    final initialId = _identitiesBloc.state.activeIdentityId;
    if (initialId != null) {
      add(ContactsLoadRequested(identityId: initialId));
    }
  }

  final IdentitiesBloc _identitiesBloc;
  final ContactService _service;
  StreamSubscription<String?>? _identitySub;

  Future<void> _onLoad(
    ContactsLoadRequested event,
    Emitter<ContactsState> emit,
  ) async {
    final switching = state.identityId != null &&
        state.identityId != event.identityId;
    // Clear previous life immediately so UI never shows cross-identity rows.
    emit(
      state.copyWith(
        status: ContactsStatus.loading,
        identityId: event.identityId,
        contacts: switching ? const [] : state.contacts,
      ),
    );
    final contacts = await _service.byIdentity(event.identityId);
    // Drop late responses if user switched again.
    if (state.identityId != null && state.identityId != event.identityId) {
      return;
    }
    emit(
      state.copyWith(
        status: ContactsStatus.loaded,
        contacts: contacts,
        identityId: event.identityId,
      ),
    );
  }

  Future<void> _onSave(
    ContactsSaveRequested event,
    Emitter<ContactsState> emit,
  ) async {
    await _service.save(event.contact);
    final identityId = event.contact.identityId;
    add(ContactsLoadRequested(identityId: identityId));
  }

  Future<void> _onDelete(
    ContactsDeleteRequested event,
    Emitter<ContactsState> emit,
  ) async {
    await _service.delete(event.contactId);
    final identityId = state.identityId;
    if (identityId != null) {
      add(ContactsLoadRequested(identityId: identityId));
    }
  }

  @override
  Future<void> close() {
    _identitySub?.cancel();
    return super.close();
  }
}
