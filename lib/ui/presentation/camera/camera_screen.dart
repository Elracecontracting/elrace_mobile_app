import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;

  const CameraScreen({super.key, required this.camera});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  String _currentDate = '';
  String _currentTime = '';

  @override
  void initState() {
    super.initState();

    _controller = CameraController(
      widget.camera,
      ResolutionPreset.max,
      enableAudio: false,
    );

    _initializeControllerFuture = _controller.initialize();

    _updateTime();
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
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final file = await _controller.takePicture();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Saved: ${file.path}")),
      );
    } catch (e) {
      print("Camera error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final H = MediaQuery.of(context).size.height;

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
                  width: _controller.value.previewSize!.height,
                  height: _controller.value.previewSize!.width,
                  child: CameraPreview(_controller),
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
                      ///
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
                          crossAxisAlignment: CrossAxisAlignment.center,
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
                        onTap: _takePicture,
                        child: Container(
                          width: 55.w,
                          height: 55.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 60.w,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),

                      /// ——— SCAN / PHOTO BUTTONS ———
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _glassButton("SCAN"),
                          _glassButton("PHOTO"),
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

  Widget _glassButton(String text) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
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
    );
  }
}
