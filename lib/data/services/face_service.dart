import 'dart:typed_data';
import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:math' as math;

class FaceService {
  late Interpreter _interpreter;
  bool _isModelLoaded = false;

  FaceService() {
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      print('🔄 Loading MobileFaceNet model in FaceService...');
      _interpreter = await Interpreter.fromAsset('assets/mobilefacenet.tflite');
      _isModelLoaded = true;
      print('✅ MobileFaceNet model loaded successfully in FaceService');
    } catch (e) {
      print('❌ Error loading MobileFaceNet model in FaceService: $e');
      _isModelLoaded = false;
    }
  }

  bool get isModelLoaded => _isModelLoaded;

  /// Extract face embedding from an image
  Future<List<double>> getEmbedding(Uint8List imageBytes) async {
    if (!_isModelLoaded) {
      print('⚠️ Model not loaded, returning empty embedding');
      return List.filled(192, 0.0);
    }

    try {
      var input = _preprocess(imageBytes);
      var output = List.filled(192, 0.0).reshape([1, 192]); // embedding size

      _interpreter.run(input, output);

      final embedding = List<double>.from(output[0]);
      print('✅ Face embedding extracted: ${embedding.length} dimensions');
      return embedding;
    } catch (e) {
      print('❌ Error extracting embedding: $e');
      return List.filled(192, 0.0);
    }
  }

  /// Extract face embedding from image file path
  Future<List<double>> getEmbeddingFromPath(String imagePath) async {
    try {
      final imageFile = await File(imagePath).readAsBytes();
      return await getEmbedding(imageFile);
    } catch (e) {
      print('❌ Error reading image from path: $e');
      return List.filled(192, 0.0);
    }
  }

  /// Cosine similarity
  double cosineSimilarity(List<double> e1, List<double> e2) {
    if (e1.length != e2.length) {
      print(
          '❌ Embedding dimensions do not match: ${e1.length} vs ${e2.length}');
      return 0.0;
    }

    try {
      // Calculate dot product
      double dotProduct = 0.0;
      for (int i = 0; i < e1.length; i++) {
        dotProduct += e1[i] * e2[i];
      }

      // Calculate magnitudes
      double mag1 = 0.0;
      double mag2 = 0.0;
      for (int i = 0; i < e1.length; i++) {
        mag1 += e1[i] * e1[i];
        mag2 += e2[i] * e2[i];
      }
      mag1 = math.sqrt(mag1);
      mag2 = math.sqrt(mag2);

      if (mag1 == 0 || mag2 == 0) {
        return 0.0;
      }

      final similarity = dotProduct / (mag1 * mag2);
      print('🔍 Cosine similarity: $similarity');
      return similarity;
    } catch (e) {
      print('❌ Error calculating cosine similarity: $e');
      return 0.0;
    }
  }

  /// Match two embeddings
  bool isMatch(List<double> e1, List<double> e2, {double threshold = 0.5}) {
    final similarity = cosineSimilarity(e1, e2);
    final isMatch = similarity > threshold;
    print(
        '🎯 Match result: $isMatch (similarity: $similarity, threshold: $threshold)');
    return isMatch;
  }

  /// Preprocess input (resize, normalize)
  List<List<List<List<double>>>> _preprocess(Uint8List imageBytes) {
    try {
      // Decode image
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        print('❌ Failed to decode image');
        return _createEmptyInput();
      }

      // Resize to 112x112 (MobileFaceNet input size)
      final resizedImage = img.copyResize(image, width: 112, height: 112);

      // Convert to normalized float values [0-1]
      final input = List.generate(
          1,
          (_) => List.generate(
              112,
              (y) => List.generate(112, (x) {
                    final pixel = resizedImage.getPixel(x, y);
                    return [
                      pixel.r / 255.0, // Red channel
                      pixel.g / 255.0, // Green channel
                      pixel.b / 255.0, // Blue channel
                    ];
                  })));

      print('✅ Image preprocessed: 112x112x3');
      return input;
    } catch (e) {
      print('❌ Error preprocessing image: $e');
      return _createEmptyInput();
    }
  }

  /// Create empty input tensor
  List<List<List<List<double>>>> _createEmptyInput() {
    return List.generate(
        1,
        (_) => List.generate(
            112, (_) => List.generate(112, (_) => [0.0, 0.0, 0.0])));
  }

  /// Dispose resources
  void dispose() {
    if (_isModelLoaded) {
      _interpreter.close();
      _isModelLoaded = false;
      print('🧹 FaceService disposed');
    }
  }
}
