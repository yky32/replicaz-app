part of 'identities_bloc.dart';

sealed class IdentitiesEvent extends Equatable {
  const IdentitiesEvent();

  @override
  List<Object?> get props => [];
}

final class IdentitiesLoadRequested extends IdentitiesEvent {
  const IdentitiesLoadRequested();
}

final class IdentitiesSwitchRequested extends IdentitiesEvent {
  const IdentitiesSwitchRequested(this.identityId);

  final String identityId;

  @override
  List<Object?> get props => [identityId];
}

final class IdentitiesCreateRequested extends IdentitiesEvent {
  const IdentitiesCreateRequested(this.identity);

  final Identity identity;

  @override
  List<Object?> get props => [identity];
}

final class IdentitiesUpdateRequested extends IdentitiesEvent {
  const IdentitiesUpdateRequested(this.identity);

  final Identity identity;

  @override
  List<Object?> get props => [identity];
}

final class IdentitiesDeleteRequested extends IdentitiesEvent {
  const IdentitiesDeleteRequested(this.identityId);

  final String identityId;

  @override
  List<Object?> get props => [identityId];
}
