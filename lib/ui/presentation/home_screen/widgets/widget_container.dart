import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/home_screen/screens/custom_swipe_button.dart';
import 'package:el_race/ui/presentation/home_screen/widgets/list_view_widgets.dart';
import 'package:el_race/ui/presentation/home_screen/widgets/timer_controller.dart';
import 'package:el_race/ui/presentation/signin/bloc/sign_in_bloc.dart' as widget;
import 'package:el_race/utils/color_utils.dart';
import 'package:el_race/utils/orientation_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_translate/flutter_translate.dart';

class WidgetContainer extends StatelessWidget {
  const WidgetContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ScreenUtil().screenWidth,
      decoration: BoxDecoration(
        color: white,
        boxShadow: [
          BoxShadow(color: black.withAlpha((0.3 * 255).toInt()), spreadRadius: 10, blurRadius: 9)
        ],
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(20),
          topLeft: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig().getWidth(20)),
            child: Column(
              children: [
                const SizedBox(height: 15),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: SizeConfig().getWidth(20)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        translate('home.my_widgets'),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF000F42),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // 🔁 Add your edit tap logic here
                        },
                        child: Text(
                          translate('home.edit'),
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF858585),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: const DecorationImage(
                      image: AssetImage('assets/png/gray_card.png'), // ✅ Update to your image path
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Swipe button
                      CustomSwipeButton(loginResponseModel: widget.loginResponseModel),

                      const SizedBox(height: 10),

                      // Timer
                      Obx(() {
                        final timer = Get.find<TimerController>().timeLeft.value;
                        final formatted = timer.toString().split('.').first.padLeft(8, "0");

                        return Text(
                          formatted,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: appFontColor,
                          ),
                        );
                      }),

                      const SizedBox(height: 16),

                      // Check-in / Check-out bar
                      if(SharedPref().getPreferenceBoolean('isCheckedIn'))
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'CHECK IN',
                            style: GoogleFonts.koulen(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A1A53),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 13,
                            height: 13,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: SharedPref().getPreferenceBoolean('isCheckedIn') ? Colors.green : Colors.transparent,
                              border: Border.all(color: Colors.green, width: 2),
                            ),
                          ),
                          Container(
                            width: 130, // ⬅️ fixed width here
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Container(
                            width: 13,
                            height: 13,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: !SharedPref().getPreferenceBoolean('isCheckedIn') ? Colors.red : Colors.transparent,
                              border: Border.all(color: Colors.red, width: 2),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            translate('home.check_out'),
                            style: GoogleFonts.koulen(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A1A53),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                ),


                const ListViewWidgets(),


              ],
            ),
          ),
        ],
      ),
    );
  }
}