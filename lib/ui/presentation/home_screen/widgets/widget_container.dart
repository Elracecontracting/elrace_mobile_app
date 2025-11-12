import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/ui/presentation/home_screen/screens/custom_swipe_button.dart';
import 'package:el_race/ui/presentation/home_screen/screens/edit_widgets_screen.dart';
import 'package:el_race/ui/presentation/home_screen/widgets/list_view_widgets.dart';
import 'package:el_race/ui/presentation/home_screen/widgets/parayer_widgets/parayer_widget.dart';
import 'package:el_race/utils/Util.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:el_race/utils/dimens.dart';
import 'package:el_race/utils/orientation_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:google_fonts/google_fonts.dart';

class WidgetContainer extends StatelessWidget {
  const WidgetContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      //width: ScreenUtil().screenWidth,
      width: double.infinity,
      decoration: BoxDecoration(
        color: white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3), // shadow color
            spreadRadius: 6,                      // how wide the shadow is
            blurRadius: 6,                        // how soft the shadow looks
            offset: const Offset(0, -5),          // move shadow upward (-Y means top)
          ),
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
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF000F42),
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>  Util.pushPage(const EditWidgetsScreen(), context),
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

                Opacity(
                  opacity: !SharedPref.isUserAuthenticated() ? 0.5 : 1,
                  child: SizedBox(
                    width: double.infinity,
                    height: AppDimen.homeWidgetCardHeight.w,
                    child: Container(
                      width: double.infinity,
                      height: AppDimen.homeWidgetCardHeight.w,
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: const DecorationImage(
                          image: AssetImage(
                              'assets/png/gray_card.png'), // ✅ Update to your image path
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Swipe button
                          IgnorePointer(
                            ignoring: !SharedPref.isUserAuthenticated(),
                            child: const CustomSwipeButton(),
                          ),

                        // Timer
                        // Obx(() {
                        //   final timer = Get.find<TimerController>().timeLeft.value;
                        //   final formatted = timer.toString().split('.').first.padLeft(8, "0");

                        //   return Text(
                        //     formatted,
                        //     style: const TextStyle(
                        //       fontSize: 16,
                        //       fontWeight: FontWeight.bold,
                        //       color: appFontColor,
                        //     ),
                        //   );
                        // }),
                        // Check-in / Check-out bar
                        // FutureBuilder(
                        //   future: null,
                        //   builder: (ctx, state) {
                        //     var isCheckedIn = SharedPref().getPreferenceBoolean('isCheckedIn');
                        //     return Row(
                        //       mainAxisAlignment: MainAxisAlignment.center,
                        //       children: [
                        //         Text(
                        //           'CHECK IN',
                        //           style: GoogleFonts.koulen(
                        //             fontSize: 11,
                        //             fontWeight: FontWeight.bold,
                        //             color: const Color(0xFF1A1A53),
                        //           ),
                        //         ),
                        //         const SizedBox(width: 6),
                        //         Container(
                        //           width: 13,
                        //           height: 13,
                        //           decoration: BoxDecoration(
                        //             shape: BoxShape.circle,
                        //             color: isCheckedIn ? Colors.green : Colors.transparent,
                        //             border: Border.all(color: Colors.green, width: 1),
                        //           ),
                        //         ),
                        //         Container(
                        //           width: 130,
                        //           height: 5,
                        //           decoration: BoxDecoration(
                        //             color: Colors.white,
                        //             borderRadius: BorderRadius.circular(2),
                        //           ),
                        //         ),
                        //         Container(
                        //           width: 13,
                        //           height: 13,
                        //           decoration: BoxDecoration(
                        //             shape: BoxShape.circle,
                        //             color: !isCheckedIn ? Colors.red : Colors.transparent,
                        //             border: Border.all(color: Colors.red, width: 1),
                        //           ),
                        //         ),
                        //         const SizedBox(width: 6),
                        //         Text(
                        //           translate('home.check_out'),
                        //           style: GoogleFonts.koulen(
                        //             fontSize: 11,
                        //             fontWeight: FontWeight.bold,
                        //             color: const Color(0xFF1A1A53),
                        //           ),
                        //         ),
                        //       ],
                        //     );
                        //   },
                        // ),

                        // Time Status Widget
                        // const TimeStatusWidget(),
                      ],
                    ),
                    ),
                  ),
                ),

                SizedBox(height: 10.w),
                const ParayerWidget(),
                SizedBox(height: 10.w),
                const ListViewWidgets(),

                // prayer times card
              ],
            ),
          ),
        ],
      ),
    );
  }
}
