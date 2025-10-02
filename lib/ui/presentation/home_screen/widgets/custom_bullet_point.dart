import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomBulletPoint extends StatelessWidget {
  final Color bulletColor;
  final String text;
  final Color textColor;
  final String count;
  final Color countColor;
  final String? days;
  final bool isAttendance;

  const CustomBulletPoint({
    super.key,
    required this.bulletColor,
    required this.text,
    required this.textColor,
    required this.count,
    required this.countColor,
    this.days = 'Days',
    this.isAttendance = false,
  });

  @override
  Widget build(BuildContext context) {
    // Inherit the style from DefaultTextStyle
    final defaultTextStyle = DefaultTextStyle.of(context).style;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          // Custom bullet design
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: bulletColor, // Bullet color
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 4), // Spacing between bullet and text
          SizedBox(
            width: 83.w,
            child: Text(
              text,
              maxLines: 2,
              style: GoogleFonts.nunito(
                color: textColor,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold, // ✅ Bold applied
              ),
            ),
          ),
          CountWidget(count: count, countColor: countColor),
          
          const SizedBox(width: 8),
          isAttendance
              ? Text(days ?? '',
                  style: GoogleFonts.leagueSpartan(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ))
              : const Text(''),
        ],
      ),
    );
  }
}



class CountWidget extends StatelessWidget {
  final String count;
  final Color countColor;
  final double? width;
  const CountWidget({super.key, required this.count, required this.countColor, this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? 26.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          border: Border.all(width: 1, color: Colors.black)),
      child: Text(
        count.toUpperCase(),  
        style: GoogleFonts.koulen(
          color: countColor,
          fontSize: 16.sp,
          fontWeight: FontWeight.bold, // ✅ Bold applied
          letterSpacing: 1
        ),
      ),
    );
  }
}