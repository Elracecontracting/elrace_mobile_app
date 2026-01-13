part of 'check_in_bloc.dart';

abstract class CheckInState extends Equatable {
  const CheckInState();

  @override
  List<Object?> get props => [];
}

class CheckInInitial extends CheckInState {}

class CheckedInST extends CheckInState {
  final String message;
  final int checkInRecordId;

  const CheckedInST(this.message, this.checkInRecordId);

  @override
  List<Object> get props => [message, checkInRecordId];
}

class CheckInErrorST extends CheckInState {
  final String errorMessage;

  const CheckInErrorST(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class CheckInWarningST extends CheckInState {
  final String warningMessage;
  final int checkInRecordId;

  const CheckInWarningST(this.warningMessage, this.checkInRecordId);

  @override
  List<Object> get props => [warningMessage, checkInRecordId];
}

final class CheckInLoadingST extends CheckInState {
  final bool isLoading;
  const CheckInLoadingST({required this.isLoading});
  @override
  List<Object> get props => [isLoading];
}

/// State for face verification results
class FaceVerificationSuccessST extends CheckInState {
  const FaceVerificationSuccessST();
}

class FaceVerificationFailedST extends CheckInState {
  final String reason;

  const FaceVerificationFailedST(this.reason);

  @override
  List<Object> get props => [reason];
}

/// State when face embeddings not found (need enrollment)
class FaceNotEnrolledST extends CheckInState {
  const FaceNotEnrolledST();
}
