import 'dart:isolate';
import 'dart:math' as math;
import 'package:image/image.dart' as img;
import '../services/facenet_service.dart';

/// Helper class for running face recognition tasks in isolates
///
/// Isolates are Dart's way of achieving true parallelism
/// This prevents UI freezing during heavy computations like TFLite inference
///
/// Performance benefits:
/// - Maintains 60 FPS during face recognition
/// - Non-blocking UI thread
/// - Better user experience
class FaceRecognitionIsolateHelper {
  /// Generate face embedding in a separate isolate
  ///
  /// This is the key to maintaining smooth UI performance
  ///
  /// Parameters:
  /// - faceImage: Cropped face image
  /// - modelPath: Path to TFLite model
  /// - inputSize: Model input size (e.g., 112 or 160)
  /// - outputSize: Embedding dimension (e.g., 192 or 512)
  ///
  /// Returns:
  /// - List<double>: The face embedding
  static Future<List<double>> generateEmbeddingInIsolate({
    required img.Image faceImage,
    required String modelPath,
    required int inputSize,
    required int outputSize,
  }) async {
    final receivePort = ReceivePort();

    // Prepare data to send to isolate
    final isolateData = IsolateData(
      sendPort: receivePort.sendPort,
      faceImage: faceImage,
      modelPath: modelPath,
      inputSize: inputSize,
      outputSize: outputSize,
    );

    // Spawn isolate
    await Isolate.spawn(_isolateEmbeddingWorker, isolateData);

    // Wait for result
    final result = await receivePort.first;

    if (result is List<double>) {
      return result;
    } else if (result is String) {
      throw Exception(result);
    } else {
      throw Exception('Unknown error in isolate');
    }
  }

  /// Isolate worker function for embedding generation
  ///
  /// This runs in a separate isolate (separate thread/memory space)
  static Future<void> _isolateEmbeddingWorker(IsolateData data) async {
    try {
      // Initialize FaceNet service in this isolate
      final faceNetService = FaceNetService();
      await faceNetService.initialize(
        modelPath: data.modelPath,
        inputSize: data.inputSize,
        outputSize: data.outputSize,
      );

      // Generate embedding
      final embedding = await faceNetService.generateEmbedding(data.faceImage);

      // Send result back to main isolate
      data.sendPort.send(embedding);

      // Clean up
      await faceNetService.dispose();
    } catch (e) {
      // Send error back
      data.sendPort.send('Error in isolate: $e');
    }
  }

  /// Compare embeddings in isolate (for large batch operations)
  ///
  /// Useful when comparing against many stored embeddings
  static Future<Map<String, dynamic>> compareEmbeddingsInIsolate({
    required List<double> targetEmbedding,
    required List<List<double>> storedEmbeddings,
    required double threshold,
    required bool useCosineSimilarity,
  }) async {
    final receivePort = ReceivePort();

    final comparisonData = ComparisonIsolateData(
      sendPort: receivePort.sendPort,
      targetEmbedding: targetEmbedding,
      storedEmbeddings: storedEmbeddings,
      threshold: threshold,
      useCosineSimilarity: useCosineSimilarity,
    );

    await Isolate.spawn(_isolateComparisonWorker, comparisonData);

    final result = await receivePort.first;

    if (result is Map<String, dynamic>) {
      return result;
    } else if (result is String) {
      throw Exception(result);
    } else {
      throw Exception('Unknown error in comparison isolate');
    }
  }

  /// Isolate worker for embedding comparison
  static void _isolateComparisonWorker(ComparisonIsolateData data) {
    try {
      // Import the comparison helper in this isolate
      // Note: We need to duplicate the comparison logic here
      // or make it a top-level function

      double bestScore = data.useCosineSimilarity ? -1.0 : double.infinity;
      int bestIndex = -1;

      for (int i = 0; i < data.storedEmbeddings.length; i++) {
        final score = data.useCosineSimilarity
            ? _cosineSimilarity(data.targetEmbedding, data.storedEmbeddings[i])
            : _euclideanDistance(
                data.targetEmbedding, data.storedEmbeddings[i]);

        final isBetter =
            data.useCosineSimilarity ? score > bestScore : score < bestScore;

        if (isBetter) {
          bestScore = score;
          bestIndex = i;
        }
      }

      final isMatch = data.useCosineSimilarity
          ? bestScore >= data.threshold
          : bestScore <= data.threshold;

      data.sendPort.send({
        'isMatch': isMatch,
        'bestScore': bestScore,
        'bestIndex': bestIndex,
      });
    } catch (e) {
      data.sendPort.send('Error in comparison isolate: $e');
    }
  }

  /// Euclidean distance calculation (duplicate for isolate)
  static double _euclideanDistance(List<double> a, List<double> b) {
    double sum = 0.0;
    for (int i = 0; i < a.length; i++) {
      final diff = a[i] - b[i];
      sum += diff * diff;
    }
    return math.sqrt(sum);
  }

  /// Cosine similarity calculation (duplicate for isolate)
  static double _cosineSimilarity(List<double> a, List<double> b) {
    double dotProduct = 0.0;
    double magnitudeA = 0.0;
    double magnitudeB = 0.0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      magnitudeA += a[i] * a[i];
      magnitudeB += b[i] * b[i];
    }

    magnitudeA = math.sqrt(magnitudeA);
    magnitudeB = math.sqrt(magnitudeB);

    if (magnitudeA == 0.0 || magnitudeB == 0.0) {
      return 0.0;
    }

    return dotProduct / (magnitudeA * magnitudeB);
  }
}

/// Data class for isolate communication
class IsolateData {
  final SendPort sendPort;
  final img.Image faceImage;
  final String modelPath;
  final int inputSize;
  final int outputSize;

  IsolateData({
    required this.sendPort,
    required this.faceImage,
    required this.modelPath,
    required this.inputSize,
    required this.outputSize,
  });
}

/// Data class for comparison isolate
class ComparisonIsolateData {
  final SendPort sendPort;
  final List<double> targetEmbedding;
  final List<List<double>> storedEmbeddings;
  final double threshold;
  final bool useCosineSimilarity;

  ComparisonIsolateData({
    required this.sendPort,
    required this.targetEmbedding,
    required this.storedEmbeddings,
    required this.threshold,
    required this.useCosineSimilarity,
  });
}
