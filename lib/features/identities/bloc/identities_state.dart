part of 'identities_bloc.dart';

enum IdentitiesStatus { initial, loading, loaded, error }

class IdentitiesState extends Equatable {
  const IdentitiesState({
    this.status = IdentitiesStatus.initial,
    this.identities = const [],
    this.activeIdentityId,
    this.errorMessage,
  });

  final IdentitiesStatus status;
  final List<Identity> identities;
  final String? activeIdentityId;
  final String? errorMessage;

  Identity? get activeIdentity {
    if (identities.isEmpty) return null;
    for (final identity in identities) {
      if (identity.id == activeIdentityId) return identity;
    }
    return identities.first;
  }

  IdentitiesState copyWith({
    IdentitiesStatus? status,
    List<Identity>? identities,
    String? activeIdentityId,
    String? errorMessage,
    bool clearError = false,
  }) {
    return IdentitiesState(
      status: status ?? this.status,
      identities: identities ?? this.identities,
      activeIdentityId: activeIdentityId ?? this.activeIdentityId,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props =>
      [status, identities, activeIdentityId, errorMessage];
}
