part of 'contacts_bloc.dart';

sealed class ContactsEvent extends Equatable {
  const ContactsEvent();

  @override
  List<Object?> get props => [];
}

final class ContactsLoadRequested extends ContactsEvent {
  const ContactsLoadRequested({required this.identityId});

  final String identityId;

  @override
  List<Object?> get props => [identityId];
}

final class ContactsSaveRequested extends ContactsEvent {
  const ContactsSaveRequested(this.contact);

  final Contact contact;

  @override
  List<Object?> get props => [contact];
}

final class ContactsDeleteRequested extends ContactsEvent {
  const ContactsDeleteRequested(this.contactId);

  final String contactId;

  @override
  List<Object?> get props => [contactId];
}
