part of 'contacts_bloc.dart';

enum ContactsStatus { initial, loading, loaded }

class ContactsState extends Equatable {
  const ContactsState({
    this.status = ContactsStatus.initial,
    this.contacts = const [],
    this.identityId,
  });

  final ContactsStatus status;
  final List<Contact> contacts;
  final String? identityId;

  ContactsState copyWith({
    ContactsStatus? status,
    List<Contact>? contacts,
    String? identityId,
  }) {
    return ContactsState(
      status: status ?? this.status,
      contacts: contacts ?? this.contacts,
      identityId: identityId ?? this.identityId,
    );
  }

  @override
  List<Object?> get props => [status, contacts, identityId];
}
