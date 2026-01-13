import 'dart:math' as math;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

/// Service for generating face embeddings using FaceNet model
///
/// FaceNet generates a 128 or 512-dimensional embedding (feature vector)
/// that uniquely represents a face in a high-dimensional space.
///
/// Faces from the same person should have embeddings that are close together,
/// while faces from different people should be far apart.
class FaceNetService {
  Interpreter? _interpreter;
  bool _isInitialized = false;

  // Model configuration
  late int _inputSize; // e.g., 160 for FaceNet, 112 for MobileFaceNet
  late int _outputSize; // 128 or 512 dimensions
  late List<int> _inputShape;
  late List<int> _outputShape;

  /// Initialize the FaceNet model from assets
  ///
  /// Parameters:
  /// - modelPath: Path to the .tflite model file in assets
  /// - inputSize: Expected input size (e.g., 160x160 for FaceNet)
  /// - outputSize: Embedding dimension (128 or 512)
  /// - useGpu: Whether to use GPU acceleration (if available)
  Future<void> initialize({
    String modelPath = 'assets/mobilefacenet.tflite',
    int inputSize = 112,
    int outputSize = 192,
    bool useGpu = false,
  }) async {
    if (_isInitialized) {
      return;
    }

    _inputSize = inputSize;
    _outputSize = outputSize;

    try {
      // Configure interpreter options
      final options = InterpreterOptions();

      if (useGpu) {
        // Enable GPU delegate for faster inference (Android/iOS)
        // Note: GPU delegate may not be available on all devices
        options.addDelegate(GpuDelegateV2());
      }

      // Use multiple threads for CPU inference
      options.threads = 4;

      // Load the model from assets
      _interpreter = await Interpreter.fromAsset(
        modelPath,
        options: options,
      );

      // Get input/output shapes
      _inputShape = _interpreter!.getInputTensor(0).shape;
      _outputShape = _interpreter!.getOutputTensor(0).shape;

      print('FaceNet Model Loaded:');
      print('Input Shape: $_inputShape');
      print('Output Shape: $_outputShape');
      print('Expected: [$inputSize, $inputSize, 3] -> [$outputSize]');

      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to load FaceNet model: $e');
    }
  }

  /// Generate face embedding from a cropped face image
  ///
  /// Parameters:
  /// - faceImage: Pre-cropped and aligned face image
  ///
  /// Returns:
  /// - List<double>: The face embedding (feature vector)
  ///
  /// Algorithm:
  /// 1. Resize image to model input size (e.g., 160x160)
  /// 2. Normalize pixel values to [-1, 1] or [0, 1]
  /// 3. Run inference through the model
  /// 4. Return the output embedding vector
  Future<List<double>> generateEmbedding(img.Image faceImage) async {
    if (!_isInitialized || _interpreter == null) {
      throw Exception(
          'FaceNetService not initialized. Call initialize() first.');
    }

    try {
      // Step 1: Resize image to model input size
      final resizedImage = img.copyResize(
        faceImage,
        width: _inputSize,
        height: _inputSize,
        interpolation: img.Interpolation.cubic,
      );

      // Step 2: Prepare input tensor
      // Format: [1, height, width, 3] for batch_size=1, RGB image
      final input = _imageToByteListFloat32(resizedImage);

      // Step 3: Prepare output tensor
      final output = [List.filled(_outputSize, 0.0)];

      // Step 4: Run inference
      _interpreter!.run(input, output);

      // Step 5: Extract and normalize the embedding
      final embedding = List<double>.from(output[0]);

      // Normalize the embedding (L2 normalization)
      // This ensures that the distance calculation is more reliable
      return _normalizeEmbedding(embedding);
    } catch (e) {
      throw Exception('Failed to generate embedding: $e');
    }
  }

  /// Generate embedding using isolate for better performance
  ///
  /// This prevents UI blocking during inference
  /// Note: The actual isolate implementation is in the helper
  Future<List<double>> generateEmbeddingInIsolate(img.Image faceImage) async {
    // This will be implemented in the isolate helper
    // For now, call the regular method
    return generateEmbedding(faceImage);
  }

  /// Convert image to Float32 tensor with normalization
  ///
  /// Normalization strategies:
  /// - MobileFaceNet: (pixel - 127.5) / 128.0 -> range [-1, 1]
  /// - FaceNet: pixel / 255.0 -> range [0, 1]
  /// - Some models: (pixel - mean) / std
  ///
  /// Check your model's preprocessing requirements!
  List<List<List<List<double>>>> _imageToByteListFloat32(img.Image image) {
    final input = List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (y) => List.generate(
          _inputSize,
          (x) {
            final pixel = image.getPixel(x, y);
            return [
              (pixel.r.toInt() - 127.5) / 128.0,
              (pixel.g.toInt() - 127.5) / 128.0,
              (pixel.b.toInt() - 127.5) / 128.0,
            ];
          },
        ),
      ),
    );
    return input;
  }

  /// Normalize embedding vector using L2 normalization
  ///
  /// L2 normalization formula:
  /// normalized_vector = vector / ||vector||_2
  ///
  /// where ||vector||_2 = sqrt(sum(x_i^2))
  ///
  /// This is crucial for:
  /// 1. Making cosine similarity equivalent to dot product
  /// 2. Ensuring consistent distance scales
  /// 3. Improving recognition accuracy
  List<double> _normalizeEmbedding(List<double> embedding) {
    // Calculate L2 norm (Euclidean length)
    double sumSquares = 0.0;
    for (final value in embedding) {
      sumSquares += value * value;
    }
    final norm = math.sqrt(sumSquares);

    // Avoid division by zero
    if (norm == 0.0) {
      return embedding;
    }

    // Normalize each element
    return embedding.map((value) => value / norm).toList();
  }

  /// Get model information
  Map<String, dynamic> getModelInfo() {
    return {
      'isInitialized': _isInitialized,
      'inputSize': _inputSize,
      'outputSize': _outputSize,
      'inputShape': _inputShape,
      'outputShape': _outputShape,
    };
  }

  /// Clean up resources
  Future<void> dispose() async {
    if (_interpreter != null) {
      _interpreter!.close();
      _interpreter = null;
    }
    _isInitialized = false;
  }

  bool get isInitialized => _isInitialized;
  int get inputSize => _inputSize;
  int get outputSize => _outputSize;
}

/// Extension to help with tensor reshaping
extension ReshapeExtension on List {
  List reshape(List<int> shape) {
    if (shape.isEmpty) return this;

    // For simple 2D reshape [1, n]
    if (shape.length == 2 && shape[0] == 1) {
      return [this];
    }

    // For 4D reshape [1, h, w, c]
    if (shape.length == 4 && shape[0] == 1) {
      return [this];
    }

    return this;
  }
}
