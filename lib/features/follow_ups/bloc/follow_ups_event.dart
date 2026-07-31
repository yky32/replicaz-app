part of 'follow_ups_bloc.dart';

sealed class FollowUpsEvent extends Equatable {
  const FollowUpsEvent();

  @override
  List<Object?> get props => [];
}

final class FollowUpsLoadRequested extends FollowUpsEvent {
  const FollowUpsLoadRequested({required this.identityId});

  final String identityId;

  @override
  List<Object?> get props => [identityId];
}

final class FollowUpsAddRequested extends FollowUpsEvent {
  const FollowUpsAddRequested({
    required this.title,
    this.details = '',
    this.dueAt,
  });

  final String title;
  final String details;
  final DateTime? dueAt;

  @override
  List<Object?> get props => [title, details, dueAt];
}

final class FollowUpsToggleRequested extends FollowUpsEvent {
  const FollowUpsToggleRequested(this.item);

  final FollowUp item;

  @override
  List<Object?> get props => [item];
}

final class FollowUpsDeleteRequested extends FollowUpsEvent {
  const FollowUpsDeleteRequested(this.followUpId);

  final String followUpId;

  @override
  List<Object?> get props => [followUpId];
}
