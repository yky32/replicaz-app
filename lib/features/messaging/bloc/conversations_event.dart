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
    this.fromSelf = false,
  });

  final String conversationId;
  final String preview;
  final DateTime at;
  final bool fromSelf;

  @override
  List<Object?> get props => [conversationId, preview, at, fromSelf];
}

/// Opened a thread — clear unread for room.
final class ConversationsMarkReadRequested extends ConversationsEvent {
  const ConversationsMarkReadRequested(this.conversationId);

  final String conversationId;

  @override
  List<Object?> get props => [conversationId];
}

/// Hide/leave room on this device (local lifecycle).
final class ConversationsLeaveRequested extends ConversationsEvent {
  const ConversationsLeaveRequested(this.conversationId);

  final String conversationId;

  @override
  List<Object?> get props => [conversationId];
}

/// Periodic soft refresh while bloc is alive (backup if WS missed a frame).
final class ConversationsRealtimeTick extends ConversationsEvent {
  const ConversationsRealtimeTick();
}

/// App / inbox resumed — refresh + socket reconnect.
final class ConversationsInboxResumeRequested extends ConversationsEvent {
  const ConversationsInboxResumeRequested();
}

/// Clear one-shot navigation id after inbox opened the new thread.
final class ConversationsLastCreatedConsumed extends ConversationsEvent {
  const ConversationsLastCreatedConsumed();
}
