import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ColleaspedCard extends StatelessWidget {
  final String status;
  final Color textColor;
  final Color bgColorStart;
  final Color bgColorEnd;
  final bool isExpanded;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String backgroundImage;
  const ColleaspedCard(
      {super.key,
      required this.status,
      required this.textColor,
      required this.bgColorStart,
      required this.bgColorEnd,
      required this.isExpanded,
      required this.checkInTime,
      required this.checkOutTime,
      required this.backgroundImage});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        // if (backgroundImage != '' && !isExpanded)
        if (!isExpanded)
          Container(
            width: 70.w,
            height: 71.w,
            margin: const EdgeInsets.only(
              top: 3,
            ),
            decoration: BoxDecoration(
              color: textColor,
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        Container(
          height: 70.w,
          key: const ValueKey("collapsed"),
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          margin: EdgeInsets.only(left: 7.w, top: 2.w),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFD6D6D6), Color.fromARGB(255, 200, 204, 213)],
              begin: Alignment.bottomRight,
              end: Alignment.topLeft,
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              // Date
              SizedBox(
                width: 80,
                child: Text(
                  DateFormat('dd MMM yy').format(checkInTime),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.bold,
                    color: appFontColor,
                  ),
                ),
              ),
              const SizedBox(
                height: 39.5,
                child: VerticalDivider(color: Colors.grey, thickness: 1),
              ),

              // Check-in
              SizedBox(
                width: 90.w,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Check-in',
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: appFontColor,
                      ),
                    ),
                    Text(
                      DateFormat('HH:mm:ss').format(checkInTime),
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),

              // Check-out
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Check-out',
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: appFontColor,
                      ),
                    ),
                    Text(
                      checkOutTime != null
                          ? DateFormat('HH:mm:ss').format(checkOutTime!)
                          : '00:00:00',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 50.w),
            ],
          ),
        ),
      ],
    );
  }
}
