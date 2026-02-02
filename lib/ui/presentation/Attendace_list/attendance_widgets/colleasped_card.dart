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
  final String? employeeName;
  final String? employeeImageUrl;
  const ColleaspedCard(
      {super.key,
      required this.status,
      required this.textColor,
      required this.bgColorStart,
      required this.bgColorEnd,
      required this.isExpanded,
      required this.checkInTime,
      required this.checkOutTime,
      required this.backgroundImage,
      this.employeeName,
      this.employeeImageUrl});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        // if (backgroundImage != '' && !isExpanded)
        if (!isExpanded)
          Container(
            width: 50.w,
            height: 55.h,
            margin: EdgeInsets.only(top: 2.h, left: 3.w),
            decoration: BoxDecoration(
              color: textColor,
              borderRadius: BorderRadius.circular(23),
            ),
          ),
        Container(
          height: 54.h,
          key: const ValueKey("collapsed"),
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          margin: EdgeInsets.only(left: 7.w, top: 2.w),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFD6D6D6), Color(0xFFADB2BD)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(23),
          ),
          child: Row(
            children: [
              // Employee Avatar
              if (employeeImageUrl != null && employeeImageUrl!.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(right: 6.w),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundImage: NetworkImage(employeeImageUrl!),
                    backgroundColor: Colors.grey[300],
                  ),
                ),
              // Date
              SizedBox(
                width: 75,
                child: Text(
                  DateFormat('dd MMM yy').format(checkInTime).toUpperCase(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: appFontColor,
                  ),
                ),
              ),
              SizedBox(width: 6.w),
              SizedBox(
                height: 40.h,
                child: const VerticalDivider(color: Colors.grey, thickness: 1),
              ),

              // Check-in
              SizedBox(
                width: 75.w,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Check-in',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: appFontColor,
                      ),
                    ),
                    Text(
                      DateFormat('HH:mm:ss').format(checkInTime),
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
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
                        fontSize: 11.sp,
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
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
            ],
          ),
        ),
      ],
    );
  }
}
