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
    this.boundIdentityId = '',
    this.activeIdentityId = '',
    this.peerTyping = false,
    this.canSend = true,
  });

  final ThreadStatus status;
  final List<ChatMessage> messages;
  final bool sending;
  final ThreadConnectionStatus connection;
  final String? errorMessage;
  final String? sendError;
  final DateTime? lastInboundAt;
  final String boundIdentityId;
  final String activeIdentityId;
  final bool peerTyping;
  final bool canSend;

  bool get isConnected => connection == ThreadConnectionStatus.connected;
  bool get showConnectionBanner =>
      connection == ThreadConnectionStatus.reconnecting ||
      connection == ThreadConnectionStatus.failed ||
      connection == ThreadConnectionStatus.connecting;
  bool get identityMismatch =>
      boundIdentityId.isNotEmpty &&
      activeIdentityId.isNotEmpty &&
      boundIdentityId != activeIdentityId;

  ThreadState copyWith({
    ThreadStatus? status,
    List<ChatMessage>? messages,
    bool? sending,
    ThreadConnectionStatus? connection,
    String? errorMessage,
    String? sendError,
    DateTime? lastInboundAt,
    String? boundIdentityId,
    String? activeIdentityId,
    bool? peerTyping,
    bool? canSend,
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
      boundIdentityId: boundIdentityId ?? this.boundIdentityId,
      activeIdentityId: activeIdentityId ?? this.activeIdentityId,
      peerTyping: peerTyping ?? this.peerTyping,
      canSend: canSend ?? this.canSend,
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
        boundIdentityId,
        activeIdentityId,
        peerTyping,
        canSend,
      ];
}
