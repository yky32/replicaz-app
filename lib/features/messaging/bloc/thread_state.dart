part of 'thread_bloc.dart';

enum ThreadStatus { initial, loading, loaded, failure }

enum ThreadConnectionStatus {
  idle,
  connecting,
  connected,
  reconnecting,
  failed,
}

class ThreadState extends Equatable {
  const ThreadState({
    this.status = ThreadStatus.initial,
    this.messages = const [],
    this.sending = false,
    this.connection = ThreadConnectionStatus.idle,
    this.errorMessage,
    this.sendError,
    this.lastInboundAt,
  });

  final ThreadStatus status;
  final List<ChatMessage> messages;
  final bool sending;
  final ThreadConnectionStatus connection;
  final String? errorMessage;
  final String? sendError;

  /// Bumps when a remote message lands — inbox can listen via parent.
  final DateTime? lastInboundAt;

  bool get isConnected => connection == ThreadConnectionStatus.connected;
  bool get showConnectionBanner =>
      connection == ThreadConnectionStatus.reconnecting ||
      connection == ThreadConnectionStatus.failed ||
      connection == ThreadConnectionStatus.connecting;

  ThreadState copyWith({
    ThreadStatus? status,
    List<ChatMessage>? messages,
    bool? sending,
    ThreadConnectionStatus? connection,
    String? errorMessage,
    String? sendError,
    DateTime? lastInboundAt,
    bool clearError = false,
    bool clearSendError = false,
  }) {
    return ThreadState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      sending: sending ?? this.sending,
      connection: connection ?? this.connection,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      sendError: clearSendError ? null : (sendError ?? this.sendError),
      lastInboundAt: lastInboundAt ?? this.lastInboundAt,
    );
  }

  @override
  List<Object?> get props => [
        status,
        messages,
        sending,
        connection,
        errorMessage,
        sendError,
        lastInboundAt,
      ];
}
