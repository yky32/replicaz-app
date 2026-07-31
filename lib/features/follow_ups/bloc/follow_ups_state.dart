part of 'follow_ups_bloc.dart';

enum FollowUpsStatus { initial, loading, loaded }

class FollowUpsState extends Equatable {
  const FollowUpsState({
    this.status = FollowUpsStatus.initial,
    this.items = const [],
    this.identityId,
  });

  final FollowUpsStatus status;
  final List<FollowUp> items;
  final String? identityId;

  int get openCount =>
      items.where((e) => e.status == FollowUpStatus.open).length;

  FollowUpsState copyWith({
    FollowUpsStatus? status,
    List<FollowUp>? items,
    String? identityId,
  }) {
    return FollowUpsState(
      status: status ?? this.status,
      items: items ?? this.items,
      identityId: identityId ?? this.identityId,
    );
  }

  @override
  List<Object?> get props => [status, items, identityId];
}
