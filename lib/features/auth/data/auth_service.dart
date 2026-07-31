import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:replicaz/core/config/app_config.dart';
import 'package:replicaz/core/constants/storage_keys.dart';
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

  Future<UserAccount> login({
    required String email,
    required String password,
  }) async {
    if (AppConfig.useRemoteBackend) {
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

  Future<UserAccount> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (AppConfig.useRemoteBackend) {
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
    await store.remove(StorageKeys.authUser);
  }

  Future<UserAccount> _remoteAuth({
    required String path,
    required Map<String, dynamic> body,
  }) async {
    final client = apiClient;
    if (client == null) {
      throw StateError('ApiClient required for remote auth');
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
      final msg = e.response?.data is Map
          ? (e.response!.data['message']?.toString() ?? e.message)
          : e.message;
      throw Exception(msg ?? 'Auth failed');
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
