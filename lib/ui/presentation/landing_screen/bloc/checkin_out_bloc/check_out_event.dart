part of 'check_out_bloc.dart';

sealed class CheckOutEvent extends Equatable {
  const CheckOutEvent();

  @override
  List<Object> get props => [];
}

final class CheckOutET extends CheckOutEvent {
  final int checkInRecordId;

  const CheckOutET(this.checkInRecordId);

  @override
  List<Object> get props => [checkInRecordId];
}
