part of 'conversations_bloc.dart';

sealed class ConversationsEvent extends Equatable {
  const ConversationsEvent();

  @override
  List<Object?> get props => [];
}

final class ConversationsLoadRequested extends ConversationsEvent {
  const ConversationsLoadRequested({required this.identityId});

  final String identityId;

  @override
  List<Object?> get props => [identityId];
}

final class ConversationsCreateRequested extends ConversationsEvent {
  const ConversationsCreateRequested({
    required this.userId,
    this.title,
    this.participantUserId,
  });

  final String userId;
  final String? title;
  final String? participantUserId;

  @override
  List<Object?> get props => [userId, title, participantUserId];
}
