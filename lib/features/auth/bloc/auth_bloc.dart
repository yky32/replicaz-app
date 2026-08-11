import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:replicaz/core/bootstrap/app_bootstrap.dart';
import 'package:replicaz/core/config/app_config.dart';
import 'package:replicaz/core/network/api_client.dart';
import 'package:replicaz/features/auth/data/auth_service.dart';
import 'package:replicaz/features/auth/domain/user_account.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    AuthService? authService,
    ApiClient? apiClient,
    Stream<void>? unauthorized,
  })  : _authService = authService ?? AppBootstrap.authService,
        super(const AuthState()) {
    on<AuthBootstrapRequested>(_onBootstrap);
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthSessionExpired>(_onSessionExpired);

    final stream = unauthorized ??
        (AppConfig.useRemoteBackend
            ? (apiClient ?? AppBootstrap.apiClient).unauthorized
            : null);
    if (stream != null) {
      _unauthorizedSub = stream.listen((_) {
        if (!isClosed) add(const AuthSessionExpired());
      });
    }
  }

  final AuthService _authService;
  StreamSubscription<void>? _unauthorizedSub;

  Future<void> _onBootstrap(
    AuthBootstrapRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final user = await _authService.currentUser();
    if (user == null) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          clearUser: true,
          clearError: true,
        ),
      );
      return;
    }

    // Remote mode: require a stored JWT or force re-login.
    if (AppConfig.useRemoteBackend) {
      final hasToken = await _authService.hasToken();
      if (!hasToken) {
        await _authService.logout();
        emit(
          state.copyWith(
            status: AuthStatus.unauthenticated,
            clearUser: true,
            clearError: true,
          ),
        );
        return;
      }
    }

    emit(
      state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        clearError: true,
      ),
    );
  }

  Future<void> _onLogin(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    try {
      final user = await _authService.login(
        email: event.email,
        password: event.password,
      );
      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    } catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: e.toString(),
          clearUser: true,
        ),
      );
    }
  }

  Future<void> _onRegister(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    try {
      final user = await _authService.register(
        email: event.email,
        password: event.password,
        displayName: event.displayName,
      );
      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    } catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: e.toString(),
          clearUser: true,
        ),
      );
    }
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authService.logout();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  Future<void> _onSessionExpired(
    AuthSessionExpired event,
    Emitter<AuthState> emit,
  ) async {
    if (state.status == AuthStatus.unauthenticated) return;
    await _authService.logout();
    emit(
      const AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Session expired. Sign in again.',
      ),
    );
  }

  @override
  Future<void> close() {
    _unauthorizedSub?.cancel();
    return super.close();
  }
}
