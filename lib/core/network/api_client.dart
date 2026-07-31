import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:replicaz/core/config/app_config.dart';
import 'package:replicaz/core/constants/storage_keys.dart';

class ApiClient {
  ApiClient({required this.secureStorage}) {
    _dio = Dio(
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
          }
          handler.next(options);
        },
      ),
    );
  }

  final FlutterSecureStorage secureStorage;
  late final Dio _dio;

  Dio get dio => _dio;
}
