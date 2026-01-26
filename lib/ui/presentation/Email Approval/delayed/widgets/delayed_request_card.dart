import 'package:el_race/core/constants/app_images.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// A card widget for displaying a delayed request item
/// Matches the design from the screenshot with employee image, request info, and days delayed badge
class DelayedRequestCard extends StatelessWidget {
  final String reqNo;
  final String requestType;
  final String employeeName;
  final String empCode;
  final String employeeImageUrl;
  final int daysDelayed;
  final VoidCallback? onTap;

  const DelayedRequestCard({
    super.key,
    required this.reqNo,
    required this.requestType,
    required this.employeeName,
    required this.empCode,
    required this.employeeImageUrl,
    required this.daysDelayed,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Fixed width per spec (logical pixels).
    const double stripWidth = 30;

    return Container(
      height: 140.w,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.w),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Base card (gradient + border)
              Positioned.fill(
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFE1E4E8),
                        Color(0xFFB9C0CB),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF5F666F), width: 1),
                  ),
                ),
              ),

              // Main content (leave space for the red strip)
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 14.w,
                    right: (14.w + stripWidth),
                    top: 8.w,
                    bottom: 8.w,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SizedBox(width: 50.w + 12.w + 2.w + 14.w),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  reqNo.toUpperCase(),
                                  style: GoogleFonts.nunito(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0B2D5E),
                                    letterSpacing: 0.5,
                                    height: 1.0,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.start,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.w),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 50.w,
                              height: 50.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.9),
                                  width: 2,
                                ),
                              ),
                              child: ClipOval(
                                child: _buildEmployeeImage(50.w),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Container(
                              width: 2.w,
                              height: 54.w,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(2.r),
                              ),
                            ),
                            SizedBox(width: 14.w),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    requestType.toUpperCase(),
                                    style: GoogleFonts.nunito(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF0E0E10),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 1.5.w),
                                  Text(
                                    employeeName.toUpperCase(),
                                    style: GoogleFonts.nunito(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0B2D5E),
                                      letterSpacing: 0.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 1.5.w),
                                  Text(
                                    empCode,
                                    style: GoogleFonts.nunito(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF6B717B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Positioned(
                top: 0,
                right: 20,
                bottom: 0,
                child: SizedBox(
                  width: stripWidth,
                  height: double.infinity,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topRight:  Radius.zero,
                      bottomRight: Radius.zero,
                      topLeft: Radius.zero,
                      bottomLeft: Radius.zero,
                    ),
                    child: ColoredBox(
                      color: const Color(0xFFC62828),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$daysDelayed',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 25.sp,
                              height: 1.0,
                            ),
                          ),
                          SizedBox(height: 9.w),
                          RotatedBox(
                            quarterTurns: 3,
                            child: Text(
                              'Days Delayed',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.sp,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeImage(double size) {
    final url = employeeImageUrl.trim();
    if (url.isNotEmpty && (url.startsWith('http://') || url.startsWith('https://'))) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        height: size,
        width: size,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            AppImages.personImage,
            fit: BoxFit.cover,
            height: size,
            width: size,
          );
        },
      );
    }

    return Image.asset(
      AppImages.personImage,
      fit: BoxFit.cover,
      height: size,
      width: size,
    );
  }
}