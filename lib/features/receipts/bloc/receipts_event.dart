part of 'receipts_bloc.dart';

sealed class ReceiptsEvent extends Equatable {
  const ReceiptsEvent();

  @override
  List<Object?> get props => [];
}

final class ReceiptsLoadRequested extends ReceiptsEvent {
  const ReceiptsLoadRequested({required this.identityId, this.force = false});

  final String identityId;
  final bool force;

  @override
  List<Object?> get props => [identityId, force];
}

final class ReceiptsSaveRequested extends ReceiptsEvent {
  const ReceiptsSaveRequested(this.receipt);

  final Receipt receipt;

  @override
  List<Object?> get props => [receipt];
}

final class ReceiptsDeleteRequested extends ReceiptsEvent {
  const ReceiptsDeleteRequested(this.receiptId);

  final String receiptId;

  @override
  List<Object?> get props => [receiptId];
}
