import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/data/services/hive_service.dart';
import 'package:el_race/ui/presentation/signin/sign_in_screen.dart';
import 'package:el_race/utils/Util.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:el_race/providers/profile_box_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class AppSettingsWidget extends StatelessWidget {
  final navKey;
  const AppSettingsWidget({super.key, required this.navKey});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 0),
          padding: const EdgeInsets.only(top: 4, bottom: 4),
          color: Colors.grey.shade100,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.15 * 255).toInt()),
                      offset: const Offset(0, 1.68),
                      // blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Container(
                        width: 100.w,
                        height: 34.w,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: !SharedPref().isArabic()
                                ? [
                                    const Color(0xFF151544),
                                    const Color(0xFF3535AA)
                                  ] // لو مش عربي
                                : [Colors.white, Colors.grey[300]!], // لو عربي
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(20.3),
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            final provider = Provider.of<ProfileBoxProvider>(
                                context,
                                listen: false);
                            if (provider.isProfileVisible) {
                              provider.hideProfileBox();
                            }
                            await Util.saveAndChangeLocale(context, 'en');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            //  backgroundColor: !SharedPref().isArabic()
                            //       ? appFontColor
                            //       : Colors.white,
                            minimumSize: const Size(100, 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.3)),
                          ),
                          child: Text(translate('profile.english'),
                              style: TextStyle(
                                  color: !SharedPref().isArabic()
                                      ? Colors.white
                                      : Colors.black,
                                  fontSize: 10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 100.w,
                      height: 34.w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.3),
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          final provider = Provider.of<ProfileBoxProvider>(
                              context,
                              listen: false);
                          if (provider.isProfileVisible) {
                            provider.hideProfileBox();
                          }
                          await Util.saveAndChangeLocale(context, 'ar');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SharedPref().isArabic()
                              ? appFontColor
                              : Colors.grey.shade200,
                          minimumSize: const Size(100, 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.3)),
                        ),
                        child: Text(translate('profile.arabic'),
                            style: TextStyle(
                                color: SharedPref().isArabic()
                                    ? Colors.white
                                    : Colors.black,
                                fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 2.w),
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
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.w),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.15 * 255).toInt()),
                      offset: const Offset(0, 1.68),
                      //blurRadius: 4,
                    )
                  ],
                  color: Colors.white,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Image.asset('assets/png/notification_filled_icon.png'),
                    const SizedBox(width: 12),
                    Text(translate('profile.mute_notifications'),
                        style: GoogleFonts.inter(fontSize: 11)),
                    const Spacer(),
                    Consumer<ProfileBoxProvider>(
                      builder: (context, provider, child) {
                        return SizedBox(
                          height: 10.57,
                          child: Transform.scale(
                            scale: 0.7, // تصغير الحجم
                            child: Switch(
                              value: provider.muteNotifications,
                              onChanged: (v) {
                                provider.setMuteNotifications(v);
                              },
                              activeColor: appFontColor,
                              activeTrackColor: const Color(
                                  0xffD9D9D9), // لون الخلفية لما يكون ON
                              inactiveThumbColor: const Color(
                                  0xff3E3C3C), // لون الزر لما يكون OFF
                              inactiveTrackColor: const Color(
                                  0xffD9D9D9), // لون الخلفية لما يكون OFF
                            ),
                          ),
                        );
                      },
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
              //🔹 Divider with shadow
              SizedBox(height: 2.w),

              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.w),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.15 * 255).toInt()),
                      offset: const Offset(0, 1.68),
                      //blurRadius: 4,
                    )
                  ],
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      child: Image.asset('assets/png/dark_mode_icon.png'),
                    ),
                    const SizedBox(width: 22),
                    Text(translate('profile.dark_mode'),
                        style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10.h),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 12.w,
          ),
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.15 * 255).toInt()),
                offset: const Offset(0, 1.68),
                //blurRadius: 4,
              )
            ],
            borderRadius: const BorderRadius.only(
              bottomRight: Radius.circular(20),
            ),
            gradient: const LinearGradient(
              colors: [Color(0xFF999999), Color(0xFFFFFFFF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Image.asset('assets/png/log_out_icon.png'),
              SizedBox(
                width: 25.w,
              ),
              TextButton(
                onPressed: () async {
                  try {
                    print('🚪 Logout button pressed');

                    // Hide profile box first
                    final provider =
                        Provider.of<ProfileBoxProvider>(context, listen: false);
                    if (provider.isProfileVisible) {
                      provider.hideProfileBox();
                    }

                    // Clear user preferences
                    print('🧹 Clearing preferences...');
                    await SharedPref().clearPreferences();
                    // Update login state in Hive for background service
                    await HiveService.setUserLoggedIn(false);
                    print('✅ Preferences cleared');

                    // Use global navigation key for navigation
                    print('🧭 Navigating to sign in...');
                    if (navKey.currentContext != null) {
                      Navigator.pushAndRemoveUntil(
                        navKey.currentContext!,
                        MaterialPageRoute(
                            builder: (context) => const SignInScreen()),
                        (route) => false,
                      );
                    } else {
                      // Fallback to local context
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SignInScreen()),
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
                        color: Color(0xffBA1719), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
