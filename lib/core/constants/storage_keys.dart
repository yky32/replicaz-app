abstract final class StorageKeys {
  static const authToken = 'auth_token';
  static const authUser = 'auth_user';
  static const identities = 'identities';
  static const activeIdentityId = 'active_identity_id';
  static const contacts = 'contacts';
  static const notes = 'notes';
  static const followUps = 'follow_ups';
  static const syncQueue = 'sync_queue';
  static const conversations = 'conversations';
  static const messages = 'messages';
  static const messageCursors = 'message_cursors';
  static const workspaceSyncCursor = 'workspace_sync_cursor';

  /// Local map: chatRoomId → ownerIdentityId (remote messenger has no identity).
  static const roomIdentityBindings = 'room_identity_bindings';
}
