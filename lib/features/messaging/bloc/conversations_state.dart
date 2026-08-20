part of 'conversations_bloc.dart';

enum ConversationsStatus { initial, loading, loaded, failure }

class ConversationsState extends Equatable {
  const ConversationsState({
    this.status = ConversationsStatus.initial,
    this.conversations = const [],
    this.identityId,
    this.errorMessage,
    this.creating = false,
    this.lastCreatedConversationId,
    this.refreshing = false,
  });

  final ConversationsStatus status;
  final List<Conversation> conversations;
  final String? identityId;
  final String? errorMessage;
  final bool creating;
  final String? lastCreatedConversationId;
  /// Pull-to-refresh skeletonizer (list stays visible).
  final bool refreshing;

  ConversationsState copyWith({
    ConversationsStatus? status,
    List<Conversation>? conversations,
    String? identityId,
    String? errorMessage,
    bool? creating,
    String? lastCreatedConversationId,
    bool? refreshing,
    bool clearError = false,
    bool clearLastCreated = false,
  }) {
    return ConversationsState(
      status: status ?? this.status,
      conversations: conversations ?? this.conversations,
      identityId: identityId ?? this.identityId,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      creating: creating ?? this.creating,
      lastCreatedConversationId: clearLastCreated
          ? null
          : (lastCreatedConversationId ?? this.lastCreatedConversationId),
      refreshing: refreshing ?? this.refreshing,
    );
  }

  @override
  List<Object?> get props => [
        status,
        conversations,
        identityId,
        errorMessage,
        creating,
        lastCreatedConversationId,
        refreshing,
      ];
}
