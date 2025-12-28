import 'dart:math' as math;

/// Helper class for comparing face embeddings
///
/// This class implements different distance metrics for comparing
/// face embedding vectors to determine if two faces belong to the same person.
///
/// Key Concepts:
/// - Face embeddings are points in high-dimensional space
/// - Similar faces have embeddings that are close together
/// - Different faces have embeddings that are far apart
/// - We use distance/similarity thresholds to make decisions
class EmbeddingComparisonHelper {
  /// Calculate Euclidean Distance between two embeddings
  ///
  /// Formula:
  /// distance = sqrt(sum((a[i] - b[i])^2))
  ///
  /// Properties:
  /// - Range: [0, ∞)
  /// - Lower is better (0 = identical)
  /// - Typical threshold for FaceNet: 0.6 to 1.0
  /// - For MobileFaceNet: 0.8 to 1.2
  ///
  /// Parameters:
  /// - embedding1: First face embedding vector
  /// - embedding2: Second face embedding vector
  ///
  /// Returns:
  /// - double: The Euclidean distance
  ///
  /// Example:
  /// If distance < 0.6: Same person (high confidence)
  /// If 0.6 <= distance < 1.0: Same person (medium confidence)
  /// If distance >= 1.0: Different person
  static double euclideanDistance(
    List<double> embedding1,
    List<double> embedding2,
  ) {
    if (embedding1.length != embedding2.length) {
      throw ArgumentError(
          'Embeddings must have the same length. Got ${embedding1.length} and ${embedding2.length}');
    }

    double sumSquaredDiff = 0.0;

    for (int i = 0; i < embedding1.length; i++) {
      final diff = embedding1[i] - embedding2[i];
      sumSquaredDiff += diff * diff;
    }

    return math.sqrt(sumSquaredDiff);
  }

  /// Calculate Cosine Similarity between two embeddings
  ///
  /// Formula:
  /// similarity = (A · B) / (||A|| * ||B||)
  ///
  /// For L2-normalized embeddings (which we do in FaceNetService):
  /// similarity = A · B (dot product)
  ///
  /// Properties:
  /// - Range: [-1, 1] (but for faces, usually [0, 1])
  /// - Higher is better (1 = identical, 0 = orthogonal)
  /// - Typical threshold: 0.5 to 0.7
  ///
  /// Parameters:
  /// - embedding1: First face embedding vector (should be normalized)
  /// - embedding2: Second face embedding vector (should be normalized)
  ///
  /// Returns:
  /// - double: The cosine similarity
  ///
  /// Example:
  /// If similarity > 0.7: Same person (high confidence)
  /// If 0.5 <= similarity <= 0.7: Same person (medium confidence)
  /// If similarity < 0.5: Different person
  static double cosineSimilarity(
    List<double> embedding1,
    List<double> embedding2,
  ) {
    if (embedding1.length != embedding2.length) {
      throw ArgumentError(
          'Embeddings must have the same length. Got ${embedding1.length} and ${embedding2.length}');
    }

    // Calculate dot product
    double dotProduct = 0.0;
    for (int i = 0; i < embedding1.length; i++) {
      dotProduct += embedding1[i] * embedding2[i];
    }

    // If embeddings are already L2-normalized (as in FaceNetService),
    // the dot product IS the cosine similarity
    // Otherwise, we would need to divide by the product of magnitudes

    // For safety, let's compute magnitudes anyway
    double magnitude1 = 0.0;
    double magnitude2 = 0.0;

    for (int i = 0; i < embedding1.length; i++) {
      magnitude1 += embedding1[i] * embedding1[i];
      magnitude2 += embedding2[i] * embedding2[i];
    }

    magnitude1 = math.sqrt(magnitude1);
    magnitude2 = math.sqrt(magnitude2);

    // Avoid division by zero
    if (magnitude1 == 0.0 || magnitude2 == 0.0) {
      return 0.0;
    }

    return dotProduct / (magnitude1 * magnitude2);
  }

  /// Convert Cosine Similarity to Cosine Distance
  ///
  /// Formula:
  /// distance = 1 - similarity
  ///
  /// This makes it consistent with Euclidean distance (lower = more similar)
  ///
  /// Range: [0, 2] (but typically [0, 1] for faces)
  static double cosineDistance(
    List<double> embedding1,
    List<double> embedding2,
  ) {
    return 1.0 - cosineSimilarity(embedding1, embedding2);
  }

