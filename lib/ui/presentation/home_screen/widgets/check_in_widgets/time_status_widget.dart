import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:el_race/ui/presentation/home_screen/widgets/timer_controller.dart';
import 'package:el_race/utils/color_utils.dart';

class TimeStatusWidget extends StatelessWidget {
  const TimeStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final timer = Get.find<TimerController>().timeLeft.value;
      final formatted = timer.toString().split('.').first.padLeft(8, "0");

      return Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: red, width: 0.5),
        ),
        child: Column(
          children: [
            // First Row - Check-in Time
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/png/icons/Ellipse_green.png',
                  width: 16.w,
                  height: 16.w,
                ),
                const SizedBox(width: 8),
                Text(
                  formatted,
                  style: GoogleFonts.koulen(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1A1A53),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Second Row - Check-out Time
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/png/icons/Ellipse_red.png',
                  width: 16.w,
                  height: 16.w,
                ),
                const SizedBox(width: 8),
                Text(
                  formatted,
                  style: GoogleFonts.koulen(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1A1A53),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}
