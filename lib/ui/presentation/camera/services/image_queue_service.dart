import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';
import 'package:image/image.dart' as img;

/// Parameters for image processing in isolate
class ImageProcessingParams {
  final String imagePath;
  final String currentDate;
  final String currentTime;
  final Uint8List? logoBytes;

  ImageProcessingParams({
    required this.imagePath,
    required this.currentDate,
    required this.currentTime,
    this.logoBytes,
  });
}

/// Result from image processing
class ImageProcessingResult {
  final String originalPath;
  final String? composedPath;
  final bool success;
  final String? error;

  ImageProcessingResult({
    required this.originalPath,
    this.composedPath,
    required this.success,
    this.error,
  });
}

/// Service for managing background image processing queue
class ImageQueueService {
  static final ImageQueueService _instance = ImageQueueService._internal();
  factory ImageQueueService() => _instance;
  ImageQueueService._internal();

  // Queue to hold pending images
  final List<ImageTask> _queue = [];
  bool _isProcessing = false;

  // Callbacks for UI updates
  final _queueUpdateController = StreamController<int>.broadcast();
  final _processingStatusController =
      StreamController<ProcessingStatus>.broadcast();

  Stream<int> get queueCount => _queueUpdateController.stream;
  Stream<ProcessingStatus> get processingStatus =>
      _processingStatusController.stream;

  int get pendingCount => _queue.length;
  bool get isProcessing => _isProcessing;

  /// Add image to processing queue (optimized for speed)
  void addImageToQueue({
    required String imagePath,
    required String currentDate,
    required String currentTime,
    Uint8List? logoBytes,
  }) {
    final task = ImageTask(
      imagePath: imagePath,
      currentDate: currentDate,
      currentTime: currentTime,
      logoBytes: logoBytes,
    );

    _queue.add(task);
    _queueUpdateController.add(_queue.length);

    // Start processing if not already running (non-blocking)
    if (!_isProcessing) {
      // ignore: unawaited_futures
      _processQueue();
    }
  }

  /// Process all images in queue
  Future<void> _processQueue() async {
    if (_isProcessing || _queue.isEmpty) return;

    _isProcessing = true;
    _processingStatusController.add(ProcessingStatus(
      isProcessing: true,
      currentIndex: 0,
      totalCount: _queue.length,
    ));

    int processedCount = 0;
    while (_queue.isNotEmpty) {
      final task = _queue.removeAt(0);
      processedCount++;

      try {
        // Update status
        _processingStatusController.add(ProcessingStatus(
          isProcessing: true,
          currentIndex: processedCount,
          totalCount: processedCount + _queue.length,
          currentImagePath: task.imagePath,
        ));

        // Process the image in background isolate using compute()
        final params = ImageProcessingParams(
          imagePath: task.imagePath,
          currentDate: task.currentDate,
          currentTime: task.currentTime,
          logoBytes: task.logoBytes,
        );

        final result = await compute(_processImageInIsolate, params);

        if (result.success) {
          // Save to gallery
          await Gal.putImage(result.composedPath ?? task.imagePath,
              album: 'RCC');

          // Clean up temporary composed file if different from original
          if (result.composedPath != null &&
              result.composedPath != task.imagePath) {
            try {
              await File(result.composedPath!).delete();
            } catch (e) {
              debugPrint('Failed to delete temp file: $e');
            }
          }

          debugPrint(
              '✓ Saved image $processedCount/${processedCount + _queue.length}');
        } else {
          debugPrint('✗ Error processing image: ${result.error}');
        }
      } catch (e) {
        debugPrint('✗ Error processing image: $e');
        // Continue with next image even if one fails
      }

      _queueUpdateController.add(_queue.length);

      // No delay needed - isolate handles the heavy work
    }

    _isProcessing = false;
    _processingStatusController.add(ProcessingStatus(
      isProcessing: false,
      currentIndex: processedCount,
      totalCount: processedCount,
    ));

    debugPrint(
        '✓ Queue processing complete. Processed $processedCount images.');
  }

  /// Clear all pending tasks
  void clearQueue() {
    _queue.clear();
    _queueUpdateController.add(0);
  }