  /// Verify if two embeddings belong to the same person
  ///
  /// Uses Euclidean distance by default
  ///
  /// Parameters:
  /// - embedding1: First face embedding (e.g., stored)
  /// - embedding2: Second face embedding (e.g., current)
  /// - threshold: Distance threshold for matching
  /// - useCosineSimilarity: Use cosine similarity instead of Euclidean
  ///
  /// Returns:
  /// - bool: true if same person, false otherwise
  ///
  /// Threshold Guidelines:
  /// Euclidean Distance:
  /// - Strict: 0.6 (fewer false positives, more false negatives)
  /// - Balanced: 0.8 (good trade-off)
  /// - Lenient: 1.0 (fewer false negatives, more false positives)
  ///
  /// Cosine Similarity:
  /// - Strict: 0.7
  /// - Balanced: 0.6
  /// - Lenient: 0.5
  static bool verify(
    List<double> embedding1,
    List<double> embedding2, {
    double threshold = 0.8,
    bool useCosineSimilarity = false,
  }) {
    if (useCosineSimilarity) {
      final similarity = cosineSimilarity(embedding1, embedding2);
      return similarity >= threshold;
    } else {
      final distance = euclideanDistance(embedding1, embedding2);
      return distance <= threshold;
    }
  }

  /// Get confidence score between 0.0 and 1.0
  ///
  /// Converts distance/similarity to a normalized confidence score
  ///
  /// For Euclidean distance:
  /// - confidence = max(0, 1 - (distance / maxDistance))
  ///
  /// For Cosine similarity:
  /// - confidence = (similarity + 1) / 2 (maps [-1,1] to [0,1])
  ///
  /// Returns:
  /// - double: Confidence score [0.0, 1.0]
  static double getConfidenceScore(
    List<double> embedding1,
    List<double> embedding2, {
    bool useCosineSimilarity = false,
    double maxDistance = 2.0,
  }) {
    if (useCosineSimilarity) {
      final similarity = cosineSimilarity(embedding1, embedding2);
      // Map [-1, 1] to [0, 1]
      return (similarity + 1.0) / 2.0;
    } else {
      final distance = euclideanDistance(embedding1, embedding2);
      // Map [0, maxDistance] to [1, 0]
      final confidence = math.max(0.0, 1.0 - (distance / maxDistance));
      return confidence.clamp(0.0, 1.0);
    }
  }

  /// Find the best matching embedding from a list
  ///
  /// Useful when you have multiple stored embeddings per user
  /// (e.g., different angles or lighting conditions)
  ///
  /// Parameters:
  /// - targetEmbedding: The embedding to match against
  /// - storedEmbeddings: List of stored embeddings to compare
  /// - threshold: Distance/similarity threshold
  /// - useCosineSimilarity: Use cosine similarity instead of Euclidean
  ///
  /// Returns:
  /// - Map with 'isMatch', 'bestScore', and 'bestIndex'
  static Map<String, dynamic> findBestMatch(
    List<double> targetEmbedding,
    List<List<double>> storedEmbeddings, {
    double threshold = 0.8,
    bool useCosineSimilarity = false,
  }) {
    if (storedEmbeddings.isEmpty) {
      return {
        'isMatch': false,
        'bestScore': useCosineSimilarity ? -1.0 : double.infinity,
        'bestIndex': -1,
      };
    }

    double bestScore = useCosineSimilarity ? -1.0 : double.infinity;
    int bestIndex = -1;

    for (int i = 0; i < storedEmbeddings.length; i++) {
      final score = useCosineSimilarity
          ? cosineSimilarity(targetEmbedding, storedEmbeddings[i])
          : euclideanDistance(targetEmbedding, storedEmbeddings[i]);

      final isBetter =
          useCosineSimilarity ? score > bestScore : score < bestScore;

      if (isBetter) {
        bestScore = score;
        bestIndex = i;
      }
    }

    final isMatch =
        useCosineSimilarity ? bestScore >= threshold : bestScore <= threshold;

    return {
      'isMatch': isMatch,
      'bestScore': bestScore,
      'bestIndex': bestIndex,
    };
  }

  /// Calculate statistics for a set of embeddings
  ///
  /// Useful for analyzing the quality of stored embeddings
  ///
  /// Returns mean, std deviation, min, and max distances
  static Map<String, double> calculateEmbeddingStatistics(
    List<List<double>> embeddings,
  ) {
    if (embeddings.length < 2) {
      return {
        'mean': 0.0,
        'stdDev': 0.0,
        'min': 0.0,
        'max': 0.0,
      };
    }

    // Calculate all pairwise distances
    final distances = <double>[];
    for (int i = 0; i < embeddings.length; i++) {
      for (int j = i + 1; j < embeddings.length; j++) {
        distances.add(euclideanDistance(embeddings[i], embeddings[j]));
      }
    }

    // Calculate statistics
    final mean = distances.reduce((a, b) => a + b) / distances.length;
    final variance =
        distances.map((d) => math.pow(d - mean, 2)).reduce((a, b) => a + b) /
            distances.length;
    final stdDev = math.sqrt(variance);
    final min = distances.reduce(math.min);
    final max = distances.reduce(math.max);

    return {
      'mean': mean,
      'stdDev': stdDev,
      'min': min,
      'max': max,
    };
  }
}
