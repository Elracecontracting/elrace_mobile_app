import 'dart:io';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CameraView extends StatefulWidget {
  const CameraView({
    super.key,
    required this.onImage,
    this.onCameraFeedReady,
    this.onDetectorViewModeChanged,
    this.onCameraLensDirectionChanged,
    this.initialCameraLensDirection = CameraLensDirection.back,
    this.onController,
    this.cameraSize = const Size(200, 200),
    this.externalController, // Add external controller parameter
  });
  final Size cameraSize;
  final Function(InputImage inputImage) onImage;
  final VoidCallback? onCameraFeedReady;
  final VoidCallback? onDetectorViewModeChanged;
  final Function(CameraLensDirection direction)? onCameraLensDirectionChanged;
  final CameraLensDirection initialCameraLensDirection;
  final void Function(CameraController controller)? onController;
  final CameraController? externalController; // External controller parameter

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> with WidgetsBindingObserver {
  static List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _cameraIndex = -1;
  bool _usingExternalController = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Check if we should use external controller
    if (widget.externalController != null) {
      _controller = widget.externalController;
      _usingExternalController = true;
      widget.onController?.call(_controller!);
      setState(() {});
    } else {
      _initialize();
    }
  }

  @override
  void didUpdateWidget(CameraView oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle external controller changes
    if (widget.externalController != oldWidget.externalController) {
      if (widget.externalController != null) {
        _controller = widget.externalController;
        _usingExternalController = true;
        widget.onController?.call(_controller!);
        setState(() {});
      } else {
        _usingExternalController = false;
        _controller = null;
        _initialize();
      }
    }
  }

  void _initialize() async {
    if (_cameras.isEmpty) {
      _cameras = await availableCameras();
    }
    for (var i = 0; i < _cameras.length; i++) {
      if (_cameras[i].lensDirection == widget.initialCameraLensDirection) {
        _cameraIndex = i;
        break;
      }
    }
    if (_cameraIndex != -1) {
      _startLiveFeed();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopLiveFeed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _liveFeedBody();
  }

  Widget _liveFeedBody() {
    if (_cameras.isEmpty && !_usingExternalController) return Container();
    if (_controller == null) return Container();
    
    // Add validation to prevent disposed controller exception
    if (!_controller!.value.isInitialized) {
      return Container(
        height: widget.cameraSize.height,
        width: widget.cameraSize.width,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(widget.cameraSize.width),
        ),
        child: const Center(
          child: Icon(
            Icons.camera_alt,
            color: Colors.grey,
            size: 40,
          ),
        ),
      );
    }
    
    // Safe call to onController
    if (widget.onController != null) {
      try {
        widget.onController!(_controller!);
      } catch (e) {
        debugPrint('Error calling onController: $e');
      }
    }

    // Safe access to preview size with null checks
    final previewSize = _controller!.value.previewSize;
    if (previewSize == null) {
      return Container(
        height: widget.cameraSize.height,
        width: widget.cameraSize.width,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(widget.cameraSize.width),
        ),
        child: const Center(
          child: Icon(
            Icons.camera_alt,
            color: Colors.grey,
            size: 40,
          ),
        ),
      );
    }

    return SizedBox(
      height: widget.cameraSize.height,
      width: widget.cameraSize.width,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.cameraSize.width),
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
              width: previewSize.height,
              height: previewSize.width,
              child: CameraPreview(_controller!)),
        ),
      ),
    );
  }

  Future _startLiveFeed() async {
    try {
      final camera = _cameras[_cameraIndex];
      _controller = CameraController(camera, ResolutionPreset.low,
          enableAudio: false,
          imageFormatGroup: Platform.isAndroid
              ? ImageFormatGroup.nv21
              : ImageFormatGroup.bgra8888);
      _controller?.initialize().then((_) {
        if (!mounted) {
          return;
        }
        _controller?.startImageStream(_processCameraImage).then((value) {
          if (widget.onCameraFeedReady != null) {
            widget.onCameraFeedReady!();
          }
          if (widget.onCameraLensDirectionChanged != null) {
            widget.onCameraLensDirectionChanged!(camera.lensDirection);
          }
        });
        setState(() {});
      });
    } catch (ex) {
      debugPrint('Camera error: $ex');
    }
  }

  Uint8List convertYUV420ToNV21(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];
    final yBuffer = yPlane.bytes;
    final uBuffer = uPlane.bytes;
    final vBuffer = vPlane.bytes;
    final numPixels = width * height + (width * height ~/ 2);
    final nv21 = Uint8List(numPixels);

    int idY = 0;
    int idUV = width * height;
    final uvWidth = width ~/ 2;
    final uvHeight = height ~/ 2;

    final yRowStride = yPlane.bytesPerRow;
    final yPixelStride = yPlane.bytesPerPixel ?? 1;
    final uvRowStride = uPlane.bytesPerRow;
    final uvPixelStride = uPlane.bytesPerPixel ?? 2;

    for (int y = 0; y < height; ++y) {
      final yOffset = y * yRowStride;
      for (int x = 0; x < width; ++x) {
        nv21[idY++] = yBuffer[yOffset + x * yPixelStride];
      }
    }

    for (int y = 0; y < uvHeight; ++y) {
      final uvOffset = y * uvRowStride;
      for (int x = 0; x < uvWidth; ++x) {
        final bufferIndex = uvOffset + (x * uvPixelStride);
        nv21[idUV++] = vBuffer[bufferIndex];
        nv21[idUV++] = uBuffer[bufferIndex];
      }
    }

    return nv21;
  }

  Future _stopLiveFeed() async {
    // Only dispose if we're not using an external controller
    if (!_usingExternalController && _controller != null) {
      await _controller?.stopImageStream();
      await _controller?.dispose();
    }
    _controller = null;
  }

  void _processCameraImage(CameraImage image) {
    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) return;
    widget.onImage(inputImage);
  }

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_controller == null) return null;

    final camera = _cameras[_cameraIndex];
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    // if (Platform.isIOS) {
    //   rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    // } else if (Platform.isAndroid) {
    var rotationCompensation =
    _orientations[_controller!.value.deviceOrientation];
    if (rotationCompensation == null) return null;
    if (camera.lensDirection == CameraLensDirection.front) {
      rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
    } else {
      rotationCompensation =
          (sensorOrientation - rotationCompensation + 360) % 360;
    }
    rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    // }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);

    bool shouldOverride =
        Platform.isAndroid && (format != InputImageFormat.nv21);
    if (image.planes.length != 1 && !shouldOverride) return null;
    final plane = image.planes.first;

    if (Platform.isIOS) {
      return InputImage.fromBytes(
        bytes: image.planes[0].bytes, // Only use first plane for BGRA
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.bgra8888,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
    }
    return InputImage.fromBytes(
      bytes: shouldOverride ? convertYUV420ToNV21(image) : plane.bytes,
      metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation, // used only in Android
          format: InputImageFormat.nv21, // used only in iOS
          bytesPerRow: image.width),
    );
  }
}