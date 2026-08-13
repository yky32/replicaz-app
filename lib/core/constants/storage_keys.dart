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

  /// Local map: chatRoomId → ISO last-read timestamp (unread cursor).
  static const roomReadCursors = 'room_read_cursors';

  /// Local set: chatRoomIds hidden/left on this device (inbox lifecycle).
  static const hiddenRoomIds = 'hidden_room_ids';
}
