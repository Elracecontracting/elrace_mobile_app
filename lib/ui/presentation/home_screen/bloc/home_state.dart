part of 'home_bloc.dart';

sealed class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object> get props => [];
}

final class HomeInitial extends HomeState {}

final class CheckedInSTHome extends HomeState {}

final class CheckedOutSTHome extends HomeState {}

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


class ChangeIndexLoading extends HomeState {}
class ChangeIndexSuccess extends HomeState {}


class FaceRecognitionStatusChanged extends HomeState {
  final FaceRecognitionStatus status;
  const FaceRecognitionStatusChanged(this.status);
  @override
  List<Object> get props => [status];
}