import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:replicaz/core/constants/storage_keys.dart';
import 'package:replicaz/core/network/api_client.dart';

/// In-memory secure storage used only in unit tests.
class MemorySecureStorage implements FlutterSecureStorage {
  MemorySecureStorage([Map<String, String>? initial])
      : map = Map<String, String>.of(initial ?? {});

  final Map<String, String> map;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName.toString();
    if (name.contains('read')) {
      final key = invocation.namedArguments[#key] as String?;
      return Future<String?>.value(key == null ? null : map[key]);
    }
    if (name.contains('write')) {
      final key = invocation.namedArguments[#key] as String?;
      final value = invocation.namedArguments[#value] as String?;
      if (key != null) {
        if (value == null) {
          map.remove(key);
        } else {
          map[key] = value;
        }
      }
      return Future<void>.value();
    }
    if (name.contains('delete')) {
      final key = invocation.namedArguments[#key] as String?;
      if (key != null) map.remove(key);
      return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }
}

class _StatusAdapter implements HttpClientAdapter {
  _StatusAdapter(this.status, {this.body = '{}'});

  final int status;
  final String body;
  String? lastAuthHeader;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastAuthHeader = options.headers['Authorization']?.toString();
    return ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('attaches Bearer token from secure storage', () async {
    final storage = MemorySecureStorage({StorageKeys.authToken: 'tok-abc'});
    final dio = Dio(BaseOptions(baseUrl: 'http://example.test/msgr'));
    final adapter = _StatusAdapter(200, body: '{"ok":true}');
    dio.httpClientAdapter = adapter;

    final client = ApiClient(secureStorage: storage, dio: dio);
    await client.dio.get('/users');
    expect(adapter.lastAuthHeader, 'Bearer tok-abc');
    client.dispose();
  });

  test('emits unauthorized on 401 for protected routes', () async {
    final storage = MemorySecureStorage({StorageKeys.authToken: 'dead'});
    final dio = Dio(BaseOptions(baseUrl: 'http://example.test/msgr'));
    dio.httpClientAdapter = _StatusAdapter(
      401,
      body: jsonEncode({'message': 'Unauthorized'}),
    );
    final client = ApiClient(secureStorage: storage, dio: dio);

    final future = client.unauthorized.first;
    try {
      await client.dio.get('/chat/my-rooms');
    } on DioException {
      // expected
    }
    await future.timeout(const Duration(seconds: 2));
    client.dispose();
  });

  test('does not emit unauthorized for login 401', () async {
    final storage = MemorySecureStorage();
    final dio = Dio(BaseOptions(baseUrl: 'http://example.test/msgr'));
    dio.httpClientAdapter = _StatusAdapter(
      401,
      body: jsonEncode({'message': 'Invalid credentials'}),
    );
    final client = ApiClient(secureStorage: storage, dio: dio);

    var fired = false;
    final sub = client.unauthorized.listen((_) => fired = true);
    try {
      await client.dio.post('/auth/login', data: {});
    } on DioException {
      // expected
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(fired, isFalse);
    await sub.cancel();
    client.dispose();
  });

  test('mapDio connection errors are readable', () {
    final ex = ApiClient.mapDio(
      DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.connectionError,
      ),
    );
    expect(ex.message, contains('Cannot reach messenger'));
  });
}
