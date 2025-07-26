import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomBulletPoint extends StatelessWidget {
  final Color bulletColor;
  final String text;
  final Color textColor;
  final String count;
  final Color countColor;

  const CustomBulletPoint({
    super.key,
    required this.bulletColor,
    required this.text,
    required this.textColor,
    required this.count,
    required this.countColor,
  });

  @override
  Widget build(BuildContext context) {
    // Inherit the style from DefaultTextStyle
    final defaultTextStyle = DefaultTextStyle.of(context).style;

    return Row(
      children: [
        // Custom bullet design
        Container(
          width: 10,
          height: 10,
          decoration: ShapeDecoration(
            color: bulletColor, // Bullet color
            shape: const OvalBorder(),
          ),
        ),
        const SizedBox(width: 8), // Spacing between bullet and text
        Expanded(
          child: Text(
            text.toUpperCase(),
            style: GoogleFonts.nunito(
              color: textColor,
              fontSize: 12.sp,
              fontWeight: FontWeight.bold, // ✅ Bold applied
            ),
          ),
        ),
        Text(
          count.toUpperCase(),
          style: GoogleFonts.nunito(
            color: countColor,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold, // ✅ Bold applied
          ),
        ),
      ],
    );
  }
}