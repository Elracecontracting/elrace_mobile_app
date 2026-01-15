part of 'check_in_bloc.dart';

sealed class CheckInEvent extends Equatable {
  const CheckInEvent();
  @override
  List<Object> get props => [];
}

/// Event to trigger check-in after face verification
final class CheckInET extends CheckInEvent {}

/// Event to verify face before check-in
/// Now supports multiple images for anti-spoofing detection
final class VerifyFaceForCheckInET extends CheckInEvent {
  final String imagePath;
  final List<String>? additionalImagePaths; // For anti-spoof check

  const VerifyFaceForCheckInET({
    required this.imagePath,
    this.additionalImagePaths,
  });

  @override
  List<Object> get props => [imagePath, additionalImagePaths ?? []];
}
