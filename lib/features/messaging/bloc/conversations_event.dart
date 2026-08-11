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

/// Soft refresh without full-screen loading spinner when list already loaded.
final class ConversationsRefreshRequested extends ConversationsEvent {
  const ConversationsRefreshRequested();
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

/// Local inbox bump after send/WS without waiting for network.
final class ConversationsPreviewUpdated extends ConversationsEvent {
  const ConversationsPreviewUpdated({
    required this.conversationId,
    required this.preview,
    required this.at,
  });

  final String conversationId;
  final String preview;
  final DateTime at;

  @override
  List<Object?> get props => [conversationId, preview, at];
}
