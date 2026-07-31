part of 'thread_bloc.dart';

enum ThreadStatus { initial, loading, loaded }

class ThreadState extends Equatable {
  const ThreadState({
    this.status = ThreadStatus.initial,
    this.messages = const [],
    this.sending = false,
  });

  final ThreadStatus status;
  final List<ChatMessage> messages;
  final bool sending;

  ThreadState copyWith({
    ThreadStatus? status,
    List<ChatMessage>? messages,
    bool? sending,
  }) {
    return ThreadState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      sending: sending ?? this.sending,
    );
  }

  @override
  List<Object?> get props => [status, messages, sending];
}
