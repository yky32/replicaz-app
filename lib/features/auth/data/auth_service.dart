import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:replicaz/core/config/app_config.dart';
import 'package:replicaz/core/constants/storage_keys.dart';
import 'package:replicaz/core/errors/app_exception.dart';
import 'package:replicaz/core/network/api_client.dart';
import 'package:replicaz/core/storage/local_store.dart';
import 'package:replicaz/features/auth/domain/user_account.dart';
import 'package:uuid/uuid.dart';

class AuthService {
  AuthService({
    required this.store,
    required this.secureStorage,
    this.apiClient,
  });

  final LocalStore store;
  final FlutterSecureStorage secureStorage;
  final ApiClient? apiClient;
  final _uuid = const Uuid();

  Future<UserAccount?> currentUser() async {
    final map = store.getJsonMap(StorageKeys.authUser);
    if (map == null) return null;
    return UserAccount.fromJson(map);
  }

  Future<bool> hasToken() async {
    final token = await secureStorage.read(key: StorageKeys.authToken);
    return token != null && token.isNotEmpty;
  }

  Future<UserAccount> login({
    required String email,
    required String password,
  }) async {
    if (AppConfig.effectiveRemoteBackend) {
      return _remoteAuth(
        path: '/auth/login',
        body: {'email': email, 'password': password},
      );
    }
    return _localSession(
      email: email,
      displayName: email.split('@').first,
    );
  }

  /// Offline shell for TestFlight / no-backend browsing.
  Future<UserAccount> enterDemoOffline() async {
    AppConfig.demoOfflineSession = true;
    await secureStorage.write(key: StorageKeys.demoSession, value: '1');
    return _localSession(
      email: 'demo@replicaz.local',
      displayName: 'Demo',
    );
  }

  Future<UserAccount> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (AppConfig.effectiveRemoteBackend) {
      return _remoteAuth(
        path: '/auth/register',
        body: {
          'email': email,
          'password': password,
          'displayName': displayName,
        },
      );
    }
    return _localSession(email: email, displayName: displayName);
  }

  Future<void> logout() async {
    await secureStorage.delete(key: StorageKeys.authToken);
    await secureStorage.delete(key: StorageKeys.demoSession);
    await store.remove(StorageKeys.authUser);
    AppConfig.demoOfflineSession = false;
  }

  /// Restore demo flag after cold start (before route decisions).
  Future<void> restoreDemoFlag() async {
    final flag = await secureStorage.read(key: StorageKeys.demoSession);
    AppConfig.demoOfflineSession = flag == '1';
  }

  Future<UserAccount> _remoteAuth({
    required String path,
    required Map<String, dynamic> body,
  }) async {
    final client = apiClient;
    if (client == null) {
      throw AppException('ApiClient required for remote auth');
    }
    try {
      final res = await client.dio.post(path, data: body);
      final data = res.data['data'] as Map<String, dynamic>;
      final token = data['accessToken'] as String;
      final userMap = data['user'] as Map<String, dynamic>;
      final user = UserAccount.fromJson(userMap);
      await secureStorage.write(key: StorageKeys.authToken, value: token);
      await store.setJson(StorageKeys.authUser, user.toJson());
      return user;
    } on DioException catch (e) {
      throw ApiClient.mapDio(e);
    }
  }

  Future<UserAccount> _localSession({
    required String email,
    required String displayName,
  }) async {
    final existing = await currentUser();
    final user = UserAccount(
      id: existing?.id ?? _uuid.v4(),
      email: email.trim().toLowerCase(),
      displayName: displayName.trim().isEmpty
          ? email.split('@').first
          : displayName.trim(),
      alias: displayName.trim().isEmpty
          ? email.split('@').first
          : displayName.trim(),
    );
    await secureStorage.write(
      key: StorageKeys.authToken,
      value: 'local-${user.id}',
    );
    await store.setJson(StorageKeys.authUser, user.toJson());
    return user;
  }
}
