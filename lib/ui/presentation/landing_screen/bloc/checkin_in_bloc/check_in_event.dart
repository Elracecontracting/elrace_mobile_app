part of 'check_in_bloc.dart';

sealed class CheckInEvent extends Equatable {
  const CheckInEvent();
  @override
  List<Object> get props => [];
}

final class CheckInET extends CheckInEvent {}