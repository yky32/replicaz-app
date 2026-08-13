part of 'thread_bloc.dart';

sealed class ThreadEvent extends Equatable {
  const ThreadEvent();

  @override
  List<Object?> get props => [];
}

final class ThreadLoadRequested extends ThreadEvent {
  const ThreadLoadRequested({this.identityId = ''});

  final String identityId;

  @override
  List<Object?> get props => [identityId];
}

final class ThreadSendRequested extends ThreadEvent {
  const ThreadSendRequested({
    required this.senderUserId,
    required this.senderIdentityId,
    required this.body,
  });

  final String senderUserId;
  final String senderIdentityId;
  final String body;

  @override
  List<Object?> get props => [senderUserId, senderIdentityId, body];
}

final class ThreadRemoteMessageReceived extends ThreadEvent {
  const ThreadRemoteMessageReceived(this.message);

  final ChatMessage message;

  @override
  List<Object?> get props => [message];
}

final class ThreadConnectionStatusChanged extends ThreadEvent {
  const ThreadConnectionStatusChanged(this.connection);

  final ThreadConnectionStatus connection;

  @override
  List<Object?> get props => [connection];
}

/// App resumed / user tapped retry — rejoin CMF room.
final class ThreadReconnectRequested extends ThreadEvent {
  const ThreadReconnectRequested();
}

final class ThreadRetrySendRequested extends ThreadEvent {
  const ThreadRetrySendRequested(this.clientMessageId);

  final String clientMessageId;

  @override
  List<Object?> get props => [clientMessageId];
}

final class ThreadTypingLocalChanged extends ThreadEvent {
  const ThreadTypingLocalChanged(this.isTyping);

  final bool isTyping;

  @override
  List<Object?> get props => [isTyping];
}

final class ThreadRemoteTypingChanged extends ThreadEvent {
  const ThreadRemoteTypingChanged({
    required this.peerId,
    required this.isTyping,
  });

  final String peerId;
  final bool isTyping;

  @override
  List<Object?> get props => [peerId, isTyping];
}

/// Active identity switched while thread is open.
final class ThreadActiveIdentityChanged extends ThreadEvent {
  const ThreadActiveIdentityChanged(this.activeIdentityId);

  final String activeIdentityId;

  @override
  List<Object?> get props => [activeIdentityId];
}
