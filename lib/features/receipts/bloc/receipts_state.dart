part of 'receipts_bloc.dart';

enum ReceiptsStatus { initial, loading, loaded, failure }

class ReceiptsState extends Equatable {
  const ReceiptsState({
    this.status = ReceiptsStatus.initial,
    this.items = const [],
    this.identityId,
  });

  final ReceiptsStatus status;
  final List<Receipt> items;
  final String? identityId;

  ReceiptsState copyWith({
    ReceiptsStatus? status,
    List<Receipt>? items,
    String? identityId,
  }) {
    return ReceiptsState(
      status: status ?? this.status,
      items: items ?? this.items,
      identityId: identityId ?? this.identityId,
    );
  }

  @override
  List<Object?> get props => [status, items, identityId];
}
