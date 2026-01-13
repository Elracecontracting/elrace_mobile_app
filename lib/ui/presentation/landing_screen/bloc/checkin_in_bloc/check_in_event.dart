part of 'check_in_bloc.dart';

sealed class CheckInEvent extends Equatable {
  const CheckInEvent();
  @override
  List<Object> get props => [];
}

/// Event to trigger check-in after face verification
final class CheckInET extends CheckInEvent {}

/// Event to verify face before check-in
final class VerifyFaceForCheckInET extends CheckInEvent {
  final String imagePath;

  const VerifyFaceForCheckInET({required this.imagePath});

  @override
  List<Object> get props => [imagePath];
}
