import 'dart:async';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

/// Enhanced FaceNet Service with Warm Isolate and Performance Optimizations
///
/// NEW FEATURES:
/// - Warm Isolate: Persistent isolate with pre-loaded interpreter
/// - Cached interpreter: No reload for each inference
/// - Throttling: Max one embedding per 300-500ms
/// - TransferableTypedData: Efficient memory transfer
/// - Batch processing support
class FaceNetService {
  Interpreter? _interpreter;
  bool _isInitialized = false;

  // Model configuration
  late int _inputSize;
  late int _outputSize;
  late List<int> _inputShape;
  late List<int> _outputShape;

  // Warm Isolate
  Isolate? _warmIsolate;
  SendPort? _isolateSendPort;
  final _isolateReady = Completer<void>();
  final _responseStreamController =
      StreamController<_IsolateResponse>.broadcast();

  // Throttling
  DateTime? _lastInferenceTime;
  static const Duration throttleDuration = Duration(milliseconds: 300);

  // Caching
  List<double>? _cachedEmbedding;
  DateTime? _cacheTimestamp;
  static const Duration cacheValidDuration = Duration(seconds: 2);

  /// Initialize the FaceNet model
  Future<void> initialize({
    String modelPath = 'assets/mobilefacenet.tflite',
    int inputSize = 112,
    int outputSize = 192,
    bool useGpu = false,
    bool useWarmIsolate =
        false, // Disabled by default due to asset loading in isolate
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
        options.addDelegate(GpuDelegateV2());
      }

      options.threads = 4;

      // Load the model
      _interpreter = await Interpreter.fromAsset(modelPath, options: options);

      // Get input/output shapes
      _inputShape = _interpreter!.getInputTensor(0).shape;
      _outputShape = _interpreter!.getOutputTensor(0).shape;

      print('FaceNet Model Loaded:');
      print('Input Shape: $_inputShape');
      print('Output Shape: $_outputShape');

      _isInitialized = true;

      // Start warm isolate if enabled
      if (useWarmIsolate) {
        await _startWarmIsolate(modelPath, options);
      }
    } catch (e) {
      throw Exception('Failed to load FaceNet model: $e');
    }
  }

  /// Start warm isolate with pre-loaded interpreter
  Future<void> _startWarmIsolate(
      String modelPath, InterpreterOptions options) async {
    final receivePort = ReceivePort();

    _warmIsolate = await Isolate.spawn(
      _isolateEntry,
      _IsolateInitData(
        sendPort: receivePort.sendPort,
        modelPath: modelPath,
        inputSize: _inputSize,
        outputSize: _outputSize,
      ),
    );

    // Listen for responses
    receivePort.listen((message) {
      if (message is SendPort) {
        _isolateSendPort = message;
        _isolateReady.complete();
      } else if (message is _IsolateResponse) {
        _responseStreamController.add(message);
      }
    });

    await _isolateReady.future;
    print('Warm Isolate ready');
  }

  /// Generate face embedding (with throttling and caching)
  Future<List<double>> generateEmbedding(img.Image faceImage) async {
    if (!_isInitialized || _interpreter == null) {
      throw Exception('FaceNetService not initialized');
    }

    // Check cache
    if (_cachedEmbedding != null && _cacheTimestamp != null) {
      final cacheAge = DateTime.now().difference(_cacheTimestamp!);
      if (cacheAge < cacheValidDuration) {
        return _cachedEmbedding!;
      }
    }

    // Apply throttling
    if (_lastInferenceTime != null) {
      final timeSinceLastInference =
          DateTime.now().difference(_lastInferenceTime!);
      if (timeSinceLastInference < throttleDuration) {
        final waitTime = throttleDuration - timeSinceLastInference;
        await Future.delayed(waitTime);
      }
    }

    // Use warm isolate if available
    if (_isolateSendPort != null) {
      final embedding = await _generateEmbeddingInIsolate(faceImage);
      _lastInferenceTime = DateTime.now();
      _cachedEmbedding = embedding;
      _cacheTimestamp = DateTime.now();
      return embedding;
    }

    // Fallback to main thread
    final embedding = await _generateEmbeddingSync(faceImage);
    _lastInferenceTime = DateTime.now();
    _cachedEmbedding = embedding;
    _cacheTimestamp = DateTime.now();
    return embedding;
  }

  /// Generate embedding in warm isolate
  Future<List<double>> _generateEmbeddingInIsolate(img.Image faceImage) async {
    if (_isolateSendPort == null) {
      throw Exception('Warm isolate not ready');
    }

    // Prepare image data for transfer
    final resizedImage = img.copyResize(
      faceImage,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.cubic,
    );

    // Convert to bytes for efficient transfer
    final imageBytes = _imageToBytes(resizedImage);
    final transferable = TransferableTypedData.fromList([imageBytes]);

    final requestId = DateTime.now().millisecondsSinceEpoch.toString();

    // Send request
    _isolateSendPort!.send(_IsolateRequest(
      requestId: requestId,
      imageData: transferable,
      width: _inputSize,
      height: _inputSize,
    ));

    // Wait for response
    final response = await _responseStreamController.stream
        .firstWhere((r) => r.requestId == requestId);

    if (response.error != null) {
      throw Exception('Isolate error: ${response.error}');
    }

    return response.embedding!;
  }

  /// Generate embedding synchronously (fallback)
  Future<List<double>> _generateEmbeddingSync(img.Image faceImage) async {
    try {
      // Resize image
      final resizedImage = img.copyResize(
        faceImage,
        width: _inputSize,
        height: _inputSize,
        interpolation: img.Interpolation.cubic,
      );

      // Prepare input tensor
      final input = _imageToByteListFloat32(resizedImage);

      // Prepare output tensor
      final output = [List.filled(_outputSize, 0.0)];

      // Run inference
      _interpreter!.run(input, output);

      // Extract and normalize embedding
      final embedding = List<double>.from(output[0]);
      return _normalizeEmbedding(embedding);
    } catch (e) {
      throw Exception('Failed to generate embedding: $e');
    }
  }

  /// Convert image to bytes for transfer
  Uint8List _imageToBytes(img.Image image) {
    final bytes = BytesBuilder();
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        bytes.addByte(pixel.r.toInt());
        bytes.addByte(pixel.g.toInt());
        bytes.addByte(pixel.b.toInt());
      }
    }
    return bytes.toBytes();
  }

  /// Convert image to Float32 tensor
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

  /// Normalize embedding using L2 normalization
  List<double> _normalizeEmbedding(List<double> embedding) {
    double sumSquares = 0.0;
    for (final value in embedding) {
      sumSquares += value * value;
    }
    final norm = math.sqrt(sumSquares);

    if (norm == 0.0) {
      return embedding;
    }

    return embedding.map((value) => value / norm).toList();
  }

  /// Clear cache
  void clearCache() {
    _cachedEmbedding = null;
    _cacheTimestamp = null;
  }

  /// Get model information
  Map<String, dynamic> getModelInfo() {
    return {
      'isInitialized': _isInitialized,
      'inputSize': _inputSize,
      'outputSize': _outputSize,
      'inputShape': _inputShape,
      'outputShape': _outputShape,
      'warmIsolateActive': _isolateSendPort != null,
    };
  }

  /// Clean up resources
  Future<void> dispose() async {
    if (_warmIsolate != null) {
      _warmIsolate!.kill(priority: Isolate.immediate);
      _warmIsolate = null;
    }

    if (_interpreter != null) {
      _interpreter!.close();
      _interpreter = null;
    }

    await _responseStreamController.close();
    _isInitialized = false;
  }

  bool get isInitialized => _isInitialized;
  int get inputSize => _inputSize;
  int get outputSize => _outputSize;

  // ======================== ISOLATE ENTRY POINT ========================

  static void _isolateEntry(_IsolateInitData initData) async {
    final receivePort = ReceivePort();
    Interpreter? interpreter;

    try {
      // Load model in isolate
      final options = InterpreterOptions()..threads = 4;
      interpreter =
          await Interpreter.fromAsset(initData.modelPath, options: options);

      // Send back the send port
      initData.sendPort.send(receivePort.sendPort);

      // Listen for requests
      await for (final message in receivePort) {
        if (message is _IsolateRequest) {
          try {
            // Extract image data
            final imageBytes = message.imageData.materialize().asUint8List();

            // Convert to image
            final image = _bytesToImage(
              imageBytes,
              message.width,
              message.height,
            );

            // Prepare input
            final input = _imageToFloat32Tensor(
              image,
              initData.inputSize,
            );

            // Run inference
            final output = [List.filled(initData.outputSize, 0.0)];
            interpreter.run(input, output);

            // Normalize
            final embedding = _normalizeList(List<double>.from(output[0]));

            // Send response
            initData.sendPort.send(_IsolateResponse(
              requestId: message.requestId,
              embedding: embedding,
            ));
          } catch (e) {
            initData.sendPort.send(_IsolateResponse(
              requestId: message.requestId,
              error: e.toString(),
            ));
          }
        }
      }
    } catch (e) {
      print('Isolate error: $e');
    } finally {
      interpreter?.close();
    }
  }

  static img.Image _bytesToImage(Uint8List bytes, int width, int height) {
    final image = img.Image(width: width, height: height);
    int index = 0;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final r = bytes[index++];
        final g = bytes[index++];
        final b = bytes[index++];
        image.setPixelRgb(x, y, r, g, b);
      }
    }
    return image;
  }

  static List<List<List<List<double>>>> _imageToFloat32Tensor(
    img.Image image,
    int size,
  ) {
    return List.generate(
      1,
      (_) => List.generate(
        size,
        (y) => List.generate(
          size,
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
  }

  static List<double> _normalizeList(List<double> embedding) {
    double sumSquares = 0.0;
    for (final value in embedding) {
      sumSquares += value * value;
    }
    final norm = math.sqrt(sumSquares);
    if (norm == 0.0) return embedding;
    return embedding.map((value) => value / norm).toList();
  }
}

// ======================== ISOLATE DATA CLASSES ========================

class _IsolateInitData {
  final SendPort sendPort;
  final String modelPath;
  final int inputSize;
  final int outputSize;

  _IsolateInitData({
    required this.sendPort,
    required this.modelPath,
    required this.inputSize,
    required this.outputSize,
  });
}

class _IsolateRequest {
  final String requestId;
  final TransferableTypedData imageData;
  final int width;
  final int height;

  _IsolateRequest({
    required this.requestId,
    required this.imageData,
    required this.width,
    required this.height,
  });
}

class _IsolateResponse {
  final String requestId;
  final List<double>? embedding;
  final String? error;

  _IsolateResponse({
    required this.requestId,
    this.embedding,
    this.error,
  });
}
