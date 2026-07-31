part of 'conversations_bloc.dart';

enum ConversationsStatus { initial, loading, loaded }

class ConversationsState extends Equatable {
  const ConversationsState({
    this.status = ConversationsStatus.initial,
    this.conversations = const [],
    this.identityId,
  });

  final ConversationsStatus status;
  final List<Conversation> conversations;
  final String? identityId;

  ConversationsState copyWith({
    ConversationsStatus? status,
    List<Conversation>? conversations,
    String? identityId,
  }) {
    return ConversationsState(
      status: status ?? this.status,
      conversations: conversations ?? this.conversations,
      identityId: identityId ?? this.identityId,
    );
  }

  @override
  List<Object?> get props => [status, conversations, identityId];
}
