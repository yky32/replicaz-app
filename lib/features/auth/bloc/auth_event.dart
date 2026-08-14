part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

final class AuthBootstrapRequested extends AuthEvent {
  const AuthBootstrapRequested();
}

final class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

/// Offline demo shell — no backend required (TestFlight flow browsing).
final class AuthDemoLoginRequested extends AuthEvent {
  const AuthDemoLoginRequested();
}

final class AuthRegisterRequested extends AuthEvent {
  const AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.displayName,
  });

  final String email;
  final String password;
  final String displayName;

  @override
  List<Object?> get props => [email, password, displayName];
}

final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// Fired when Dio receives 401 on a protected route.
final class AuthSessionExpired extends AuthEvent {
  const AuthSessionExpired();
}
