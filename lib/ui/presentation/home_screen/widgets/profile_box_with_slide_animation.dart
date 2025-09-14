import 'dart:convert';
import 'dart:ui';

import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/providers/profile_box_provider.dart';
import 'package:el_race/ui/presentation/signin/sign_in_screen.dart';
import 'package:el_race/utils/Util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;
import 'package:provider/provider.dart';

class ProfileBoxWithSlideAnimation extends StatelessWidget {
  const ProfileBoxWithSlideAnimation({super.key});

  // Custom painter for QR code background with repeated numbers
  Widget _buildQRBackground() {
    return CustomPaint(
      size: const Size(200, 200),
      painter: QRBackgroundPainter(),
    );
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

              return AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                left: SharedPref().isArabic()
                    ? null
                    : (profileBoxProvider.isProfileVisible ? 0 : -drawerWidth),
                right: SharedPref().isArabic()
                    ? (profileBoxProvider.isProfileVisible ? 0 : -drawerWidth)
                    : null,
                top: 0,
                child: Material(
                  color: Colors.white,
                  child: SafeArea(
                    child: Container(
                      width: drawerWidth,
                      height: MediaQuery.of(context).size.height,
                      child: Stack(
                        children: [
                          SingleChildScrollView(
                            child: Column(
                              children: [
                                // Top section
                                Container(
                                  height: 200,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        // Profile picture
                                        Container(
                                          width: 80,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.grey.shade300,
                                              width: 2,
                                            ),
                                          ),
                                          child: CircleAvatar(
                                            radius: 38,
                                            backgroundImage: hasValidImage
                                                ? MemoryImage(
                                                    base64Decode(base64Image))
                                                : const AssetImage(
                                                        'assets/png/profile_1.png')
                                                    as ImageProvider,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        // Full name
                                        Text(
                                          loginData.result?.data?.name ??
                                              'Marwan Ahmed Mohamed Abdelsattar',
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                            color: Colors.grey.shade800,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 4),
                                        // Profession
                                        Text(
                                          loginData.result?.data?.job_id ??
                                              'Graphic Designer',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        // ID number
                                        Text(
                                          loginData.result?.data?.emp_id
                                                  ?.toString() ??
                                              '5026',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        // Golden badge icon
                                        Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: Colors.amber.shade600,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Icon(
                                            Icons.star,
                                            color: Colors.white,
                                            size: 12,
                                          ),
                                        ),
                                        // Status
                                        Text(
                                          'Status : Active',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w400,
                                            height: 0,
                                            color: const Color(0xFF1D1A20),
                                            decoration: TextDecoration.none,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // QR Code section
                                Container(
                                  margin: const EdgeInsets.only(
                                      top: 20, bottom: 36),
                                  width: 200,
                                  height: 200,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    clipBehavior: Clip.hardEdge,
                                    children: [
                                      // Background with repeated numbers
                                      Container(
                                        width: 200,
                                        height: 200,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                            color: Colors.green,
                                            width: 3,
                                          ),
                                        ),
                                        child: _buildQRBackground(),
                                      ),
                                      // QR Code (rotated 45 degrees)
                                      Transform.rotate(
                                        angle:
                                            0.785398, // 45 degrees in radians
                                        child: Container(
                                          width: 100,
                                          height: 100,
                                          decoration: BoxDecoration(
                                            color: Colors.black,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Image.asset(
                                            'assets/png/qr_code.png',
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Language selection
                                Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      // English button
                                      Expanded(
                                        child: Container(
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: !SharedPref().isArabic()
                                                ? const Color(0xFF1A1A53)
                                                : Colors.grey.shade200,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: () async {
                                                if (profileBoxProvider
                                                    .isProfileVisible) {
                                                  profileBoxProvider
                                                      .hideProfileBox();
                                                }
                                                await Util.saveAndChangeLocale(
                                                    context, 'en');
                                              },
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              child: Container(
                                                height: 40,
                                                alignment: Alignment.center,
                                                child: Text(
                                                  'English',
                                                  style: TextStyle(
                                                    color:
                                                        !SharedPref().isArabic()
                                                            ? Colors.white
                                                            : Colors.black,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Arabic button
                                      Expanded(
                                        child: Container(
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: SharedPref().isArabic()
                                                ? const Color(0xFF1A1A53)
                                                : Colors.grey.shade200,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: () async {
                                                if (profileBoxProvider
                                                    .isProfileVisible) {
                                                  profileBoxProvider
                                                      .hideProfileBox();
                                                }
                                                await Util.saveAndChangeLocale(
                                                    context, 'ar');
                                              },
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              child: Container(
                                                height: 40,
                                                alignment: Alignment.center,
                                                child: Text(
                                                  'Arabic',
                                                  style: TextStyle(
                                                    color:
                                                        SharedPref().isArabic()
                                                            ? Colors.white
                                                            : Colors.black,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Mute notifications
                                Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.notifications,
                                        color: const Color(0xFF1A1A53),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        'Mute notifications',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                      const Spacer(),
                                      Switch(
                                        value: false,
                                        onChanged: (value) {
                                          // Handle mute toggle
                                        },
                                        activeColor: const Color(0xFF1A1A53),
                                        activeTrackColor: Colors.grey.shade300,
                                        inactiveThumbColor:
                                            Colors.grey.shade600,
                                        inactiveTrackColor:
                                            Colors.grey.shade300,
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Logout section
                                Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () async {
                                        SharedPref().clearPreferences();
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const SignInScreen()),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.logout,
                                              color: Colors.red.shade600,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 16),
                                            Text(
                                              'Logout',
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w400,
                                                color: Colors.red.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                          // Decorative strips behind profile image
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: IgnorePointer(
                              child: Stack(
                                children: [
                                  // First strip (left side)
                                  Positioned(
                                    top: 0,
                                    left: drawerWidth * 0.1,
                                    child: Transform.rotate(
                                      angle: 3.14159, // 180 degrees in radians
                                      child: CustomPaint(
                                        size: Size(
                                            drawerWidth * 0.1,
                                            MediaQuery.of(context).size.height *
                                                0.4),
                                        painter: DecorativeStripPainter(),
                                      ),
                                    ),
                                  ),
                                  // Second strip (right side, spread apart)
                                  Positioned(
                                    top: 0,
                                    right: drawerWidth * 0.1,
                                    child: Transform.rotate(
                                      angle: 3.14159, // 180 degrees in radians
                                      child: CustomPaint(
                                        size: Size(
                                            drawerWidth * 0.1,
                                            MediaQuery.of(context).size.height *
                                                0.4),
                                        painter: DecorativeStripPainter(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
  }
}

// Custom painter for QR background with repeated numbers
class QRBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const textStyle = TextStyle(
      color: Colors.green,
      fontSize: 12,
      fontWeight: FontWeight.w400,
    );

    const spacing = 50.0; // Increased spacing for more spread out numbers
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        final textPainter = TextPainter(
          text: const TextSpan(text: '5026', style: textStyle),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x, y));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for decorative strips
class DecorativeStripPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: const Alignment(0.0, 1.0), // Bottom
        end: const Alignment(0.0, -1.0), // Top
        colors: [
          Colors.white.withOpacity(0.49),
          const Color(0xFF999999).withOpacity(0.49),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

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
