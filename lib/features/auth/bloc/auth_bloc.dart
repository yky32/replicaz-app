import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:replicaz/core/bootstrap/app_bootstrap.dart';
import 'package:replicaz/features/auth/data/auth_service.dart';
import 'package:replicaz/features/auth/domain/user_account.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({AuthService? authService})
      : _authService = authService ?? AppBootstrap.authService,
        super(const AuthState()) {
    on<AuthBootstrapRequested>(_onBootstrap);
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthLogoutRequested>(_onLogout);
  }

  final AuthService _authService;

  Future<void> _onBootstrap(
    AuthBootstrapRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final user = await _authService.currentUser();
    emit(
      state.copyWith(
        status: user == null ? AuthStatus.unauthenticated : AuthStatus.authenticated,
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
}
