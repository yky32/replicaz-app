import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:replicaz/core/constants/storage_keys.dart';
import 'package:replicaz/core/storage/local_store.dart';
import 'package:replicaz/features/auth/bloc/auth_bloc.dart';
import 'package:replicaz/features/auth/data/auth_service.dart';
import 'package:replicaz/features/auth/domain/user_account.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Minimal in-memory secure storage for unit tests.
class MemorySecureStorage implements FlutterSecureStorage {
  final map = <String, String>{};

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

class StubAuthService extends AuthService {
  StubAuthService({
    required super.store,
    required super.secureStorage,
  }) : super(apiClient: null);

  UserAccount? user = const UserAccount(
    id: 'u1',
    email: 'alice@replicaz.local',
    displayName: 'Alice',
    alias: 'alice',
  );
  bool loggedOut = false;

  @override
  Future<UserAccount?> currentUser() async => user;

  @override
  Future<bool> hasToken() async => true;

  @override
  Future<void> logout() async {
    loggedOut = true;
    user = null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AuthSessionExpired clears session via unauthorized stream', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalStore(prefs);
    final secure = MemorySecureStorage();
    await secure.write(key: StorageKeys.authToken, value: 'tok');
    final service = StubAuthService(store: store, secureStorage: secure);
    final unauthorized = StreamController<void>.broadcast();

    final bloc = AuthBloc(
      authService: service,
      unauthorized: unauthorized.stream,
    );

    bloc.add(const AuthBootstrapRequested());
    await bloc.stream.firstWhere((s) => s.isAuthenticated);

    unauthorized.add(null);

    await expectLater(
      bloc.stream,
      emitsThrough(
        predicate<AuthState>(
          (s) =>
              s.status == AuthStatus.unauthenticated &&
              s.user == null &&
              (s.errorMessage?.contains('Session') ?? false),
        ),
      ),
    );
    expect(service.loggedOut, isTrue);
    await unauthorized.close();
    await bloc.close();
  });
}
