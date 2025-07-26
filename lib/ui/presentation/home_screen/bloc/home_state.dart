part of 'home_bloc.dart';

sealed class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object> get props => [];
}

final class HomeInitial extends HomeState {}

final class CheckedInST extends HomeState {}

final class CheckedOutST extends HomeState {}

class LastMonthAttendanceSummaryLoading extends HomeState {
  const LastMonthAttendanceSummaryLoading();
}


class LastMonthAttendanceSummaryLoaded extends HomeState {
  const LastMonthAttendanceSummaryLoaded();

  @override
  List<Object> get props => [];
}

class LastMonthAttendanceSummaryError extends HomeState {
  final String message;
  const LastMonthAttendanceSummaryError(this.message);

  @override
  List<Object> get props => [message];
}
