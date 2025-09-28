import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/main.dart';
import 'package:el_race/providers/profile_box_provider.dart';
import 'package:el_race/ui/presentation/qr_code/data/repository.dart';
import 'package:el_race/ui/presentation/signin/sign_in_screen.dart';
import 'package:el_race/utils/Util.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ProfileBoxWithSlideAnimation extends StatefulWidget {
  const ProfileBoxWithSlideAnimation({super.key});

  @override
  State<ProfileBoxWithSlideAnimation> createState() =>
      _ProfileBoxWithSlideAnimationState();
}

class _ProfileBoxWithSlideAnimationState
    extends State<ProfileBoxWithSlideAnimation> with TickerProviderStateMixin {
  final QrCodeRepository _qrCodeRepository = QrCodeRepository();
  Uint8List? _qrCodeData;
  bool _isLoadingQr = true;

  // Animation controller for moving numbers
  late AnimationController _numbersAnimationController;
  late Animation<double> _numbersAnimation;

  @override
  void initState() {
    super.initState();
    _loadQrCode();

    // Initialize animation controller for moving numbers
    _numbersAnimationController = AnimationController(
      duration: const Duration(
          milliseconds: 1500), // Faster - 1.5 seconds instead of 3
      vsync: this,
    );

    _numbersAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _numbersAnimationController,
      curve: Curves.linear,
    ));

    // Start infinite continuous animation without looping back
    _numbersAnimationController.repeat();
  }

  @override
  void dispose() {
    _numbersAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadQrCode() async {
    try {
      final qrData = await _qrCodeRepository.getQrCodeImageDirect();
      if (mounted) {
        setState(() {
          _qrCodeData = qrData;
          _isLoadingQr = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingQr = false;
        });
      }
    }
  }

  // Custom painter for QR code background with animated numbers
  Widget _buildQRBackground() {
    return AnimatedBuilder(
      animation: _numbersAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(200, 200),
          painter: AnimatedQRBackgroundPainter(_numbersAnimation.value),
        );
      },
    );
  }

  void _showCertificateOverEverything() {
    final overlayState = appOverlayKey.currentState;
    if (overlayState == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) {
        final size =
            MediaQuery.of(ctx).size; // ناخد أبعاد الشاشة من نفس الـ Overlay
        return Material(
          type: MaterialType.transparency, // علشان Directionality/Theme
          child: Stack(
            children: [
              // خلفية (barrier) قابلة للإغلاق باللمس
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => entry.remove(),
                  child: Container(color: Colors.black54),
                ),
              ),

              // المحتوى في المنتصف
              Center(
                child: Dialog(
                  insetPadding: const EdgeInsets.all(15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: size.width * 0.85,
                      height: size.height * 0.30,
                      child: Image.asset(
                        'assets/png/certificate.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    overlayState.insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    return SharedPref.isUserAuthenticated() == false
        ? const SizedBox.shrink()
        : Consumer<ProfileBoxProvider>(
            builder: (context, profileBoxProvider, child) {
              final isAuthenticated = SharedPref.isUserAuthenticated();
              if (isAuthenticated == false) return const SizedBox.shrink();

              final screenWidth = MediaQuery.of(context).size.width;
              final drawerWidth = screenWidth * 0.75;

              final base64Image = SharedPref().getUserBase64Image();
              final hasValidImage =
                  base64Image.isNotEmpty && Util.isValidBase64(base64Image);

              final loginData = SharedPref.getLoginData();

              return Stack(
                children: [
                  // Black transparent overlay
                  if (profileBoxProvider.isProfileVisible)
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: () => profileBoxProvider.hideProfileBox(),
                        child: Container(
                          color: Colors.black.withOpacity(0.7),
                        ),
                      ),
                    ),
                  // Side menu
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    left: SharedPref().isArabic()
                        ? null
                        : (profileBoxProvider.isProfileVisible
                            ? 0
                            : -drawerWidth),
                    right: SharedPref().isArabic()
                        ? (profileBoxProvider.isProfileVisible
                            ? 0
                            : -drawerWidth)
                        : null,
                    top: 0,
                    child: Material(
                      color: Colors.grey[300],
                      child: SafeArea(
                        child: Container(
                          width: drawerWidth,
                          height: MediaQuery.of(context).size.height *
                              0.72, // Increased height to 65% to accommodate content
                          padding: const EdgeInsets.only(bottom: 15),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Column(
                                  children: [
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        const SizedBox(
                                          width: 120.0,
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: Colors.black, width: 2),
                                          ),
                                          child: CircleAvatar(
                                            radius: 28,
                                            backgroundImage: hasValidImage
                                                ? MemoryImage(
                                                    base64Decode(base64Image))
                                                : const AssetImage(
                                                        'assets/png/profile_1.png')
                                                    as ImageProvider,
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 12.4,
                                        ),
                                        // Container(
                                        //   width: 48,
                                        //   height: 48,
                                        //   decoration: BoxDecoration(
                                        //       color: Colors.white,
                                        //       borderRadius:
                                        //           BorderRadius.circular(24)),
                                        //   child: Image.asset(
                                        //       'assets/png/name_tag_icon.png'),
                                        // ),
                                      ],
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      loginData.result?.data?.name
                                              ?.split(' ')
                                              .take(2)
                                              .join(' ') ??
                                          translate(
                                              'profile.name_not_available'),
                                      style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11.26),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      loginData.result?.data?.job_id ??
                                          translate(
                                              'profile.job_id_not_available'),
                                      style: GoogleFonts.inter(
                                          fontSize: 11.26,
                                          fontWeight: FontWeight.w400),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      loginData.result?.data?.emp_id
                                              ?.toString() ??
                                          translate('profile.id_not_available'),
                                      style: GoogleFonts.inter(
                                          fontSize: 11.26,
                                          fontWeight: FontWeight.w400),
                                    ),
                                    const SizedBox(height: 1),
                                    GestureDetector(
                                      onTap: _showCertificateOverEverything,
                                      //   final ctx = navKey.currentContext!;
                                      //   showDialog(
                                      //     context: ctx,
                                      //     builder: (_) {
                                      //       return Dialog(
                                      //         insetPadding: const EdgeInsets.all(15),
                                      //         child: Container(
                                      //           width: double.infinity,
                                      //           height:
                                      //               MediaQuery.of(ctx).size.height *
                                      //                   0.3,
                                      //           decoration: BoxDecoration(
                                      //             color: Colors.black,
                                      //             borderRadius:
                                      //                 BorderRadius.circular(12),
                                      //           ),
                                      //           child: ClipRRect(
                                      //             borderRadius:
                                      //                 BorderRadius.circular(12),
                                      //             child: Image.asset(
                                      //                 'assets/png/certificate.png',
                                      //                 fit: BoxFit.cover),
                                      //           ),
                                      //         ),
                                      //       );
                                      //     },
                                      //   );

                                      child: Image.asset(
                                        'assets/png/cert_icon.png',
                                        height: 26.52,
                                        width: 26.52,
                                        //fit: BoxFit.cover,
                                      ),
                                    ),
                                    SizedBox(height: 1.h),
                                    Text(
                                      'Status : Not Active',
                                      style: GoogleFonts.inter(
                                          fontSize: 11.26,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xff6D6D6D)),
                                    ),
                                    SizedBox(height: 1.h),
                                    Container(
                                      // margin: const EdgeInsets.only(
                                      //   top: 20,
                                      //   bottom: 36,
                                      // ),
                                      width: 250.w,
                                      height: 250.h,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        clipBehavior: Clip.hardEdge,
                                        children: [
                                          // Background with repeated numbers
                                          Container(
                                            width: 200,
                                            height: 200,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  Colors.grey.shade100,
                                                  Colors.grey.shade200,
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(28),
                                              border: Border.all(
                                                color: Colors.grey.shade400,
                                                width: 1,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.1),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                                child: _buildQRBackground()),
                                          ),
                                          // QR Code (rotated 45 degrees)
                                          Transform.rotate(
                                            angle:
                                                0.785398, // 45 degrees in radians
                                            child: Container(
                                              width: 120,
                                              height: 120,
                                              decoration: BoxDecoration(
                                                color: Colors.black,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.grey.shade600,
                                                    blurRadius: 2,
                                                    offset: const Offset(0, 1),
                                                  ),
                                                ],
                                              ),
                                              child: _isLoadingQr
                                                  ? const CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2,
                                                    )
                                                  : _qrCodeData != null
                                                      ? Image.memory(
                                                          _qrCodeData!,
                                                          fit: BoxFit.cover,
                                                        )
                                                      : const Icon(
                                                          Icons.error_outline,
                                                          color: Colors.white,
                                                          size: 30,
                                                        ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Container(
                                          margin: const EdgeInsets.only(top: 0),
                                          padding: const EdgeInsets.only(
                                              top: 4, bottom: 4),
                                          color: Colors.grey.shade100,
                                          child: Column(
                                            children: [
                                              const SizedBox(height: 0),
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withAlpha(
                                                              (0.15 * 255)
                                                                  .toInt()),
                                                      offset:
                                                          const Offset(0, 1.68),
                                                      // blurRadius: 4,
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 8),
                                                      child: Container(
                                                        width: 94.13,
                                                        height: 30.03,
                                                        decoration:
                                                            BoxDecoration(
                                                          gradient:
                                                              LinearGradient(
                                                            colors: !SharedPref()
                                                                    .isArabic()
                                                                ? [
                                                                    const Color(
                                                                        0xFF151544),
                                                                    const Color(
                                                                        0xFF3535AA)
                                                                  ] // لو مش عربي
                                                                : [
                                                                    Colors
                                                                        .white,
                                                                    Colors.grey[
                                                                        300]!
                                                                  ], // لو عربي
                                                            begin: Alignment
                                                                .centerLeft,
                                                            end: Alignment
                                                                .centerRight,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      20.3),
                                                        ),
                                                        child: ElevatedButton(
                                                          onPressed: () async {
                                                            if (profileBoxProvider
                                                                .isProfileVisible) {
                                                              profileBoxProvider
                                                                  .hideProfileBox();
                                                            }
                                                            await Util
                                                                .saveAndChangeLocale(
                                                                    context,
                                                                    'en');
                                                          },
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                            backgroundColor:
                                                                Colors
                                                                    .transparent,
                                                            //  backgroundColor: !SharedPref().isArabic()
                                                            //       ? appFontColor
                                                            //       : Colors.white,
                                                            minimumSize:
                                                                const Size(
                                                                    100, 16),
                                                            shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            20.3)),
                                                          ),
                                                          child: Text(
                                                              translate(
                                                                  'profile.english'),
                                                              style: TextStyle(
                                                                  color: !SharedPref()
                                                                          .isArabic()
                                                                      ? Colors
                                                                          .white
                                                                      : Colors
                                                                          .black,
                                                                  fontSize:
                                                                      10)),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Container(
                                                      width: 94.13,
                                                      height: 30.03,
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20.3),
                                                      ),
                                                      child: ElevatedButton(
                                                        onPressed: () async {
                                                          if (profileBoxProvider
                                                              .isProfileVisible) {
                                                            profileBoxProvider
                                                                .hideProfileBox();
                                                          }
                                                          await Util
                                                              .saveAndChangeLocale(
                                                                  context,
                                                                  'ar');
                                                        },
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              SharedPref()
                                                                      .isArabic()
                                                                  ? appFontColor
                                                                  : Colors.grey
                                                                      .shade200,
                                                          minimumSize:
                                                              const Size(
                                                                  100, 16),
                                                          shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          20.3)),
                                                        ),
                                                        child: Text(
                                                            translate(
                                                                'profile.arabic'),
                                                            style: TextStyle(
                                                                color: SharedPref()
                                                                        .isArabic()
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .black,
                                                                fontSize: 12)),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              const SizedBox(height: 1),
                                              // Container(
                                              //   height: 2,
                                              //   width: double.infinity,
                                              //   decoration: BoxDecoration(
                                              //     color: Colors.grey.shade300,
                                              //     // boxShadow: [
                                              //     //   BoxShadow(
                                              //     //     color: Colors.black.withAlpha(
                                              //     //         (0.15 * 255).toInt()),
                                              //     //     offset: const Offset(0, 2),
                                              //     //     blurRadius: 4,
                                              //     //   ),
                                              //     // ],
                                              //   ),
                                              // ),

                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 12),
                                                decoration: BoxDecoration(
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withAlpha(
                                                              (0.15 * 255)
                                                                  .toInt()),
                                                      offset:
                                                          const Offset(0, 1.68),
                                                      //blurRadius: 4,
                                                    )
                                                  ],
                                                  color: Colors.white,
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: [
                                                    Image.asset(
                                                        'assets/png/notification_filled_icon.png'),
                                                    const SizedBox(width: 12),
                                                    Text(
                                                        translate(
                                                            'profile.mute_notifications'),
                                                        style:
                                                            GoogleFonts.inter(
                                                                fontSize: 11)),
                                                    const Spacer(),
                                                    SizedBox(
                                                      height: 10.57,
                                                      child: Transform.scale(
                                                        scale:
                                                            0.7, // تصغير الحجم
                                                        child: const Switch(
                                                          value: false,
                                                          onChanged: null,
                                                          activeColor:
                                                              appFontColor, // لون الزر لما يكون ON
                                                          activeTrackColor: Color(
                                                              0xffD9D9D9), // لون الخلفية لما يكون ON
                                                          inactiveThumbColor: Color(
                                                              0xff3E3C3C), // لون الزر لما يكون OFF
                                                          inactiveTrackColor: Color(
                                                              0xffD9D9D9), // لون الخلفية لما يكون OFF
                                                        ),
                                                      ),
                                                    )
                                                    // Switch.adaptive(
                                                    //   value: isMuted,
                                                    //   onChanged: (val) => _updateMuteStatus(val),
                                                    //   activeColor: const Color(0xFF1A1A53),
                                                    //   activeTrackColor: Colors.grey.shade400,
                                                    // ),
                                                  ],
                                                ),
                                              ),
                                              // 🔹 Divider with shadow
                                              // Container(
                                              //   height: 2,
                                              //   width: double.infinity,
                                              //   decoration: BoxDecoration(
                                              //     color: Colors.grey.shade300,
                                              // boxShadow: [
                                              //   BoxShadow(
                                              //     color: Colors.black.withAlpha(
                                              //         (0.15 * 255).toInt()),
                                              //     offset: const Offset(0, 2),
                                              //     blurRadius: 4,
                                              //   ),
                                              // ],
                                              //   ),
                                              // ),
                                              const SizedBox(
                                                height: 8,
                                              ),
                                              // Container(
                                              //   padding: const EdgeInsets.symmetric(
                                              //         horizontal: 20, vertical: 12),
                                              //   decoration: BoxDecoration(
                                              //       color: Colors.white,
                                              //       boxShadow: [
                                              //         BoxShadow(
                                              //           color: Colors.black.withAlpha(
                                              //               (0.15 * 255).toInt()),
                                              //           offset: const Offset(0, 1.68),
                                              //           // blurRadius: 4,
                                              //         )
                                              //       ]),
                                              //   child: Row(
                                              //     children: [
                                              //       SizedBox(
                                              //         child: Image.asset(
                                              //             'assets/png/dark_mode_icon.png'),
                                              //       ),
                                              //       const SizedBox(width: 22),
                                              //       Text(
                                              //           translate(
                                              //               'profile.dark_mode'),
                                              //           style: const TextStyle(
                                              //               fontSize: 12)),
                                              //     ],
                                              //   ),
                                              // ),
                                            ],
                                          ),
                                        ),
                                        // Positioned(
                                        //   top: -10,
                                        //   left: 0,
                                        //   right: 0,
                                        //   child: Center(
                                        //     child: // QR Code section
                                        //         Container(
                                        //       margin: const EdgeInsets.only(
                                        //           top: 20, bottom: 36),
                                        //       width: 200,
                                        //       height: 200,
                                        //       child: Stack(
                                        //         alignment: Alignment.center,
                                        //         clipBehavior: Clip.hardEdge,
                                        //         children: [
                                        //           // Background with repeated numbers
                                        //           Container(
                                        //             width: 200,
                                        //             height: 200,
                                        //             decoration: BoxDecoration(
                                        //               gradient: LinearGradient(
                                        //                 begin: Alignment.topLeft,
                                        //                 end: Alignment.bottomRight,
                                        //                 colors: [
                                        //                   Colors.grey.shade100,
                                        //                   Colors.grey.shade200,
                                        //                 ],
                                        //               ),
                                        //               borderRadius:
                                        //                   BorderRadius.circular(16),
                                        //               border: Border.all(
                                        //                 color: Colors.grey.shade400,
                                        //                 width: 1,
                                        //               ),
                                        //               boxShadow: [
                                        //                 BoxShadow(
                                        //                   color: Colors.black
                                        //                       .withOpacity(0.1),
                                        //                   blurRadius: 4,
                                        //                   offset: const Offset(0, 2),
                                        //                 ),
                                        //               ],
                                        //             ),
                                        //             child: _buildQRBackground(),
                                        //           ),
                                        //           // QR Code (rotated 45 degrees)
                                        //           Transform.rotate(
                                        //             angle:
                                        //                 0.785398, // 45 degrees in radians
                                        //             child: Container(
                                        //               width: 100,
                                        //               height: 100,
                                        //               decoration: BoxDecoration(
                                        //                 color: Colors.black,
                                        //                 borderRadius:
                                        //                     BorderRadius.circular(8),
                                        //                 boxShadow: [
                                        //                   BoxShadow(
                                        //                     color:
                                        //                         Colors.grey.shade600,
                                        //                     blurRadius: 2,
                                        //                     offset:
                                        //                         const Offset(0, 1),
                                        //                   ),
                                        //                 ],
                                        //               ),
                                        //               child: Image.asset(
                                        //                 'assets/png/qr_code.png',
                                        //                 fit: BoxFit.cover,
                                        //               ),
                                        //             ),
                                        //           ),
                                        //         ],
                                        //       ),
                                        //     ),
                                        //   ),
                                        // ),
                                      ],
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Container(
                                  margin:
                                      const EdgeInsets.only(top: 8, bottom: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: const BorderRadius.only(
                                      bottomRight: Radius.circular(20),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      const SizedBox(
                                        width: 20,
                                      ),
                                      Image.asset(
                                          'assets/png/log_out_icon.png'),
                                      const SizedBox(
                                        width: 26,
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          try {
                                            print('🚪 Logout button pressed');

                                            // Hide profile box first
                                            if (profileBoxProvider
                                                .isProfileVisible) {
                                              profileBoxProvider
                                                  .hideProfileBox();
                                            }

                                            // Clear user preferences
                                            print('🧹 Clearing preferences...');
                                            await SharedPref()
                                                .clearPreferences();
                                            print('✅ Preferences cleared');

                                            // Use global navigation key for navigation
                                            print(
                                                '🧭 Navigating to sign in...');
                                            if (navKey.currentContext != null) {
                                              Navigator.pushAndRemoveUntil(
                                                navKey.currentContext!,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        const SignInScreen()),
                                                (route) => false,
                                              );
                                            } else {
                                              // Fallback to local context
                                              Navigator.pushAndRemoveUntil(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        const SignInScreen()),
                                                (route) => false,
                                              );
                                            }
                                            print('✅ Navigation completed');
                                          } catch (e) {
                                            print('❌ Logout error: $e');
                                          }
                                        },
                                        child: Text(translate('profile.logout'),
                                            style: const TextStyle(
                                                color: Color(0xffBA1719))),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
  }
}

