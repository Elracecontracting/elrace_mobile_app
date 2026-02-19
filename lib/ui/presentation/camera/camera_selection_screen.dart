import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../../utils/safe_insets.dart';

import 'services/image_queue_service.dart';
import '../document_scanner/data/services/document_export_service.dart';
import '../document_scanner/data/services/image_processing_service.dart';
import '../document_scanner/domain/entities/document_page.dart';
import '../document_scanner/domain/entities/scanned_document.dart';
import '../qr_code/qr_scanner_screen.dart';

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
  String _currentLocation = '';
  bool _isCapturing = false;
  Uint8List? _logoBytes;
  Timer? _locationRefreshTimer;
  int _locationRetryCount = 0;

  // Image queue service for background processing
  final ImageQueueService _imageQueueService = ImageQueueService();
  StreamSubscription<int>? _queueCountSubscription;
  StreamSubscription<ProcessingStatus>? _processingStatusSubscription;
  int _pendingImagesCount = 0;
  int _totalCapturedCount = 0;
  String _processingStatusText = '';

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
    _fetchLocation();

    // Refresh location every 60 seconds to keep it up-to-date
    _locationRefreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _fetchLocation();
    });

    // Listen to queue updates
    _queueCountSubscription = _imageQueueService.queueCount.listen((count) {
      if (mounted) {
        setState(() {
          _pendingImagesCount = count;
        });
      }
    });

    _processingStatusSubscription =
        _imageQueueService.processingStatus.listen((status) {
      if (mounted) {
        setState(() {
          _processingStatusText = status.progressText;
        });
      }
    });
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
    // Show all system UI (status bar and navigation bar)
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
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

  Future<void> _fetchLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
        _scheduleLocationRetry();
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          _scheduleLocationRetry();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied');
        return;
      }

      // Get current position with timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception('GPS timeout');
      });

      // Try to get address from coordinates
      String locationText = '';
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(const Duration(seconds: 8));

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;

          // Show the specific area/neighborhood + emirate/city
          // Priority: subLocality > thoroughfare > locality
          if (place.subLocality != null && place.subLocality!.isNotEmpty) {
            locationText = place.subLocality!;
          } else if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
            locationText = place.thoroughfare!;
          } else if (place.locality != null && place.locality!.isNotEmpty) {
            locationText = place.locality!;
          }

          // Add emirate/city (locality or administrativeArea)
          String emirate = '';
          if (place.locality != null && place.locality!.isNotEmpty && place.locality != locationText) {
            emirate = place.locality!;
          } else if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
            emirate = place.administrativeArea!;
          }

          if (emirate.isNotEmpty && locationText.isNotEmpty) {
            locationText = '$locationText, $emirate';
          } else if (emirate.isNotEmpty) {
            locationText = emirate;
          }
        }
      } catch (geocodeError) {
        debugPrint('✗ Reverse geocoding failed: $geocodeError');
      }

      // Fallback to GPS coordinates if geocoding returned nothing
      if (locationText.isEmpty) {
        locationText = '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
        debugPrint('⚠ Using GPS coordinates as fallback: $locationText');
      }

      if (mounted) {
        setState(() {
          _currentLocation = locationText;
        });
        _locationRetryCount = 0; // Reset retry count on success
        debugPrint('✓ Location fetched: $_currentLocation');
      }
    } catch (e) {
      debugPrint('✗ Error fetching location: $e');
      _scheduleLocationRetry();
    }
  }

  /// Retry location fetch with increasing delay (max 3 retries)
  void _scheduleLocationRetry() {
    if (_locationRetryCount >= 3 || !mounted) return;
    _locationRetryCount++;
    final delay = Duration(seconds: 3 * _locationRetryCount);
    debugPrint('↻ Retrying location fetch in ${delay.inSeconds}s (attempt $_locationRetryCount/3)');
    Future.delayed(delay, () {
      if (mounted) _fetchLocation();
    });
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
    _locationRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _queueCountSubscription?.cancel();
    _processingStatusSubscription?.cancel();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_isCapturing || _controller == null) return;

    _isCapturing = true; // Direct assignment, no setState for speed

    try {
      // Capture photo immediately
      final file = await _controller!.takePicture();

      // Capture current date/time at moment of capture
      final captureDate = _currentDate;
      final captureTime = _currentTime;
      final captureLocation = _currentLocation;

      // Reset capturing flag immediately
      _isCapturing = false;

      // Increment total captured count
      if (mounted) {
        setState(() {
          _totalCapturedCount++;
        });
      }

      // Add to queue (non-blocking, no await for instant response)
      _imageQueueService.addImageToQueue(
        imagePath: file.path,
        currentDate: captureDate,
        currentTime: captureTime,
        currentLocation: captureLocation,
        logoBytes: _logoBytes,
      );

      // Don't go back - allow multiple photos
    } catch (e) {
      debugPrint("Camera error: $e");
      _isCapturing = false;
      if (mounted) {
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

      // Draw date, time, and location text with shadow (all same font, aligned)
      final font = img.arial24;
      final shadowOffset = 1;

      // Measure actual text widths using font metrics
      int measureWidth(img.BitmapFont f, String text) {
        int w = 0;
        for (var ch in text.codeUnits) {
          if (f.characters.containsKey(ch)) {
            w += f.characters[ch]!.xAdvance;
          }
        }
        return w;
      }

      final timeTextWidth = measureWidth(font, _currentTime);
      final dateTextWidth = measureWidth(font, _currentDate);
      final locationTextWidth = _currentLocation.isNotEmpty
          ? measureWidth(font, _currentLocation)
          : 0;

      // Find widest to align all from the same left edge
      int maxWidth = timeTextWidth;
      if (dateTextWidth > maxWidth) maxWidth = dateTextWidth;
      if (locationTextWidth > maxWidth) maxWidth = locationTextWidth;

      final int rightEdge = baseImage.width - padding;
      final int lineHeight = font.lineHeight + 6;
      final int totalLines = _currentLocation.isNotEmpty ? 3 : 2;
      int currentY = baseImage.height - padding - (lineHeight * totalLines);

      // Draw time (right-aligned)
      final int timeX = rightEdge - timeTextWidth;
      img.drawString(
        baseImage,
        _currentTime,
        font: font,
        x: timeX + shadowOffset,
        y: currentY + shadowOffset,
        color: img.ColorRgb8(50, 50, 50),
      );
      img.drawString(
        baseImage,
        _currentTime,
        font: font,
        x: timeX,
        y: currentY,
        color: img.ColorRgb8(255, 255, 255),
      );

      currentY += lineHeight;

      // Draw date (right-aligned)
      final int dateX = rightEdge - dateTextWidth;
      img.drawString(
        baseImage,
        _currentDate,
        font: font,
        x: dateX + shadowOffset,
        y: currentY + shadowOffset,
        color: img.ColorRgb8(50, 50, 50),
      );
      img.drawString(
        baseImage,
        _currentDate,
        font: font,
        x: dateX,
        y: currentY,
        color: img.ColorRgb8(255, 255, 255),
      );

      // Draw location (right-aligned)
      if (_currentLocation.isNotEmpty) {
        currentY += lineHeight;
        final int locationX = rightEdge - locationTextWidth;
        img.drawString(
          baseImage,
          _currentLocation,
          font: font,
          x: locationX + shadowOffset,
          y: currentY + shadowOffset,
          color: img.ColorRgb8(50, 50, 50),
        );
        img.drawString(
          baseImage,
          _currentLocation,
          font: font,
          x: locationX,
          y: currentY,
          color: img.ColorRgb8(255, 255, 255),
        );
      }

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
    try {
      final pictures = await CunningDocumentScanner.getPictures(
        noOfPages: 20,
        isGalleryImportAllowed: true,
      );

      if (!mounted) return;
      if (pictures == null || pictures.isEmpty) return;

      // Add logo, date, time, location overlay then save to gallery
      final List<String> processedPaths = [];
      for (final picturePath in pictures) {
        try {
          await _composeWithOverlay(picturePath);
          await Gal.putImage(picturePath, album: 'RCC');
          processedPaths.add(picturePath);
        } catch (e) {
          debugPrint('Error processing scanned page: $e');
        }
      }

      if (!mounted || processedPaths.isEmpty) return;

      // Show bottom sheet with Save ✓ and Share options
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 16.h),
              Icon(Icons.check_circle_rounded,
                  color: Colors.green, size: 48.sp),
              SizedBox(height: 12.h),
              Text(
                '${processedPaths.length} page(s) scanned & saved ✓',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  // Share as Images
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await Share.shareXFiles(
                          processedPaths.map((p) => XFile(p)).toList(),
                        );
                      },
                      icon: Icon(Icons.image_rounded, size: 20.sp),
                      label: Text('Share Images',
                          style: GoogleFonts.inter(fontSize: 13.sp)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.1),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          side: BorderSide(
                              color: Colors.white.withOpacity(0.15)),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  // Share as PDF
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        try {
                          final pages = processedPaths
                              .asMap()
                              .entries
                              .map((e) => DocumentPage(
                                    id: 'scan-${DateTime.now().millisecondsSinceEpoch}-${e.key}',
                                    originalImagePath: e.value,
                                    processedImagePath: e.value,
                                    filterType: ImageFilterType.original,
                                    pageNumber: e.key + 1,
                                    capturedAt: DateTime.now(),
                                    edgeDetectionSuccessful: false,
                                  ))
                              .toList();

                          final exportDir =
                              await _exportService.getExportDirectory();
                          final pdfPath =
                              '$exportDir/scan_${DateTime.now().millisecondsSinceEpoch}.pdf';

                          await _exportService.exportToPdf(
                              pages, pdfPath, ExportQuality.high);

                          await Share.shareXFiles([XFile(pdfPath)]);
                        } catch (e) {
                          debugPrint('PDF export error: $e');
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('PDF share failed: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon: Icon(Icons.picture_as_pdf_rounded, size: 20.sp),
                      label: Text('Share PDF',
                          style: GoogleFonts.inter(fontSize: 13.sp)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan.withOpacity(0.8),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              // Done button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Done',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('Document scanner error: $e');
    }
  }

  void _openQrScanner() async {
    try {
      // Navigate to QR scanner screen
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const QrScannerScreen(),
          fullscreenDialog: true,
        ),
      );
    } catch (e) {
      debugPrint('QR scanner error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QR scanner error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
            /// LOGO OVERLAY ON CAMERA (LEFT TOP)
            /// ================================
            Center(
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: Padding(
                  padding: EdgeInsets.only(top: 5.h, left: 10.w),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Image.asset(
                      'assets/logo/rcc2.png',
                      height: 35.h,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
              ),
            ),

            /// ================================
            /// PHOTO COUNTER (RIGHT TOP)
            /// ================================
            if (_totalCapturedCount > 0)
              Center(
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: Padding(
                    padding: EdgeInsets.only(top: 30.h, right: 20.w),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.photo_camera,
                              color: Colors.white,
                              size: 16.sp,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              '$_totalCapturedCount',
                              style: GoogleFonts.inter(
                                fontSize: 16.sp,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            /// ================================
            /// DATE + TIME + LOCATION OVERLAY ON CAMERA (BOTTOM)
            /// ================================
            Positioned(
              bottom: H * 0.15 + 40.h,
              right: 20.w,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _currentTime,
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
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
                  SizedBox(height: 2.h),
                  Text(
                    _currentDate,
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
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
                  if (_currentLocation.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Text(
                      _currentLocation,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
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
                      textAlign: TextAlign.right,
                    ),
                  ],
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
                      EdgeInsets.symmetric(horizontal: 30.w, vertical: 2.h),
                  decoration: const BoxDecoration(
                    color: Colors.black12,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      /// ——— PROCESSING STATUS INDICATOR ———
                      if (_processingStatusText.isNotEmpty ||
                          _pendingImagesCount > 0)
                        Container(
                          margin: EdgeInsets.only(bottom: 4.h),
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_imageQueueService.isProcessing)
                                Padding(
                                  padding: EdgeInsets.only(right: 6.w),
                                  child: SizedBox(
                                    width: 10.w,
                                    height: 10.w,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              Text(
                                _processingStatusText.isNotEmpty
                                    ? _processingStatusText
                                    : 'Saving $_pendingImagesCount photo${_pendingImagesCount > 1 ? 's' : ''}...',
                                style: GoogleFonts.inter(
                                  fontSize: 10.sp,
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
                      SizedBox(height: 15.h),

                      /// ——— SCAN / PHOTO / QR BUTTONS ———
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _glassButton("SCAN", _openScanner),
                          _glassButton(
                              "PHOTO", _isCapturing ? () {} : _takePicture),
                          _glassButton("QR", _openQrScanner),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0D0D0D),
              const Color(0xFF1A1A2E),
              const Color(0xFF0D0D0D),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Modern Top Bar
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                child: Row(
                  children: [
                    // Back button with ripple
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(50),
                        onTap: () {
                          setState(() {
                            _showScanOverlay = false;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.08),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 24.sp,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    // Title with gradient
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Document Scan',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                          if (_isProcessingFilter)
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 600),
                              builder: (context, value, child) {
                                return Row(
                                  children: [
                                    SizedBox(
                                      width: 10.w,
                                      height: 10.w,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                        color: Colors.cyan.withOpacity(value),
                                      ),
                                    ),
                                    SizedBox(width: 6.w),
                                    Text(
                                      'Enhancing...',
                                      style: GoogleFonts.inter(
                                        color: Colors.white54,
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                    // Action buttons
                    _actionButton(
                      icon: Icons.save_alt_rounded,
                      label: 'Save',
                      onTap: _saveScanResult,
                      isPrimary: false,
                    ),
                    SizedBox(width: 8.w),
                    _actionButton(
                      icon: Icons.share_rounded,
                      label: 'PDF',
                      onTap: _isExportingPdf ? null : _shareScanAsPdf,
                      isLoading: _isExportingPdf,
                      isPrimary: true,
                    ),
                  ],
                ),
              ),

              // Image Preview with elegant frame
              Expanded(
                child: Container(
                  margin:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  child: previewPath == null
                      ? _buildLoadingSkeleton()
                      : Hero(
                          tag: 'scan_preview',
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            child: Stack(
                              key: ValueKey(previewPath),
                              alignment: Alignment.center,
                              children: [
                                // Glow effect behind image
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20.r),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.cyan.withOpacity(0.15),
                                        blurRadius: 40,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                ),
                                // Image with frame
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16.r),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.1),
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(16.r),
                                    ),
                                    child: Image.file(
                                      File(previewPath),
                                      fit: BoxFit.contain,
                                      filterQuality: FilterQuality.high,
                                    ),
                                  ),
                                ),
                                // Processing overlay with blur
                                if (_isProcessingFilter)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16.r),
                                    child: BackdropFilter(
                                      filter: ui.ImageFilter.blur(
                                        sigmaX: 3,
                                        sigmaY: 3,
                                      ),
                                      child: Container(
                                        color: Colors.black.withOpacity(0.3),
                                        child: Center(
                                          child: _buildProcessingIndicator(),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),

              // Modern Filter Bar
              Container(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 20.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.5),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_fix_high_rounded,
                          color: Colors.cyan,
                          size: 16.sp,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'Enhancement',
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    SizedBox(
                      height: 80.h,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: ImageFilterType.values.length,
                        itemBuilder: (context, index) {
                          return _modernFilterCard(
                              ImageFilterType.values[index]);
                        },
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

  Widget _buildLoadingSkeleton() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 0.7),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(value * 0.1),
                Colors.white.withOpacity(0.05),
                Colors.white.withOpacity(value * 0.1),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 40.w,
                  height: 40.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.cyan.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Processing scan...',
                  style: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProcessingIndicator() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (value * 0.2),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: Colors.cyan.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 32.w,
                    height: 32.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.cyan,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Applying filter...',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    bool isLoading = false,
    bool isPrimary = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: BoxDecoration(
            gradient: isPrimary
                ? LinearGradient(
                    colors: [
                      Colors.cyan.withOpacity(0.8),
                      Colors.blue.withOpacity(0.6),
                    ],
                  )
                : null,
            color: isPrimary ? null : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isPrimary
                  ? Colors.cyan.withOpacity(0.5)
                  : Colors.white.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                SizedBox(
                  width: 16.w,
                  height: 16.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else
                Icon(icon, color: Colors.white, size: 18.sp),
              SizedBox(width: 6.w),
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
      ),
    );
  }

  Widget _modernFilterCard(ImageFilterType type) {
    final bool selected = _selectedFilter == type;
    final filterMeta = _getFilterMeta(type);

    return GestureDetector(
      onTap: () => _applyScanFilter(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        margin: EdgeInsets.only(right: 12.w),
        width: 72.w,
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    filterMeta.color.withOpacity(0.4),
                    filterMeta.color.withOpacity(0.2),
                  ],
                )
              : null,
          color: selected ? null : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: selected
                ? filterMeta.color.withOpacity(0.7)
                : Colors.white.withOpacity(0.1),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: filterMeta.color.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? filterMeta.color.withOpacity(0.25)
                    : Colors.white.withOpacity(0.08),
              ),
              child: Icon(
                filterMeta.icon,
                color: selected ? filterMeta.color : Colors.white60,
                size: 20.sp,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              filterMeta.label,
              style: GoogleFonts.inter(
                color: selected ? Colors.white : Colors.white60,
                fontSize: 11.sp,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  _FilterMeta _getFilterMeta(ImageFilterType type) {
    switch (type) {
      case ImageFilterType.magic:
        return _FilterMeta('Auto', Colors.cyan, Icons.auto_awesome_rounded);
      case ImageFilterType.enhanced:
        return _FilterMeta('Sharp', Colors.orange, Icons.tune_rounded);
      case ImageFilterType.blackAndWhite:
        return _FilterMeta('B&W', Colors.purple, Icons.filter_b_and_w_rounded);
      case ImageFilterType.grayscale:
        return _FilterMeta('Gray', Colors.blueGrey, Icons.tonality_rounded);
      case ImageFilterType.original:
        return _FilterMeta('Original', Colors.green, Icons.image_rounded);
    }
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

/// Helper class for filter metadata
class _FilterMeta {
  final String label;
  final Color color;
  final IconData icon;

  _FilterMeta(this.label, this.color, this.icon);
}
