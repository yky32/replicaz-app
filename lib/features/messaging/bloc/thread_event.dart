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