// Custom painter for QR background with animated moving numbers
class AnimatedQRBackgroundPainter extends CustomPainter {
  final double animationValue;

  static const textStyle = TextStyle(
    color: Colors.grey,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  static const spacing = 50.0;
  static const text = '920';

  // Pre-compute text painter once to avoid recreation
  static final _textPainter = TextPainter(
    text: const TextSpan(text: text, style: textStyle),
    textDirection: ui.TextDirection.ltr,
  );

  static bool _isInitialized = false;

  AnimatedQRBackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    // Initialize text painter only once
    if (!_isInitialized) {
      _textPainter.layout();
      _isInitialized = true;
    }

    // Clip to container bounds to keep numbers only inside the white square
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Calculate movement offset - numbers move from bottom-right to top-left
    final moveX = animationValue * spacing;
    final moveY = animationValue * spacing;

    // Create multiple layers for infinite continuous effect
    final gridWidth = (size.width / spacing).ceil() + 3;
    final gridHeight = (size.height / spacing).ceil() + 3;

    for (int i = -1; i < gridWidth; i++) {
      for (int j = -1; j < gridHeight; j++) {
        // Base position
        final baseX = i * spacing;
        final baseY = j * spacing;

        // Create multiple flowing layers for infinite effect
        for (int layer = 0; layer < 4; layer++) {
          final layerOffsetX = layer * (size.width + spacing);
          final layerOffsetY = layer * (size.height + spacing);

          final animatedX = baseX + layerOffsetX - moveX;
          final animatedY = baseY + layerOffsetY - moveY;

          // Paint numbers - clipping will automatically constrain to square bounds
          _textPainter.paint(canvas, Offset(animatedX, animatedY));
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is AnimatedQRBackgroundPainter &&
        oldDelegate.animationValue != animationValue;
  }
}

// Keep the original painter for reference (can be removed if not needed)
class QRBackgroundPainter extends CustomPainter {
  static const textStyle = TextStyle(
    color: Colors.grey,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  static const spacing = 50.0;
  static const text = '920';

  // Pre-compute text painter once to avoid recreation
  static final _textPainter = TextPainter(
    text: const TextSpan(text: text, style: textStyle),
    textDirection: ui.TextDirection.ltr,
  );

  static bool _isInitialized = false;

  @override
  void paint(Canvas canvas, Size size) {
    // Initialize text painter only once
    if (!_isInitialized) {
      _textPainter.layout();
      _isInitialized = true;
    }

    // Use cached text painter and reduce iterations
    final maxX = size.width;
    final maxY = size.height;

    for (double x = 0; x < maxX; x += spacing) {
      for (double y = 0; y < maxY; y += spacing) {
        _textPainter.paint(canvas, Offset(x, y));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for decorative strips
class DecorativeStripPainter extends CustomPainter {
  // Cache the shader to avoid recreation
  static Shader? _cachedShader;
  static Size? _cachedSize;

  @override
  void paint(Canvas canvas, Size size) {
    // Only recreate shader if size changed
    if (_cachedShader == null || _cachedSize != size) {
      _cachedShader = LinearGradient(
        begin: const Alignment(0.0, 1.0), // Bottom
        end: const Alignment(0.0, -1.0), // Top
        colors: [
          Colors.white.withOpacity(0.49),
          const Color(0xFF999999).withOpacity(0.49),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      _cachedSize = size;
    }

    final paint = Paint()..shader = _cachedShader;

    // Create the triangular strip path based on new SVG (36/233 ratio)
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width * 0.154, 0); // 36/233 ≈ 0.154 (15.4% of width)
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
