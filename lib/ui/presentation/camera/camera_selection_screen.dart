import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:gal/gal.dart';
import '../document_scanner/simple_document_scanner.dart';

/// Camera Selection Screen with built-in camera preview
/// Shows SCAN and PHOTO buttons at bottom
class CameraSelectionScreen extends StatefulWidget {
  const CameraSelectionScreen({super.key});

  @override
  State<CameraSelectionScreen> createState() => _CameraSelectionScreenState();
}

class _CameraSelectionScreenState extends State<CameraSelectionScreen> {
  CameraController? _controller;
  late Future<void> _initializeControllerFuture;
  String _currentDate = '';
  String _currentTime = '';
  bool _isCapturing = false;
  ui.Image? _logoImage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _updateTime();
    _loadLogo();
  }

  Future<void> _loadLogo() async {
    try {
      final data = await rootBundle.load('assets/png/main logo 1.png');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      _logoImage = frame.image;
    } catch (e) {
      debugPrint('Error loading logo: $e');
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        backCamera,
        ResolutionPreset.max,
        enableAudio: false,
      );

      _initializeControllerFuture = _controller!.initialize();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentDate = DateFormat('dd/MM/yyyy').format(now);
      _currentTime = DateFormat('hh:mm a').format(now);
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) _updateTime();
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_isCapturing || _controller == null) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      await _initializeControllerFuture;
      final file = await _controller!.takePicture();
      final composedPath = await _composeWithOverlay(file.path);

      // Save to gallery using Gal
      await Gal.putImage(composedPath ?? file.path, album: 'RCC');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo saved to gallery ✓'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );

      // Don't go back - allow multiple photos
    } catch (e) {
      debugPrint("Camera error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  Future<ui.Image> _decodeImage(Uint8List bytes) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, (img) => completer.complete(img));
    return completer.future;
  }

  Future<String?> _composeWithOverlay(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final baseImage = await _decodeImage(bytes);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint();

      // Draw captured photo
      canvas.drawImage(baseImage, Offset.zero, paint);

      final double padding = baseImage.width * 0.04;
      final double topBarHeight = baseImage.height * 0.20;
      final double bottomBarHeight = baseImage.height * 0.28;

      // Glass-like overlays to match live UI
      canvas.drawRect(
        Rect.fromLTWH(0, 0, baseImage.width.toDouble(), topBarHeight),
        Paint()..color = Colors.black.withOpacity(0.35),
      );

      canvas.drawRect(
        Rect.fromLTWH(
          0,
          baseImage.height - bottomBarHeight,
          baseImage.width.toDouble(),
          bottomBarHeight,
        ),
        Paint()..color = Colors.black.withOpacity(0.5),
      );

      // Draw logo top-left
      if (_logoImage != null) {
        final logo = _logoImage!;
        final double logoWidth = baseImage.width * 0.28;
        final double logoHeight = logoWidth * logo.height / logo.width;
        final Rect dst = Rect.fromLTWH(padding, padding, logoWidth, logoHeight);

        // Soft shadow behind logo
        final shadowPaint = Paint()
          ..color = Colors.black.withOpacity(0.25)
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 8);
        canvas.drawRRect(
          RRect.fromRectAndRadius(dst.inflate(6), const Radius.circular(8)),
          shadowPaint,
        );

        canvas.drawImageRect(
          logo,
          Rect.fromLTWH(0, 0, logo.width.toDouble(), logo.height.toDouble()),
          dst,
          paint,
        );
      }

      // Draw date + time bottom-right
      final textPainter = TextPainter(
        text: TextSpan(
          text: '$_currentDate\n$_currentTime',
          style: TextStyle(
            color: Colors.white,
            fontSize: baseImage.width * 0.04,
            fontWeight: FontWeight.w600,
            shadows: const [
              Shadow(
                  offset: Offset(0, 1.5), blurRadius: 2, color: Colors.black54),
            ],
          ),
        ),
        textDirection: ui.TextDirection.ltr,
        textAlign: TextAlign.right,
      )..layout(maxWidth: baseImage.width.toDouble());

      final Offset textOffset = Offset(
        baseImage.width - padding - textPainter.width,
        baseImage.height - bottomBarHeight + padding,
      );
      textPainter.paint(canvas, textOffset);

      final ui.Image composed = await recorder.endRecording().toImage(
            baseImage.width,
            baseImage.height,
          );

      final ByteData? pngBytes =
          await composed.toByteData(format: ui.ImageByteFormat.png);
      if (pngBytes == null) return imagePath;
      await File(imagePath).writeAsBytes(pngBytes.buffer.asUint8List());
      return imagePath;
    } catch (e) {
      debugPrint('Error composing overlay: $e');
      return imagePath;
    }
  }

  void _openScanner() async {
    // Pause camera before opening scanner
    await _controller?.dispose();

    if (!mounted) return;

    // Replace camera screen with scanner (so back button goes to main screen)
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SimpleDocumentScanner(
          maxPages: 10,
          allowGalleryImport: true,
          onScanComplete: (imagePaths) {
            debugPrint('Scanned ${imagePaths.length} pages');
          },
          onExportComplete: (path, format) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Document saved to: $path'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final H = MediaQuery.of(context).size.height;

    if (_controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder(
        future: _initializeControllerFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.white));
          }

          return Stack(children: [
            /// ================================
            /// REAL CAMERA PREVIEW (FULL FIT)
            /// ================================
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.previewSize!.height,
                  height: _controller!.value.previewSize!.width,
                  child: CameraPreview(_controller!),
                ),
              ),
            ),

            /// ================================
            /// TOP GLASS BAR (PERFECT MATCH)
            /// ================================
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 175.h,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35), // ← سواد نصف شفاف
                ),
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// BACK ARROW
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),

                      /// RCC LOGO
                      Image.asset(
                        'assets/png/main logo 1.png',
                        height: 42.h,
                      ),

                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),

            /// ================================
            /// BOTTOM GLASS CONTAINER (FULL FOOTER)
            /// ================================
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(0),
                child: Container(
                  width: double.infinity,
                  height: H * 0.28, // ربع الشاشة مثل الهيدر بالضبط
                  padding:
                      EdgeInsets.symmetric(horizontal: 30.w, vertical: 20.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5), // نفس الهيدر
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      /// ——— DATE + TIME ———
                      Align(
                        alignment: Alignment.centerRight,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _currentDate,
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _currentTime,
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      /// ——— SHOOT BUTTON ———
                      GestureDetector(
                        onTap: _isCapturing ? null : _takePicture,
                        child: Container(
                          width: 55.w,
                          height: 55.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isCapturing
                                ? Colors.white.withOpacity(0.5)
                                : Colors.white,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 60.w,
                            ),
                          ),
                          child: _isCapturing
                              ? Padding(
                                  padding: EdgeInsets.all(12.w),
                                  child: const CircularProgressIndicator(
                                    color: Colors.black,
                                    strokeWidth: 2,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      SizedBox(height: 20.h),

                      /// ——— SCAN / PHOTO BUTTONS ———
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _glassButton("SCAN", _openScanner),
                          _glassButton(
                              "PHOTO", _isCapturing ? () {} : _takePicture),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ]);
        },
      ),
    );
  }

  Widget _glassButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30.r),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 36.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.30), // ← سواد زجاجي
              borderRadius: BorderRadius.circular(30.r),
              border: Border.all(
                color: Colors.white.withOpacity(0.20), // ← حواف ناعمة
                width: 1.2,
              ),
            ),
            child: Text(
              text,
              style: GoogleFonts.koulen(
                fontSize: 17.sp,
                letterSpacing: 1.4,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
