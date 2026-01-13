import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../utils/safe_insets.dart';

import '../document_scanner/data/services/document_export_service.dart';
import '../document_scanner/data/services/image_processing_service.dart';
import '../document_scanner/domain/entities/document_page.dart';
import '../document_scanner/domain/entities/scanned_document.dart';

/// Camera Selection Screen with built-in camera preview
/// Shows SCAN and PHOTO buttons at bottom
class CameraSelectionScreen extends StatefulWidget {
  const CameraSelectionScreen({super.key});

  @override
  State<CameraSelectionScreen> createState() => _CameraSelectionScreenState();
}

class _CameraSelectionScreenState extends State<CameraSelectionScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  late Future<void> _initializeControllerFuture;
  String _currentDate = '';
  String _currentTime = '';
  bool _isCapturing = false;
  Uint8List? _logoBytes;

  // Inline scan/filter state
  final ImageProcessingService _imageProcessingService =
      ImageProcessingService();
  final DocumentExportService _exportService = DocumentExportService();
  String? _scanOriginalPath;
  String? _scanFilteredPath;
  bool _showScanOverlay = false;
  bool _isProcessingFilter = false;
  bool _isExportingPdf = false;
  ImageFilterType _selectedFilter = ImageFilterType.magic;
  final Map<ImageFilterType, String> _filterCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _enableImmersiveMode();
    _initializeCamera();
    _updateTime();
    _loadLogo();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Re-enable immersive on resume (Samsung resets system bars)
    if (state == AppLifecycleState.resumed) {
      _enableImmersiveMode();
    }
  }

  void _enableImmersiveMode() {
    // Hide bottom navigation bar only, keep status bar for better UX
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top],
    );
  }

  void _restoreSystemUI() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  Future<void> _loadLogo() async {
    try {
      final data = await rootBundle.load('assets/logo/rcc2.png');
      if (mounted) {
        setState(() {
          _logoBytes = data.buffer.asUint8List();
        });
      }
      debugPrint('✓ Logo rcc2.png loaded: ${data.lengthInBytes} bytes');
    } catch (e) {
      debugPrint('✗ Error loading logo: $e');
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
        ResolutionPreset.medium,
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
    _restoreSystemUI();
    WidgetsBinding.instance.removeObserver(this);
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

      // Stop capturing immediately for instant response
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }

      // Process overlay in background (non-blocking)
      _composeWithOverlay(file.path).then((composedPath) async {
        await Gal.putImage(composedPath ?? file.path, album: 'RCC');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo saved ✓'),
              backgroundColor: Colors.green,
              duration: Duration(milliseconds: 600),
            ),
          );
        }
      }).catchError((e) {
        debugPrint("Error saving: $e");
      });

      // Don't go back - allow multiple photos
    } catch (e) {
      debugPrint("Camera error: $e");
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<String?> _composeWithOverlay(String imagePath) async {
    try {
      // Read base image
      final bytes = await File(imagePath).readAsBytes();
      img.Image? baseImage = img.decodeImage(bytes);
      if (baseImage == null) return imagePath;

      final int padding = (baseImage.width * 0.04).toInt();

      // Add logo if available
      if (_logoBytes != null) {
        img.Image? logo = img.decodeImage(_logoBytes!);
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

      // Draw date and time text with shadow (smaller readable size)
      final int fontSize = (baseImage.width * 0.045).toInt();
      final shadowOffset = 1;

      // Calculate proper date width
      final dateTextWidth = _currentDate.length * (fontSize * 0.6).toInt();

      // Draw shadow for time (left)
      img.drawString(
        baseImage,
        _currentTime,
        font: img.arial24,
        x: padding + shadowOffset,
        y: baseImage.height - padding - fontSize - 10 + shadowOffset,
        color: img.ColorRgb8(50, 50, 50),
      );

      // Draw time on the left
      img.drawString(
        baseImage,
        _currentTime,
        font: img.arial24,
        x: padding,
        y: baseImage.height - padding - fontSize - 10,
        color: img.ColorRgb8(255, 255, 255),
      );

      // Draw shadow for date (right)
      img.drawString(
        baseImage,
        _currentDate,
        font: img.arial24,
        x: baseImage.width - padding - dateTextWidth + shadowOffset,
        y: baseImage.height - padding - fontSize - 10 + shadowOffset,
        color: img.ColorRgb8(50, 50, 50),
      );

      // Draw date on the right
      img.drawString(
        baseImage,
        _currentDate,
        font: img.arial24,
        x: baseImage.width - padding - dateTextWidth,
        y: baseImage.height - padding - fontSize - 10,
        color: img.ColorRgb8(255, 255, 255),
      );

      // Save the result with optimized quality
      final outputBytes = img.encodeJpg(baseImage, quality: 95);
      await File(imagePath).writeAsBytes(outputBytes);
      return imagePath;
    } catch (e) {
      debugPrint('Error composing overlay: $e');
      return imagePath;
    }
  }

  Future<void> _captureForScan() async {
    if (_isCapturing || _controller == null) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      await _initializeControllerFuture;
      final file = await _controller!.takePicture();

      // Show overlay immediately
      setState(() {
        _scanOriginalPath = file.path;
        _scanFilteredPath = null;
        _filterCache.clear();
        _selectedFilter = ImageFilterType.magic;
        _showScanOverlay = true;
        _isCapturing = false;
      });

      // Process overlay and filter in background
      _composeWithOverlay(file.path).then((withOverlay) {
        if (mounted) {
          setState(() {
            _scanOriginalPath = withOverlay ?? file.path;
          });
        }
        return _applyScanFilter(ImageFilterType.magic);
      });
    } catch (e) {
      debugPrint('Scan capture error: $e');
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _applyScanFilter(ImageFilterType filter) async {
    if (_scanOriginalPath == null) return;

    if (_filterCache[filter] != null) {
      setState(() {
        _selectedFilter = filter;
        _scanFilteredPath = _filterCache[filter];
      });
      return;
    }

    setState(() {
      _selectedFilter = filter;
      _isProcessingFilter = true;
    });

    try {
      final tempDir = await getTemporaryDirectory();
      final outputPath =
          '${tempDir.path}/inline_scan_${DateTime.now().millisecondsSinceEpoch}_${filter.name}.jpg';

      final processedPath = await _imageProcessingService.applyFilter(
        _scanOriginalPath!,
        filter,
        outputPath,
      );

      _filterCache[filter] = processedPath;

      if (mounted) {
        setState(() {
          _scanFilteredPath = processedPath;
        });
      }
    } catch (e) {
      debugPrint('Filter error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Filter failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingFilter = false;
        });
      }
    }
  }

  Future<void> _saveScanResult() async {
    final targetPath = _scanFilteredPath ?? _scanOriginalPath;
    if (targetPath == null) return;

    try {
      await Gal.putImage(targetPath, album: 'RCC');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scan saved to gallery ✓'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('Save scan error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareScanAsPdf() async {
    final targetPath = _scanFilteredPath ?? _scanOriginalPath;
    if (targetPath == null) return;

    setState(() {
      _isExportingPdf = true;
    });

    try {
      final page = DocumentPage(
        id: 'inline-scan-${DateTime.now().millisecondsSinceEpoch}',
        originalImagePath: targetPath,
        processedImagePath: targetPath,
        filterType: _selectedFilter,
        pageNumber: 1,
        capturedAt: DateTime.now(),
        edgeDetectionSuccessful: false,
      );

      final exportDir = await _exportService.getExportDirectory();
      final pdfPath =
          '$exportDir/scan_${DateTime.now().millisecondsSinceEpoch}.pdf';

      await _exportService.exportToPdf([
        page,
      ], pdfPath, ExportQuality.high);

      await Share.shareXFiles([
        XFile(pdfPath),
      ]);
    } catch (e) {
      debugPrint('Export PDF error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF share failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExportingPdf = false;
        });
      }
    }
  }

  void _openScanner() async {
    await _captureForScan();
  }

  @override
  Widget build(BuildContext context) {
    final H = MediaQuery.of(context).size.height;

    if (_controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black12,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black12,
      body: FutureBuilder(
        future: _initializeControllerFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.white));
          }

          return Stack(children: [
            /// ================================
            /// TRANSPARENT/GRADIENT BACKGROUND
            /// ================================
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.8,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.85),
                  ],
                ),
              ),
            ),

            /// ================================
            /// CAMERA PREVIEW (4:3 ASPECT RATIO)
            /// ================================
            Center(
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: CameraPreview(_controller!),
                ),
              ),
            ),

            /// ================================
            /// TOP GLASS BAR (LOGO + BACK)
            /// ================================
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  height: 100.h,
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    child: Row(
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
                      ],
                    ),
                  ),
                ),
              ),
            ),

            /// ================================
            /// LOGO OVERLAY ON CAMERA (CENTERED TOP)
            /// ================================
            Center(
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: Padding(
                  padding: EdgeInsets.only(top: 30.h, left: 20.w),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Image.asset(
                      'assets/logo/rcc2.png',
                      height: 35.h,
                    ),
                  ),
                ),
              ),
            ),

            /// ================================
            /// DATE + TIME OVERLAY ON CAMERA (BOTTOM)
            /// ================================
            Positioned(
              bottom: H * 0.15 + 40.h,
              left: 20.w,
              right: 20.w,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _currentTime,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          offset: const Offset(-1, -1),
                          blurRadius: 2,
                        ),
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          offset: const Offset(1, -1),
                          blurRadius: 2,
                        ),
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          offset: const Offset(1, 1),
                          blurRadius: 2,
                        ),
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          offset: const Offset(-1, 1),
                          blurRadius: 2,
                        ),
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(0, 0),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _currentDate,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          offset: const Offset(-1, -1),
                          blurRadius: 2,
                        ),
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          offset: const Offset(1, -1),
                          blurRadius: 2,
                        ),
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          offset: const Offset(1, 1),
                          blurRadius: 2,
                        ),
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          offset: const Offset(-1, 1),
                          blurRadius: 2,
                        ),
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(0, 0),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            /// ================================
            /// BOTTOM CONTROLS CONTAINER
            /// ================================
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BottomDock(
                extra: 0,
                liftWithKeyboard:
                    false, // Camera doesn't need keyboard handling
                child: Container(
                  width: double.infinity,
                  height: H * 0.15,
                  padding:
                      EdgeInsets.symmetric(horizontal: 30.w, vertical: 4.h),
                  decoration: const BoxDecoration(
                    color: Colors.black12,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      /// ——— SHOOT BUTTON ———
                      GestureDetector(
                        onTap: _isCapturing ? null : _takePicture,
                        child: Container(
                          width: 50.w,
                          height: 50.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isCapturing
                                ? Colors.white.withOpacity(0.5)
                                : Colors.white,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 55.w,
                            ),
                          ),
                          child: _isCapturing
                              ? Padding(
                                  padding: EdgeInsets.all(10.w),
                                  child: const CircularProgressIndicator(
                                    color: Colors.black12,
                                    strokeWidth: 2,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      SizedBox(height: 6.h),

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

            if (_showScanOverlay) _buildScanOverlay(),
          ]);
        },
      ),
    );
  }

  Widget _buildScanOverlay() {
    final previewPath = _scanFilteredPath ?? _scanOriginalPath;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.82),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _showScanOverlay = false;
                        });
                      },
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Scan Preview',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: _isExportingPdf ? null : _shareScanAsPdf,
                          icon: _isExportingPdf
                              ? SizedBox(
                                  width: 16.w,
                                  height: 16.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.picture_as_pdf,
                                  color: Colors.white),
                          label: const Text(
                            'Share PDF',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _saveScanResult,
                          child: const Text(
                            'Save',
                            style: TextStyle(color: Colors.greenAccent),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: previewPath == null
                      ? const Text(
                          'No scan yet',
                          style: TextStyle(color: Colors.white70),
                        )
                      : Stack(
                          alignment: Alignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12.r),
                              child: Image.file(
                                File(previewPath),
                                fit: BoxFit.contain,
                              ),
                            ),
                            if (_isProcessingFilter)
                              Container(
                                color: Colors.black.withOpacity(0.4),
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                          ],
                        ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filters',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ImageFilterType.values
                            .map((f) => _filterCard(f))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterCard(ImageFilterType type) {
    final bool selected = _selectedFilter == type;
    final Map<ImageFilterType, (String, Color, IconData)> meta = {
      ImageFilterType.enhanced: (
        'Enhanced',
        Colors.blueAccent.withOpacity(0.18),
        Icons.tune
      ),
      ImageFilterType.blackAndWhite: (
        'B&W',
        Colors.deepPurple.withOpacity(0.18),
        Icons.filter_b_and_w
      ),
      ImageFilterType.grayscale: (
        'Gray',
        Colors.grey.withOpacity(0.18),
        Icons.tonality
      ),
      ImageFilterType.original: (
        'Original',
        Colors.orange.withOpacity(0.18),
        Icons.image
      ),
    };

    final (String label, Color tint, IconData icon) =
        meta[type] ?? ('Filter', Colors.white12, Icons.filter_alt);

    return GestureDetector(
      onTap: () => _applyScanFilter(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: EdgeInsets.only(right: 10.w),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withOpacity(0.14) : tint,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Colors.white : Colors.white24,
            width: selected ? 1.4 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            SizedBox(width: 8.w),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glassButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25.r),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.30),
              borderRadius: BorderRadius.circular(25.r),
              border: Border.all(
                color: Colors.white.withOpacity(0.20),
                width: 1.2,
              ),
            ),
            child: Text(
              text,
              style: GoogleFonts.koulen(
                fontSize: 15.sp,
                letterSpacing: 1.2,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// CustomPainter for shadow overlay showing safe zones
class CameraShadowOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Calculate exact overlay areas that match the photo composition
    final padding = size.width * 0.04;

    // Top overlay: Logo area (logo is 28% of width with proportional height)
    final logoWidth = size.width * 0.28;
    final logoHeight = logoWidth * 0.4; // Approximate logo aspect ratio
    final topOverlayHeight = padding * 2 + logoHeight + padding * 2;

    // Bottom overlay: Date/Time text area
    final fontSize = size.width * 0.045;
    final bottomTextHeight = fontSize + 10 + padding;
    final bottomOverlayHeight = bottomTextHeight + padding * 2;

    // Draw top gradient overlay (covers logo area)
    final topGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.black.withOpacity(0.75),
        Colors.black.withOpacity(0.55),
        Colors.black.withOpacity(0.25),
        Colors.transparent,
      ],
      stops: const [0.0, 0.5, 0.85, 1.0],
    );

    final topRect = Rect.fromLTWH(0, 0, size.width, topOverlayHeight);
    final topPaint = Paint()..shader = topGradient.createShader(topRect);
    canvas.drawRect(topRect, topPaint);

    // Draw bottom gradient overlay (covers date/time area)
    final bottomGradient = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        Colors.black.withOpacity(0.75),
        Colors.black.withOpacity(0.55),
        Colors.black.withOpacity(0.25),
        Colors.transparent,
      ],
      stops: const [0.0, 0.5, 0.85, 1.0],
    );

    final bottomRect = Rect.fromLTWH(
      0,
      size.height - bottomOverlayHeight,
      size.width,
      bottomOverlayHeight,
    );
    final bottomPaint = Paint()
      ..shader = bottomGradient.createShader(bottomRect);
    canvas.drawRect(bottomRect, bottomPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
