part of 'home_bloc.dart';

sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object> get props => [];
}

final class CheckInET extends HomeEvent {}

final class CheckOutET extends HomeEvent {}

final class FetchLastMonthAttendanceSummary extends HomeEvent {
  const FetchLastMonthAttendanceSummary();
}


class ChangeCurrentIndex extends HomeEvent{
  final int index;
  const ChangeCurrentIndex({required this.index});
}