  /// Dispose resources
  void dispose() {
    _queueUpdateController.close();
    _processingStatusController.close();
  }
}

/// Static function to process image in isolate (must be top-level or static)
ImageProcessingResult _processImageInIsolate(ImageProcessingParams params) {
  try {
    // Read base image
    final bytes = File(params.imagePath).readAsBytesSync();
    img.Image? baseImage = img.decodeImage(bytes);
    if (baseImage == null) {
      return ImageProcessingResult(
        originalPath: params.imagePath,
        composedPath: params.imagePath,
        success: true,
      );
    }

    final int padding = (baseImage.width * 0.04).toInt();

    // Add logo if available
    if (params.logoBytes != null) {
      img.Image? logo = img.decodeImage(params.logoBytes!);
      if (logo != null) {
        // Resize logo with high quality interpolation
        final int logoWidth = (baseImage.width * 0.28).toInt();
        final int logoHeight = (logoWidth * logo.height / logo.width).toInt();
        logo = img.copyResize(
          logo,
          width: logoWidth,
          height: logoHeight,
          interpolation: img.Interpolation.cubic,
        );

        // Composite logo onto base image
        img.compositeImage(
          baseImage,
          logo,
          dstX: padding,
          dstY: padding,
        );
      }
    }

    // Draw date and time text with shadow
    final int fontSize = (baseImage.width * 0.045).toInt();
    const shadowOffset = 1;
    final dateTextWidth = params.currentDate.length * (fontSize * 0.6).toInt();

    // Draw shadow for time (left)
    img.drawString(
      baseImage,
      params.currentTime,
      font: img.arial24,
      x: padding + shadowOffset,
      y: baseImage.height - padding - fontSize - 10 + shadowOffset,
      color: img.ColorRgb8(50, 50, 50),
    );

    // Draw time on the left
    img.drawString(
      baseImage,
      params.currentTime,
      font: img.arial24,
      x: padding,
      y: baseImage.height - padding - fontSize - 10,
      color: img.ColorRgb8(255, 255, 255),
    );

    // Draw shadow for date (right)
    img.drawString(
      baseImage,
      params.currentDate,
      font: img.arial24,
      x: baseImage.width - padding - dateTextWidth + shadowOffset,
      y: baseImage.height - padding - fontSize - 10 + shadowOffset,
      color: img.ColorRgb8(50, 50, 50),
    );

    // Draw date on the right
    img.drawString(
      baseImage,
      params.currentDate,
      font: img.arial24,
      x: baseImage.width - padding - dateTextWidth,
      y: baseImage.height - padding - fontSize - 10,
      color: img.ColorRgb8(255, 255, 255),
    );

    // Save composed image
    final composedFile = File(
      '${params.imagePath.substring(0, params.imagePath.lastIndexOf('.'))}_composed.jpg',
    );
    composedFile.writeAsBytesSync(img.encodeJpg(baseImage, quality: 95));

    return ImageProcessingResult(
      originalPath: params.imagePath,
      composedPath: composedFile.path,
      success: true,
    );
  } catch (e) {
    return ImageProcessingResult(
      originalPath: params.imagePath,
      composedPath: params.imagePath,
      success: false,
      error: e.toString(),
    );
  }
}

/// Image processing task
class ImageTask {
  final String imagePath;
  final String currentDate;
  final String currentTime;
  final Uint8List? logoBytes;

  ImageTask({
    required this.imagePath,
    required this.currentDate,
    required this.currentTime,
    this.logoBytes,
  });
}

/// Processing status for UI updates
class ProcessingStatus {
  final bool isProcessing;
  final int currentIndex;
  final int totalCount;
  final String? currentImagePath;

  ProcessingStatus({
    required this.isProcessing,
    required this.currentIndex,
    required this.totalCount,
    this.currentImagePath,
  });

  String get progressText => isProcessing
      ? 'Processing $currentIndex/$totalCount...'
      : totalCount > 0
          ? 'Saved $totalCount photo${totalCount > 1 ? 's' : ''} ✓'
          : '';
}
