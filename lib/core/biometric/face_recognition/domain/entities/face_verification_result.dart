import 'package:equatable/equatable.dart';

/// Entity representing the result of a face verification attempt
class FaceVerificationResult extends Equatable {
  final bool isVerified;
  final double confidence; // Distance or similarity score
  final String? message;
  final bool hasLiveness; // Did the person pass the liveness check?

  const FaceVerificationResult({
    required this.isVerified,
    required this.confidence,
    this.message,
    this.hasLiveness = false,
  });

  @override
  List<Object?> get props => [isVerified, confidence, message, hasLiveness];

  FaceVerificationResult copyWith({
    bool? isVerified,
    double? confidence,
    String? message,
    bool? hasLiveness,
  }) {
    return FaceVerificationResult(
      isVerified: isVerified ?? this.isVerified,
      confidence: confidence ?? this.confidence,
      message: message ?? this.message,
      hasLiveness: hasLiveness ?? this.hasLiveness,
    );
  }
}
