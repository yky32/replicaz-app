/// Local docker stack defaults (iOS Simulator → host machine).
abstract final class AppConfig {
  /// Toggle remote Messenger + CMF (tgt-rn pattern).
  static const useRemoteBackend = bool.fromEnvironment(
    'USE_REMOTE_BACKEND',
    defaultValue: true,
  );

  /// Nest messenger (`docker-compose` → :9010).
  static const apiHost = String.fromEnvironment(
    'API_HOST',
    defaultValue: 'http://127.0.0.1:9010',
  );

  /// CMF WebSocket (`docker-compose` → :8088).
  static const cmfWsUrl = String.fromEnvironment(
    'CMF_WS_URL',
    defaultValue: 'ws://127.0.0.1:8088',
  );

  static String get msgrBase => '$apiHost/msgr';
}
