import 'package:equatable/equatable.dart';

/// Entity representing a Face Embedding (Feature Vector)
/// This is a 128 or 512-dimensional vector that uniquely identifies a face
class FaceEmbedding extends Equatable {
  final List<double> embedding;
  final String userId;
  final DateTime createdAt;
  final String?
      label; // Optional label for multiple faces (e.g., "front", "left_angle")

  const FaceEmbedding({
    required this.embedding,
    required this.userId,
    required this.createdAt,
    this.label,
  });

  /// Create from JSON
  factory FaceEmbedding.fromJson(Map<String, dynamic> json) {
    return FaceEmbedding(
      embedding: (json['embedding'] as List).map((e) => e as double).toList(),
      userId: json['userId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      label: json['label'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'embedding': embedding,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'label': label,
    };
  }

  @override
  List<Object?> get props => [embedding, userId, createdAt, label];

  FaceEmbedding copyWith({
    List<double>? embedding,
    String? userId,
    DateTime? createdAt,
    String? label,
  }) {
    return FaceEmbedding(
      embedding: embedding ?? this.embedding,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      label: label ?? this.label,
    );
  }
}
