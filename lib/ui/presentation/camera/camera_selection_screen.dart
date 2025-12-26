import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _updateTime();
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

      // Save to gallery using Gal
      await Gal.putImage(file.path, album: 'RCC');

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

  void _openScanner() async {
    // Dispose camera before opening scanner
    await _controller?.dispose();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SimpleDocumentScanner(
            maxPages: 10,
            allowGalleryImport: true,
            onScanComplete: (imagePaths) {
              debugPrint('Scanned ${imagePaths.length} pages');
            },
            onExportComplete: (path, format) {
              debugPrint('Exported to: $path');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Document saved to: $path'),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
          ),
        ),
      );
    }
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
