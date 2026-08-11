import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:replicaz/core/config/app_config.dart';
import 'package:replicaz/core/constants/storage_keys.dart';
import 'package:replicaz/core/errors/app_exception.dart';

/// Dio-backed Messenger REST client (`AppConfig.msgrBase`).
///
/// - Attaches `Authorization: Bearer <token>` from secure storage on every request
/// - Emits [unauthorized] on HTTP 401 so Auth can force re-login
class ApiClient {
  ApiClient({
    required this.secureStorage,
    Dio? dio,
  }) {
    _dio = dio ??
        Dio(
          BaseOptions(
            baseUrl: AppConfig.msgrBase,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 20),
            headers: {'Content-Type': 'application/json'},
          ),
        );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await secureStorage.read(key: StorageKeys.authToken);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            options.headers.remove('Authorization');
          }
          handler.next(options);
        },
        onError: (error, handler) {
          final status = error.response?.statusCode;
          if (status == 401) {
            final path = error.requestOptions.path;
            final isAuthEndpoint =
                path.contains('/auth/login') || path.contains('/auth/register');
            if (!isAuthEndpoint) {
              _unauthorizedController.add(null);
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  final FlutterSecureStorage secureStorage;
  late final Dio _dio;
  final _unauthorizedController = StreamController<void>.broadcast();

  Dio get dio => _dio;

  /// Fires when a non-auth request receives HTTP 401.
  Stream<void> get unauthorized => _unauthorizedController.stream;

  void dispose() {
    _unauthorizedController.close();
  }

  /// Maps [DioException] into a short user-facing [AppException].
  static AppException mapDio(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return AppException('Request timed out. Check the local stack.', cause: e);
    }
    if (e.type == DioExceptionType.connectionError) {
      return AppException(
        'Cannot reach messenger (${AppConfig.apiHost}). Is it running?',
        cause: e,
      );
    }
    final data = e.response?.data;
    String? serverMsg;
    if (data is Map) {
      final message = data['message'];
      if (message is List) {
        serverMsg = message.map((e) => e.toString()).join(', ');
      } else if (message != null) {
        serverMsg = message.toString();
      }
    }
    final status = e.response?.statusCode;
    if (status == 401) {
      return AppException(serverMsg ?? 'Session expired. Sign in again.', cause: e);
    }
    if (status == 403) {
      return AppException(serverMsg ?? 'Not allowed.', cause: e);
    }
    if (status == 404) {
      return AppException(serverMsg ?? 'Not found.', cause: e);
    }
    if (status != null && status >= 500) {
      return AppException(serverMsg ?? 'Messenger error ($status).', cause: e);
    }
    return AppException(
      serverMsg ?? e.message ?? 'Network request failed',
      cause: e,
    );
  }
}
